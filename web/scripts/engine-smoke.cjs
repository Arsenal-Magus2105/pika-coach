const assert = require('node:assert/strict');
const path = require('node:path');
const Pikafish = require('../vendor/pikafish.js');
const vendor = path.resolve(__dirname, '../vendor');

(async () => {
  const output = [];
  const engine = await Pikafish({
    locateFile: file => path.join(vendor, file),
    read_stdout: line => output.push(line),
  });
  engine.send_command('uci');
  engine.send_command('isready');
  engine.send_command('setoption name MultiPV value 3');
  engine.send_command('position startpos');
  engine.send_command('go movetime 200');
  assert(output.some(line => line.includes('uciok')), 'missing uciok');
  assert(output.some(line => line.includes('readyok')), 'missing readyok');
  assert(output.some(line => /info .*score .* pv /.test(line)), 'missing evaluated principal variation');
  assert(output.some(line => /bestmove [a-i][0-9][a-i][0-9]/.test(line)), 'missing legal bestmove');
  console.log('Pikafish WebAssembly answered UCI, MultiPV and bestmove.');
})().catch(error => { console.error(error); process.exitCode = 1; });
