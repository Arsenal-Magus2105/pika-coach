export const START_FEN = 'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1';

const PIECES = new Set('RNBAKCPrnbakcp');
const LABELS = {
  R: '車', N: '馬', B: '相', A: '仕', K: '帥', C: '炮', P: '兵',
  r: '車', n: '馬', b: '象', a: '士', k: '將', c: '砲', p: '卒',
};
const VIETNAMESE = { R: 'Xe', N: 'Mã', B: 'Tượng', A: 'Sĩ', K: 'Tướng', C: 'Pháo', P: 'Tốt' };

export function colorOf(piece) {
  if (!piece) return null;
  return piece === piece.toUpperCase() ? 'w' : 'b';
}

export function parseFen(fen) {
  const [layout, side = 'w'] = fen.trim().split(/\s+/);
  if (!['w', 'b'].includes(side)) throw Error('Lượt đi trong FEN phải là w hoặc b.');
  const rows = layout?.split('/');
  if (rows?.length !== 10) throw Error('FEN phải có đúng 10 hàng.');
  const board = [];
  for (const row of rows) {
    for (const symbol of row) {
      if (/^[1-9]$/.test(symbol)) board.push(...Array(Number(symbol)).fill(null));
      else if (PIECES.has(symbol)) board.push(symbol);
      else throw Error(`Ký tự FEN không hợp lệ: ${symbol}`);
    }
    if (board.length % 9 !== 0) throw Error('Mỗi hàng FEN phải có 9 ô.');
  }
  if (board.length !== 90) throw Error('FEN phải có đúng 90 ô.');
  if (board.filter(piece => piece === 'K').length !== 1 || board.filter(piece => piece === 'k').length !== 1) {
    throw Error('FEN cần đủ hai quân Tướng.');
  }
  return { board, side };
}

export function toFen({ board, side }) {
  const ranks = [];
  for (let rank = 0; rank < 10; rank++) {
    let rankText = '', empty = 0;
    for (let file = 0; file < 9; file++) {
      const piece = board[rank * 9 + file];
      if (!piece) empty++;
      else {
        if (empty) rankText += String(empty);
        rankText += piece;
        empty = 0;
      }
    }
    if (empty) rankText += String(empty);
    ranks.push(rankText);
  }
  return `${ranks.join('/')} ${side} - - 0 1`;
}

export function toUci(from, to) {
  const square = index => String.fromCharCode(97 + index % 9) + String(9 - Math.floor(index / 9));
  return square(from) + square(to);
}

export function fromUci(value) {
  if (!/^[a-i][0-9][a-i][0-9]$/.test(value)) return null;
  const index = (file, rank) => (9 - Number(rank)) * 9 + file.charCodeAt(0) - 97;
  return [index(value[0], value[1]), index(value[2], value[3])];
}

const row = index => Math.floor(index / 9);
const col = index => index % 9;
const inPalace = (r, c, side) => c >= 3 && c <= 5 && (side === 'w' ? r >= 7 && r <= 9 : r >= 0 && r <= 2);

function blockers(board, a, b) {
  const ar = row(a), ac = col(a), br = row(b), bc = col(b);
  if (ar !== br && ac !== bc) return -1;
  const step = ar === br ? Math.sign(bc - ac) : 9 * Math.sign(br - ar);
  let count = 0;
  for (let i = a + step; i !== b; i += step) if (board[i]) count++;
  return count;
}

export function pseudoLegal(board, from, to) {
  if (from === to || from < 0 || to < 0 || from >= 90 || to >= 90) return false;
  const piece = board[from], target = board[to];
  if (!piece || (target && colorOf(piece) === colorOf(target))) return false;
  const side = colorOf(piece), r = row(from), c = col(from), nr = row(to), nc = col(to);
  const dr = nr - r, dc = nc - c;
  switch (piece.toUpperCase()) {
    case 'R': return (dr === 0 || dc === 0) && blockers(board, from, to) === 0;
    case 'C': return (dr === 0 || dc === 0) && blockers(board, from, to) === (target ? 1 : 0);
    case 'N': {
      if (Math.abs(dr) === 2 && Math.abs(dc) === 1) return !board[(r + Math.sign(dr)) * 9 + c];
      if (Math.abs(dc) === 2 && Math.abs(dr) === 1) return !board[r * 9 + c + Math.sign(dc)];
      return false;
    }
    case 'B': {
      if (Math.abs(dr) !== 2 || Math.abs(dc) !== 2) return false;
      if (side === 'w' ? nr < 5 : nr > 4) return false;
      return !board[(r + dr / 2) * 9 + c + dc / 2];
    }
    case 'A': return Math.abs(dr) === 1 && Math.abs(dc) === 1 && inPalace(nr, nc, side);
    case 'K': {
      if (target?.toUpperCase() === 'K' && dc === 0 && blockers(board, from, to) === 0) return true;
      return Math.abs(dr) + Math.abs(dc) === 1 && inPalace(nr, nc, side);
    }
    case 'P': {
      if (dr === (side === 'w' ? -1 : 1) && dc === 0) return true;
      return (side === 'w' ? r <= 4 : r >= 5) && dr === 0 && Math.abs(dc) === 1;
    }
    default: return false;
  }
}

export function isInCheck(board, side) {
  const king = board.indexOf(side === 'w' ? 'K' : 'k');
  if (king < 0) return true;
  for (let from = 0; from < 90; from++) {
    if (colorOf(board[from]) !== (side === 'w' ? 'b' : 'w')) continue;
    if (pseudoLegal(board, from, king)) return true;
  }
  return false;
}

export function legalMove(position, from, to) {
  const { board, side } = position;
  if (colorOf(board[from]) !== side || !pseudoLegal(board, from, to)) return false;
  const next = board.slice();
  next[to] = next[from];
  next[from] = null;
  return !isInCheck(next, side);
}

export function playMove(position, from, to) {
  if (!legalMove(position, from, to)) return null;
  const board = position.board.slice();
  board[to] = board[from];
  board[from] = null;
  return { board, side: position.side === 'w' ? 'b' : 'w' };
}

export function pieceLabel(piece) { return LABELS[piece] ?? ''; }

export function moveLabel(position, uci) {
  const move = fromUci(uci);
  if (!move) return uci;
  const [from, to] = move, piece = position.board[from];
  if (!piece) return uci;
  const side = colorOf(piece), current = side === 'w' ? 9 - col(from) : col(from) + 1;
  const target = side === 'w' ? 9 - col(to) : col(to) + 1;
  const dr = row(to) - row(from);
  const action = dr === 0 ? 'bình' : (dr < 0) === (side === 'w') ? 'tiến' : 'thoái';
  const last = dr === 0 || 'NBA'.includes(piece.toUpperCase()) ? target : Math.abs(dr);
  return `${VIETNAMESE[piece.toUpperCase()]} ${current} ${action} ${last}`;
}
