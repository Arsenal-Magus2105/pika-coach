import test from 'node:test';
import assert from 'node:assert/strict';
import { parseInfo, scoreText } from './engine.js';

test('MultiPV parser keeps mate separate from centipawns', () => {
  const cp = parseInfo('info depth 16 seldepth 23 multipv 2 score cp 91 nodes 2300 pv h2e2 h9g7');
  assert.deepEqual(cp.score, { type: 'cp', value: 91 });
  assert.equal(cp.multiPv, 2);
  assert.deepEqual(cp.moves, ['h2e2', 'h9g7']);
  const mate = parseInfo('info depth 20 multipv 1 score mate -3 pv h0g2');
  assert.equal(scoreText(mate.score), 'Bị chiếu hết sau 3');
  assert.equal(scoreText(cp.score), '+0.91');
  assert.equal(parseInfo('info depth 12 score cp 14'), null);
});
