import { START_FEN, colorOf, fromUci, legalMove, moveLabel, parseFen, pieceLabel, playMove, toFen, toUci } from './xiangqi.js';
import { scoreText, WebPikafish } from './engine.js';

const $ = id => document.getElementById(id);
let position = parseFen(START_FEN);
let history = [];
let selected = null;
let lastMove = null;
let hinted = null;
let lines = [];
let analysisPosition = null;
let replay = null;
let busy = false;
let engineReady = false;
let pendingReview = null;
const engine = new WebPikafish();

function message(text) { $('message').textContent = text; }
function status(text, error = false) {
  $('engine-status').textContent = text;
  $('engine-status').classList.toggle('error', error);
}

function renderBoard() {
  const display = replay ? replay.positions[replay.index] : position;
  const squares = $('squares');
  squares.replaceChildren();
  for (let index = 0; index < 90; index++) {
    const square = document.createElement('button');
    square.type = 'button';
    square.className = 'square';
    square.style.left = `${(index % 9) * 12.5}%`;
    square.style.top = `${Math.floor(index / 9) * 100 / 9}%`;
    if (!replay && index === selected) square.classList.add('selected');
    if (!replay && hinted?.includes(index)) square.classList.add('hint');
    if (!replay && lastMove?.includes(index)) square.classList.add('last');
    const piece = display.board[index];
    square.setAttribute('aria-label', `${piece ? `${colorOf(piece) === 'w' ? 'Đỏ' : 'Đen'} ${pieceLabel(piece)}` : 'Ô trống'} ${String.fromCharCode(97 + index % 9)}${9 - Math.floor(index / 9)}`);
    if (piece) {
      const content = document.createElement('span');
      content.className = `piece ${colorOf(piece) === 'b' ? 'black' : 'red'}`;
      content.textContent = pieceLabel(piece);
      square.append(content);
    }
    square.addEventListener('click', () => tapSquare(index));
    squares.append(square);
  }
  $('turn').textContent = replay ? 'Xem biến' : `${position.side === 'w' ? 'Đỏ' : 'Đen'} đi`;
  $('move-count').textContent = `Nước ${history.length + 1}`;
  $('fen').value = toFen(position);
  $('undo').disabled = busy || history.length === 0;
  $('hint').disabled = busy || !engineReady;
  $('analyze').disabled = busy || !engineReady;
}

function resetAnalysis() {
  lines = [];
  analysisPosition = null;
  hinted = null;
  replay = null;
  $('replay').hidden = true;
  $('review').hidden = true;
  renderLines();
}

async function tapSquare(index) {
  if (replay || busy) return;
  const piece = position.board[index];
  if (selected === null) {
    if (colorOf(piece) === position.side) { selected = index; renderBoard(); }
    return;
  }
  if (selected === index) { selected = null; renderBoard(); return; }
  if (colorOf(piece) === position.side) { selected = index; renderBoard(); return; }
  const from = selected;
  selected = null;
  if (!legalMove(position, from, index)) { message('Nước đi chưa hợp lệ hoặc Tướng sẽ bị chiếu.'); renderBoard(); return; }
  const before = position;
  const move = toUci(from, index);
  const cached = analysisPosition && toFen(analysisPosition) === toFen(before) ? lines.slice() : [];
  history.push({ position: before, lastMove });
  position = playMove(before, from, index);
  lastMove = [from, index];
  resetAnalysis();
  renderBoard();
  message(`Đã đi ${moveLabel(before, move)}. Đang tìm gợi ý cho lượt tiếp theo…`);
  if (engineReady) await analyzeAfterMove(before, move, cached);
  else pendingReview = { before, move, cached };
}

function setBusy(value) {
  busy = value;
  renderBoard();
  $('reset').disabled = value;
  $('load-fen').disabled = value;
}

