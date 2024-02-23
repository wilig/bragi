package piece_table

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:testing"

LINE_ENDING :: "\n"

BufferType :: enum {
	Immutable,
	Mutable,
}

// Piece represents a contiguous span of text in the piece table.
Piece :: struct {
	start:        int,
	length:       int,
	line_count:   int,
	line_offsets: [dynamic]int,
	type:         BufferType,
}

// Currently we somewhat naively store pieces in a list, and stores
// line information and offsets for each piece.  In the future, we
// may want to consider moving to a binary tree or skip list for
// faster lookups.
PieceTable :: struct {
	pieces:        [dynamic]Piece,
	static_buffer: string,
	buffer:        [dynamic]u8,
}


/*
  Calculates the line offsets for a given piece of text.

  Input:
   * A string of text

  Returns:
   * An array of line offsets
*/
calculate_line_offsets :: proc(text: string) -> (offsets: [dynamic]int) {
	for i := 0; i < len(text); i += 1 {
		if text[i] == LINE_ENDING[0] {
			append(&offsets, i + 1)
		}
	}
	return
}

/*
  Updates the line count and line offsets for a given piece.

  Input:
   * A pointer to a piece table
   * A pointer to a piece
*/
update_piece_attributes :: proc(table: ^PieceTable, piece: ^Piece) {
	chunk := get_piece_chunk(table^, piece^)
	piece.line_count = strings.count(chunk, LINE_ENDING)
	piece.line_offsets = calculate_line_offsets(chunk)
}

/*
  Gets the text chunk for a given piece.

  Input:
   * A pointer to a piece table
   * A pointer to a piece

  Returns:
   * The text chunk for the piece
*/
get_piece_chunk :: proc(table: PieceTable, piece: Piece) -> (chunk: string) {
	switch piece.type {
	case .Immutable:
		chunk = table.static_buffer[piece.start:piece.start + piece.length]
	case .Mutable:
		chunk = string(table.buffer[piece.start:piece.start + piece.length])
	}
	return
}

/*
  Initializes a new piece with a given text chunk.

  Input:
   * A string of text (piece length in calcualted from the string)
   * The starting position of the piece, in the buffer
   * The type of buffer

  Returns:
   * A new piece
*/
init_piece :: proc(chunk: string, start: int = 0, type: BufferType = .Mutable) -> (piece: Piece) {
	piece = Piece {
		start        = start,
		length       = len(chunk),
		type         = type,
		line_count   = strings.count(chunk, LINE_ENDING),
		line_offsets = calculate_line_offsets(chunk),
	}
	return
}

