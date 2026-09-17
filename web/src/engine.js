export function parseInfo(line) {
  if (!line.startsWith('info ') || !line.includes(' pv ')) return null;
  const depth = /\bdepth\s+(\d+)/.exec(line);
  const score = /\bscore\s+(cp|mate)\s+(-?\d+)/.exec(line);
  const pv = /\bpv\s+(.+)$/.exec(line);
  if (!depth || !score || !pv) return null;
  const moves = pv[1].trim().split(/\s+/).filter(m => /^[a-i][0-9][a-i][0-9]$/.test(m));
  if (!moves.length) return null;
  return {
    depth: Number(depth[1]),
    multiPv: Number(/\bmultipv\s+(\d+)/.exec(line)?.[1] ?? 1),
    score: { type: score[1], value: Number(score[2]) },
    moves,
  };
}

export function scoreText(score) {
  if (!score) return '—';
  if (score.type === 'mate') {
    return score.value > 0 ? `Chiếu hết sau ${score.value}` : `Bị chiếu hết sau ${Math.abs(score.value)}`;
  }
  const value = score.value / 100;
  return `${value >= 0 ? '+' : ''}${value.toFixed(2)}`;
}

export class WebPikafish {
  constructor(workerUrl = './src/engine-worker.js') {
    this.workerUrl = workerUrl;
    this.worker = null;
    this.pending = null;
    this.lines = new Map();
    this.onProgress = () => {};
  }

  async init() {
    if (this.worker) return;
    const worker = new Worker(this.workerUrl);
    this.worker = worker;
    let initTimer;
    try {
      await new Promise((resolve, reject) => {
        initTimer = setTimeout(() => reject(Error('Pikafish tải quá lâu. Hãy kiểm tra kết nối.')), 60000);
        worker.onerror = event => reject(Error(event.message || 'Không tải được engine WebAssembly.'));
        worker.onmessage = ({ data }) => {
          if (data.type === 'error') { reject(Error(data.message)); return; }
          if (data.type === 'ready') {
            worker.onmessage = ({ data: next }) => this._handle(next);
            resolve();
          }
        };
      });
      this._command('uci');
      await this._expect('uciok');
      this._command('setoption name Threads value 1');
      this._command('setoption name Hash value 32');
      this._command('isready');
      await this._expect('readyok');
    } catch (error) {
      worker.terminate();
      this.worker = null;
      throw error;
    } finally {
      clearTimeout(initTimer);
    }
  }

  _command(value) { this.worker.postMessage({ type: 'command', value }); }

  _expect(expected) {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => { this.handshake = null; reject(Error(`Pikafish không trả lời ${expected}.`)); }, 15000);
      this.handshake = { expected, resolve: () => { clearTimeout(timer); resolve(); } };
    });
  }

  _handle(data) {
    if (data.type === 'error') { this._fail(Error(data.message)); return; }
    if (data.type !== 'line') return;
    const line = data.line;
    if (this.handshake?.expected === line) {
      const { resolve } = this.handshake;
      this.handshake = null;
      resolve();
    }
    if (!this.pending) return;
    const info = parseInfo(line);
    if (info && info.multiPv <= this.pending.multiPv) {
      const previous = this.lines.get(info.multiPv);
      if (!previous || info.depth >= previous.depth) {
        this.lines.set(info.multiPv, info);
        this.onProgress(this._sorted());
      }
    }
    if (line.startsWith('bestmove ')) {
      const result = { bestMove: line.split(/\s+/)[1], lines: this._sorted() };
      const { resolve } = this.pending;
      clearTimeout(this.pending.timer);
      this.pending = null;
      resolve(result);
    }
  }

  _sorted() { return [...this.lines.values()].sort((a, b) => a.multiPv - b.multiPv); }

  _fail(error) {
    if (!this.pending) return;
    const { reject } = this.pending;
    clearTimeout(this.pending.timer);
    this.pending = null;
    reject(error);
  }

  async analyze(fen, { multiPv = 3, moveTimeMs = 900, onProgress = () => {} } = {}) {
    await this.init();
    if (this.pending) throw Error('Pikafish đang phân tích vị trí khác.');
    this.lines.clear();
    this.onProgress = onProgress;
    this._command(`setoption name MultiPV value ${Math.max(1, Math.min(5, multiPv))}`);
    this._command(`position fen ${fen}`);
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => this._fail(Error('Pikafish phân tích quá thời gian.')), moveTimeMs + 20000);
      this.pending = { resolve, reject, timer, multiPv };
      this._command(`go movetime ${moveTimeMs}`);
    });
  }

  dispose() {
    this._fail(Error('Pikafish đã dừng.'));
    this.worker?.terminate();
    this.worker = null;
  }
}