async function requestAnalysis(showHint = false) {
  if (busy || !engineReady || replay) return;
  const root = position;
  setBusy(true);
  status('Đang phân tích…');
  message('Pikafish đang tìm các nước mạnh nhất trong vị trí này.');
  try {
    const result = await engine.analyze(toFen(root), {
      multiPv: Number($('multi-pv').value),
      moveTimeMs: Number($('think-time').value),
      onProgress: progress => {
        lines = progress;
        analysisPosition = root;
        renderLines();
      },
    });
    lines = result.lines;
    analysisPosition = root;
    hinted = fromUci(lines[0]?.moves[0] ?? result.bestMove);
    renderLines();
    message(showHint ? 'Gợi ý đã được đánh dấu trên bàn. Sếp thử tự đi nước đó.' : 'Chạm một dòng bên dưới để xem từng nước của biến.');
  } catch (error) {
    message(`Không phân tích được: ${error.message}`);
    status('Lỗi Pikafish', true);
  } finally {
    setBusy(false);
    if (engineReady) status('Pikafish sẵn sàng');
  }
}

async function analyzeAfterMove(before, played, cached) {
  setBusy(true);
  status('Đang tìm gợi ý…');
  try {
    const options = { multiPv: Number($('multi-pv').value), moveTimeMs: Number($('think-time').value) };
    const current = position;
    const result = await engine.analyze(toFen(current), {
      ...options,
      onProgress: progress => {
        lines = progress;
        analysisPosition = current;
        hinted = fromUci(progress[0]?.moves[0]);
        renderLines();
        renderBoard();
      },
    });
    lines = result.lines;
    analysisPosition = current;
    hinted = fromUci(lines[0]?.moves[0] ?? result.bestMove);
    renderLines();
    renderBoard();
    message('Đã có gợi ý cho lượt này. Đang chấm nước vừa đi…');
    await grade(before, played, cached, lines[0]?.score);
  } catch (error) {
    message(`Không phân tích được: ${error.message}`);
    status('Lỗi Pikafish', true);
  } finally {
    setBusy(false);
    if (engineReady) status('Pikafish sẵn sàng');
  }
}

async function grade(before, played, cached, afterScore) {
  try {
    const options = { multiPv: Number($('multi-pv').value), moveTimeMs: Number($('think-time').value) };
    const beforeLines = cached.length ? cached : (await engine.analyze(toFen(before), options)).lines;
    const best = beforeLines[0];
    if (!best?.moves.length) throw Error('Pikafish chưa trả về nước hợp lệ.');
    let playedScore = beforeLines.find(candidate => candidate.moves[0] === played)?.score;
    if (!playedScore) {
      if (!afterScore) throw Error('Chưa có điểm cho nước vừa đi.');
      playedScore = { ...afterScore, value: -afterScore.value };
    }
    const diff = best.score.type === 'cp' && playedScore.type === 'cp'
      ? Math.max(0, best.score.value - playedScore.value) : null;
    const label = diff === null ? 'So sánh biến' : diff <= 30 ? 'Nước rất tốt' : diff <= 75 ? 'Nước tốt' : diff <= 150 ? 'Bỏ lỡ cơ hội' : 'Cần xem lại';
    const review = $('review-text');
    review.replaceChildren();
    const summary = document.createElement('p');
    summary.textContent = `${moveLabel(before, played)} · ${scoreText(playedScore)}`;
    const detail = document.createElement('p');
    detail.textContent = `Pikafish chọn ${moveLabel(before, best.moves[0])} (${scoreText(best.score)})${diff === null ? '' : ` · chênh ${(diff / 100).toFixed(2)}`}`;
    const quality = document.createElement('strong');
    quality.textContent = label;
    review.append(summary, detail, quality);
    $('review').hidden = false;
    message('Nước vừa đi đã được chấm. Gợi ý cho lượt tiếp theo đang hiển thị trên bàn.');
  } catch (error) {
    message(`Chưa chấm được nước: ${error.message}`);
  }
}

function renderLines() {
  const list = $('lines');
  list.replaceChildren();
  const first = lines[0];
  $('best-move').textContent = first?.moves.length && analysisPosition ? moveLabel(analysisPosition, first.moves[0]) : '—';
  $('best-score').textContent = first ? scoreText(first.score) : 'Chưa phân tích';
  $('depth').textContent = first ? `DEPTH ${first.depth} · ${lines.length} BIẾN` : `MULTIPV ${$('multi-pv').value}`;
  if (!lines.length) {
    const empty = document.createElement('p');
    empty.className = 'empty';
    empty.textContent = 'Kết quả Pikafish sẽ hiện tại đây.';
    list.append(empty);
    return;
  }
  for (const line of lines) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'line';
    const rank = document.createElement('span');
    rank.className = 'line-rank';
    rank.textContent = String(line.multiPv).padStart(2, '0');
    const middle = document.createElement('span');
    middle.className = 'line-main';
    const name = document.createElement('strong');
    name.textContent = analysisPosition ? moveLabel(analysisPosition, line.moves[0]) : line.moves[0];
    const detail = document.createElement('small');
    detail.textContent = `Xem biến · ${line.moves.slice(0, 3).join(' · ')}`;
    middle.append(name, detail);
    const score = document.createElement('span');
    score.className = 'line-score';
    score.textContent = scoreText(line.score);
    button.append(rank, middle, score);
    button.addEventListener('click', () => showReplay(line));
    list.append(button);
  }
}