/*
  Initializes a new piece table with a given string.

  Input:
   * A string to initialize the piece table with

  Returns:
   * A pointer to the piece table
   * An error if the piece table could not be initialized
*/
init :: proc(source: string) -> (pt: ^PieceTable, err: mem.Allocator_Error) {
	pt = new(PieceTable) or_return
	pt.static_buffer = source
	piece := init_piece(source, 0, .Immutable)
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
split_piece :: proc(table: ^PieceTable, piece_idx: int, offset: int) -> Piece {
	piece := &table.pieces[piece_idx]
	// Get the text chunk for the piece, and create a new piece from the split
	chunk := get_piece_chunk(table^, piece^)
	new_piece := init_piece(chunk[offset:], piece.start + offset, piece.type)

	// Update the original piece
	piece.length = offset
	update_piece_attributes(table, piece)
	return new_piece
}

/*
  Gets the line offset, and length for a given range of lines.

  Input:
   * A pointer to a piece table
   * The starting line
   * The number of lines to get

  Returns:
   * Starting offset and length (Use get_span to get the text for the lines)
*/
get_line_offsets :: proc(
	table: ^PieceTable,
	starting_line: int,
	number_of_lines: int = 1,
) -> (
	start: int,
	length: int,
) {
	starting_line := starting_line - 1
	number_of_lines := number_of_lines // Make it mutable
	offset_from_start := 0
	for piece, idx in table.pieces {
		if starting_line <= piece.line_count {
			// line offsets are always one less than the line number
			offset_in_piece := 0 if starting_line == 0 else piece.line_offsets[starting_line - 1]
			start = offset_from_start + offset_in_piece
			if number_of_lines <= piece.line_count - starting_line {
				// All the lines are in this piece
				length = piece.line_offsets[starting_line + number_of_lines - 1] - offset_in_piece
				return
			} else {
				// We need to get the rest of the lines from later pieces
				length_from_start := piece.length - offset_in_piece
				for piece in table.pieces[idx + 1:] {
					if number_of_lines <= piece.line_count {
						length = length_from_start + piece.line_offsets[number_of_lines - 1]
						return
					}
					number_of_lines -= piece.line_count
					length_from_start += piece.length
				}
				// If we get here, we've gone through all the pieces and still haven't found all
				// the lines. So we just return the length of the last remaining piece.
				return start, length_from_start
			}
		}
		starting_line -= piece.line_count
		offset_from_start += piece.length
	}
	return
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

can_append_in_place :: proc(table: ^PieceTable, piece: ^Piece) -> bool {
	return len(table.buffer) == piece.start + piece.length
}

/*
Inserts a string into the piece table.

String may be inserted as a new piece or appended to the buffer if the position is at the end of the buffer.

Input:
 * A pointer to a piece table
 * A string to insert
 * The position at which it should be inserted (Anything larger then the overall length with cause an append)

Returns:
 * A boolean indicating success

*/
insert :: proc(table: ^PieceTable, chunk: string, position: int) -> bool {
	piece_idx, offset, ok := find_piece(table.pieces[:], position)
	piece := &table.pieces[piece_idx] if ok else &table.pieces[len(table.pieces) - 1]
	if !ok && can_append_in_place(table, piece) {
		// It's at the end of the buffer, so just update the pieces length
		append(&table.buffer, chunk)
		piece.length += len(chunk)
	} else {
		// Create a new piece and insert it into the piece table
		new_piece := init_piece(chunk, len(table.buffer), .Mutable)
		append(&table.buffer, chunk)
		if !ok {
			append(&table.pieces, new_piece)
		} else if offset == 0 {
			inject_at(&table.pieces, piece_idx, new_piece)
		} else {
			// Split the piece and insert the new piece in the middle.
			piece_part_two := split_piece(table, piece_idx, offset)
			inject_at(&table.pieces, piece_idx + 1, new_piece)
			inject_at(&table.pieces, piece_idx + 2, piece_part_two)
		}
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
			piece.line_count += next_piece.line_count
			append(&piece.line_offsets, ..next_piece.line_offsets[:])
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
remove :: proc(table: ^PieceTable, start, length: int) -> bool {
	length := length
	idx, offset := find_piece(table.pieces[:], start) or_return
	piece := &table.pieces[idx]

	// Span is contained within one piece
	if piece.length - offset >= length {
		if offset == 0 { 	// It's at the beginning to restart the starting index
			piece.start = length
			piece.length -= length
		} else if (piece.length - offset == length) { 	// It's at the end, so reset length
			piece.length = offset + length
		} else { 	// There are bits hanging on both ends, so split into two pieces
			new_piece := split_piece(table, idx, offset + length)
			inject_at(&table.pieces, idx + 1, new_piece)
			piece.length = offset
		}
		update_piece_attributes(table, piece)
	} else {
		// Span is spread across multiple pieces
		previous_piece_idx := idx - 1
		for length > 0 {
			piece_length := piece.length
			if piece.length > length {
				// Span ends within piece
				piece.start += length
                piece.length -= length
				update_piece_attributes(table, piece)
				break
			} else {
				// Entire piece is within span, remove it.
				length -= piece.length
				ordered_remove(&table.pieces, idx)
				// Get the next piece, it will be the new piece at the current index
				piece = &table.pieces[idx]
			}
		}
		maybe_merge_pieces(table, previous_piece_idx)
	}
	return true
}
