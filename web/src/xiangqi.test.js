import test from 'node:test';
import assert from 'node:assert/strict';
import { START_FEN, fromUci, isInCheck, legalMove, moveLabel, parseFen, playMove, toFen, toUci } from './xiangqi.js';

test('opening FEN and Pikafish coordinates round-trip', () => {
  const start = parseFen(START_FEN);
  assert.equal(toFen(start), START_FEN);
  assert.deepEqual(fromUci('h2e2'), [70, 67]);
  assert.equal(toUci(70, 67), 'h2e2');
  assert.equal(moveLabel(start, 'h2e2'), 'Pháo 2 bình 5');
});

test('cannon needs exactly one screen to capture', () => {
  const start = parseFen(START_FEN);
  const cannon = fromUci('h2e2');
  assert.equal(legalMove(start, ...cannon), true);
  const noScreen = parseFen('3k5/9/9/9/9/9/9/1C7/9/4K4 w - - 0 1');
  assert.equal(legalMove(noScreen, ...fromUci('b2b5')), true);
  assert.equal(legalMove(noScreen, ...fromUci('b2b9')), true);
  const capture = parseFen('3k5/9/9/9/9/1p7/1P7/1C7/9/4K4 w - - 0 1');
  assert.equal(legalMove(capture, ...fromUci('b2b5')), false);
  assert.equal(legalMove(capture, ...fromUci('b2b4')), true);
});

test('horse leg, river and facing generals restrict moves', () => {
  const start = parseFen(START_FEN);
  assert.equal(legalMove(start, ...fromUci('b0c2')), true);
  const blockedHorse = parseFen('3k5/9/9/9/9/9/9/9/1P7/1N2K4 w - - 0 1');
  assert.equal(legalMove(blockedHorse, ...fromUci('b0a2')), false);
  assert.equal(legalMove(start, ...fromUci('c0e2')), true);
  const blockedElephant = parseFen('3k5/9/9/9/9/9/9/9/3P5/2B1K4 w - - 0 1');
  assert.equal(legalMove(blockedElephant, ...fromUci('c0e2')), false);
  const facing = parseFen('4k4/9/9/9/4R4/9/9/9/9/4K4 w - - 0 1');
  assert.equal(legalMove(facing, ...fromUci('e5d5')), false);
  assert.equal(legalMove(facing, ...fromUci('e5e6')), true);
});

test('check safety is enforced after move', () => {
  const position = parseFen('4k4/9/9/9/4r4/9/9/9/4R4/4K4 w - - 0 1');
  assert.equal(isInCheck(position.board, 'w'), false);
  assert.equal(legalMove(position, ...fromUci('e1e2')), true);
  const next = playMove(position, ...fromUci('e1e2'));
  assert.equal(next.side, 'b');
  assert.equal(legalMove(position, ...fromUci('e1d1')), false);
});

test('malformed FEN is rejected instead of rendering a partial board', () => {
  assert.throws(() => parseFen('9/9/9 w'), /10 hàng/);
  assert.throws(() => parseFen('4k4/9/9/9/9/9/9/9/9/9 w'), /hai quân Tướng/);
});