function showReplay(line) {
  if (!analysisPosition || busy) return;
  const positions = [analysisPosition];
  let current = analysisPosition;
  for (const uci of line.moves.slice(0, 20)) {
    const move = fromUci(uci);
    if (!move) break;
    const next = playMove(current, ...move);
    if (!next) break;
    positions.push(next);
    current = next;
  }
  replay = { positions, index: 0, moves: line.moves.slice(0, positions.length - 1) };
  $('replay').hidden = false;
  renderReplay();
}

function renderReplay() {
  if (!replay) return;
  $('replay-counter').textContent = `${replay.index} / ${replay.moves.length}`;
  $('replay-label').textContent = replay.index
    ? moveLabel(replay.positions[replay.index - 1], replay.moves[replay.index - 1])
    : 'Thế cờ trước khi đi';
  $('replay-prev').disabled = replay.index === 0;
  $('replay-next').disabled = replay.index >= replay.moves.length;
  renderBoard();
}

$('squares');
$('hint').addEventListener('click', () => requestAnalysis(true));
$('analyze').addEventListener('click', () => requestAnalysis());
$('undo').addEventListener('click', () => {
  if (busy || !history.length) return;
  pendingReview = null;
  const previous = history.pop();
  position = previous.position;
  lastMove = previous.lastMove;
  selected = null;
  resetAnalysis();
  renderBoard();
  message('Đã hoàn tác nước vừa đi.');
});
$('reset').addEventListener('click', () => {
  if (busy) return;
  pendingReview = null;
  position = parseFen(START_FEN);
  history = [];
  lastMove = null;
  selected = null;
  resetAnalysis();
  renderBoard();
  message('Ván mới đã sẵn sàng.');
});
$('load-fen').addEventListener('click', () => {
  if (busy) return;
  try {
    position = parseFen($('fen').value);
    pendingReview = null;
    history = [];
    lastMove = null;
    selected = null;
    resetAnalysis();
    renderBoard();
    message('Đã nạp thế cờ từ FEN.');
  } catch (error) { message(error.message); }
});
$('copy-fen').addEventListener('click', async () => {
  try { await navigator.clipboard.writeText(toFen(position)); message('Đã sao chép FEN.'); }
  catch { $('fen').focus(); $('fen').select(); message('Hãy sao chép FEN từ ô nhập phía trên.'); }
});
$('replay-close').addEventListener('click', () => { replay = null; $('replay').hidden = true; renderBoard(); });
$('replay-prev').addEventListener('click', () => { if (replay && replay.index > 0) { replay.index--; renderReplay(); } });
$('replay-next').addEventListener('click', () => { if (replay && replay.index < replay.moves.length) { replay.index++; renderReplay(); } });
$('multi-pv').addEventListener('change', renderLines);

renderBoard();
renderLines();
engine.init().then(() => {
  engineReady = true;
  status('Pikafish sẵn sàng');
  message('Pikafish sẵn sàng. Sau mỗi nước đi, gợi ý sẽ tự hiện; sếp cũng có thể phân tích ngay thế hiện tại.');
  renderBoard();
  if (pendingReview) {
    const { before, move, cached } = pendingReview;
    pendingReview = null;
    void analyzeAfterMove(before, move, cached);
  }
}).catch(error => {
  status('Pikafish không khả dụng', true);
  message(`Bàn cờ vẫn dùng được. Lỗi tải engine: ${error.message}`);
});

if ('serviceWorker' in navigator && location.protocol === 'https:') {
  navigator.serviceWorker.register('./sw.js').catch(() => {});
}
