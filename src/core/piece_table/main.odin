package piece_table

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:testing"

BufferType :: enum {
	Immutable,
	Mutable,
	Appendable,
}

Piece :: struct {
	start:  int,
	length: int,
	type:   BufferType,
}

PieceTable :: struct {
	pieces:              [dynamic]Piece,
	static_buffer:       string,
	appendable_position: int,
	buffer:              [dynamic]u8,
	appendable:          [dynamic]u8,
}


/*
  Initializes a new piece table with a given string.

  Input:
   * A string to initialize the piece table with

  Returns:
   * A pointer to the piece table 
   * An error if the piece table could not be initialized
*/
init :: proc(static: string) -> (pt: ^PieceTable, err: mem.Allocator_Error) {
	pt = new(PieceTable) or_return
	piece := Piece {
		start  = 0,
		length = len(static),
		type   = .Immutable,
	}
	pt.static_buffer = static
	append(&pt.pieces, piece)
	return
}

/*
  Splits a piece into two pieces at a given offset.

  Input:
   * A pointer to a piece
   * The index at which to split the piece

  Returns:
   * A new piece starting at the split location
*/
split_piece :: proc(piece: ^Piece, offset: int) -> Piece {
	piece := piece
	new_piece := Piece {
		start  = piece.start + offset,
		length = piece.length - offset,
		type   = piece.type,
	}
	piece.length = offset
	return new_piece
}

/*
  Finds the piece that contains a given position in the piece table.

  Input:
   * A slice of pieces
   * The position to find

  Returns:
   * The index of the piece that contains the position
   * The offset of the position within the piece
   * A boolean indicating if the position was found
*/
find_piece :: proc(pieces: []Piece, start: int) -> (idx: int, offset: int, found: bool) {
	start := start
	for piece, idx in pieces {
		if piece.length > start {
			return idx, start, true
		}
		start -= piece.length
	}
	return
}

/*
  Gets a contiguous span of text from the piece table.

  Input:
   * A pointer to a piece table
   * The start position of the span to get
   * The length of the span to get

  Returns:
   * The text of the span
   * A boolean indicating if the span was found
*/
get_span :: proc(table: ^PieceTable, start: int, length: int) -> (text: string, found: bool) {
	piece_idx, offset := find_piece(table.pieces[:], start) or_return
	found = true
	remaining_length := length
	sb := strings.builder_make()
	for ; piece_idx < len(table.pieces); piece_idx += 1 {
		piece := table.pieces[piece_idx]
		start := piece.start + offset
		end := min(start + piece.length - offset, start + remaining_length)
		switch piece.type {
		case .Immutable:
			strings.write_string(&sb, table.static_buffer[start:end])
		case .Mutable:
			strings.write_bytes(&sb, table.buffer[start:end])
		case .Appendable:
			strings.write_bytes(&sb, table.appendable[start:end])
		}
		remaining_length = remaining_length - (end - start)
		if remaining_length <= 0 {
			break
		}
		offset = 0
	}
	text = strings.to_string(sb)
	return
}

/*
Inserts a string into the piece table as a new piece.

Input:
 * A pointer to a piece table
 * A string to insert
 * The position at which it should be inserted (Anything larger then the overall length with cause an append)

Returns:
 * A boolean indicating success

*/
// TODO: Handle appendable buffer
insert :: proc(table: ^PieceTable, chunk: string, position: int) -> bool {
	new_piece := Piece {
		start  = len(table.buffer),
		length = len(chunk),
		type   = .Mutable,
	}
	append(&table.buffer, chunk)
	piece_idx, offset, ok := find_piece(table.pieces[:], position)
	if !ok {
		// It's after the last piece, so append it
		append(&table.pieces, new_piece)
	} else if offset == 0 {
		// Insert it before the current piece
		inject_at(&table.pieces, piece_idx, new_piece)
	} else {
		// Split the piece and insert the new piece in the middle.
		piece_part_two := split_piece(&table.pieces[piece_idx], offset)
		inject_at(&table.pieces, piece_idx + 1, new_piece)
		inject_at(&table.pieces, piece_idx + 2, piece_part_two)
	}
	return true
}

/*
 Tries to merge two pieces in the piece table, if the pieces are adjacent and of the same type.

 Input:
 * A pointer to a piece table
 * The index of the starting piece
*/
maybe_merge_pieces :: proc(table: ^PieceTable, idx: int) {
	if idx >= 0 && idx + 1 < len(table.pieces) {
		piece := &table.pieces[idx]
		next_piece := &table.pieces[idx + 1]
		// If the pieces are adjacent in the same buffer, merge them.
		if piece.type == next_piece.type && piece.start + piece.length == next_piece.start {
			piece.length += next_piece.length
			ordered_remove(&table.pieces, idx + 1)
		}
	}
}

/*
 Delete a span from the document represented by piece table

 Input:
 * A pointer to a piece table
 * The start position of the span to delete
 * The length of the span to delete

 Returns:
 * A boolean indicating success

*/
// TODO: Handle appendable buffer
remove :: proc(table: ^PieceTable, start, length: int) -> bool {
	length := length
	idx, offset := find_piece(table.pieces[:], start) or_return
	piece := &table.pieces[idx]

	// Span is contained within one piece
	if piece.length - offset >= length {
		if offset == 0 { 	// It's at the beginning to restart the starting index
			piece.start = length
		} else if (piece.length - offset == length) { 	// It's at the end, so reset length
			piece.length = offset + length
		} else { 	// There are bits hanging on both ends, so split into two pieces
			new_piece := split_piece(piece, offset + length)
			inject_at(&table.pieces, idx + 1, new_piece)
			piece.length = offset
		}
	} else {
		// Span is spread across multiple pieces
		previous_piece_idx := idx - 1
		for length > 0 {
			piece_length := piece.length
			if piece.length > length {
				// Span ends within piece
				piece.start += length
				break
			} else {
				// Entire piece is within span, remove it.
				length -= piece.length
				ordered_remove(&table.pieces, idx)
				// Get the next piece
				piece = &table.pieces[idx]
			}
		}
		maybe_merge_pieces(table, previous_piece_idx)
	}
	return true
}

/*
set_appendable_position :: proc(table: ^PieceTable, position: int) {
	idx, offset := find_piece(table.pieces[:], position) or_return
	piece := &table.pieces[idx]
	if piece.type == .Appendable {
		return
	} else {
		current_appendable_piece := find_appendable_piece(table.pieces[:])
		if piece.length > 0 {
			// Convert the current appendable buffer to a mutable piece
			start_position := len(table.buffer)
			length := len(table.appendable)
			append(&table.buffer, table.appendable[:])
			current_appendable_piece.start = start_position
			current_appendable_piece.length = length
			current_appendable_piece.type = .Mutable
		}
		new_appendable_piece := Piece {
			start  = position,
			length = 0,
			type   = .Appendable,
		}
		if offset == 0 {
			inject_at(&table.pieces, idx, new_appendable_piece)
		} else if offset == piece.length {
			inject_at(&table.pieces, idx + 1, new_appendable_piece)
		} else {
			// Split the piece and insert the appendable piece in the middle.
			piece_part_two = split_piece(&table.pieces[idx], offset)
			inject_at(&table.pieces, idx + 1, new_appendable_piece)
			inject_at(&table.pieces, idx + 2, piece_part_two)
		}
	}
}
*/

// TODO: Append buffer
// TODO: Rune to byte conversion on append buffer
