package piece_table

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:testing"


@(test)
test_initing_piece_table :: proc(t: ^testing.T) {
	test_str := "This is a test string for initing the piece table."
	pt, err := init(test_str)
	testing.expect(t, err == nil)
	testing.expect(t, pt.pieces[0].length == len(test_str))
}

@(test)
test_inserting_empty_string :: proc(t: ^testing.T) {
    base := "Hello, World!"
    pt, err := init(base)
    testing.expect(t, err == nil)

    // Test inserting an empty string at the beginning
    testing.expect(t, insert(pt, "", 0))
    testing.expect(t, len(pt.pieces) == 1, "Expected 1 piece after inserting empty string at the beginning")
    text, ok := get_span(pt, 0, len(base))
    testing.expect(t, ok)
    testing.expect(t, text == base, "Content should remain unchanged after inserting empty string at the beginning")

    // Test inserting an empty string in the middle
    testing.expect(t, insert(pt, "", 7))
    testing.expect(t, len(pt.pieces) == 1, "Expected 1 piece after inserting empty string in the middle")
    text, ok = get_span(pt, 0, len(base))
    testing.expect(t, ok)
    testing.expect(t, text == base, "Content should remain unchanged after inserting empty string in the middle")

    // Test inserting an empty string at the end
    testing.expect(t, insert(pt, "", len(base)))
    testing.expect(t, len(pt.pieces) == 1, "Expected 1 piece after inserting empty string at the end")
    text, ok = get_span(pt, 0, len(base))
    testing.expect(t, ok)
    testing.expect(t, text == base, "Content should remain unchanged after inserting empty string at the end")
}

@(test)
test_removing_empty_span :: proc(t: ^testing.T) {
    base := "Hello, World!"
    pt, err := init(base)
    testing.expect(t, err == nil)

    // Test removing an empty span from the beginning
    testing.expect(t, remove(pt, 0, 0))
    testing.expect(t, len(pt.pieces) == 1, "Expected 1 piece after removing empty span from the beginning")
    text, ok := get_span(pt, 0, len(base))
    testing.expect(t, ok)
    testing.expect(t, text == base, "Content should remain unchanged after removing empty span from the beginning")

    // Test removing an empty span from the middle
    testing.expect(t, remove(pt, 7, 0))
    testing.expect(t, len(pt.pieces) == 1, "Expected 1 piece after removing empty span from the middle")
    text, ok = get_span(pt, 0, len(base))
    testing.expect(t, ok)
    testing.expect(t, text == base, "Content should remain unchanged after removing empty span from the middle")

    // Test removing an empty span from the end
    testing.expect(t, remove(pt, len(base), 0))
    testing.expect(t, len(pt.pieces) == 1, "Expected 1 piece after removing empty span from the end")
    text, ok = get_span(pt, 0, len(base))
    testing.expect(t, ok)
    testing.expect(t, text == base, "Content should remain unchanged after removing empty span from the end")
}

@(test)
test_inserting_a_piece_in_the_middle_of_an_existing_piece :: proc(t: ^testing.T) {
	test_str := "Today is a good day!"
	pt, err := init(test_str)
	testing.expect(t, err == nil)
	testing.expect(t, insert(pt, "very ", 11))
	testing.expect(t, len(pt.pieces) == 3, "Expected 3 pieces")
	text, ok := get_span(pt, 0, 25)
	testing.expect(t, ok)
	testing.expect(t, text == "Today is a very good day!")
}

@(test)
test_inserting_a_piece_at_the_start_of_an_existing_piece :: proc(t: ^testing.T) {
	test_str := "Today is a good day!"
	pt, err := init(test_str)
	testing.expect(t, err == nil)
	testing.expect(t, insert(pt, "And ", 0))
	testing.expect(
		t,
		len(pt.pieces) == 2,
		fmt.tprintf("Expected 2 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok := get_span(pt, 0, 24)
	testing.expect(t, ok)
	testing.expect(t, text == "And Today is a good day!")
}

@(test)
test_inserting_a_piece_at_the_end_of_an_existing_piece :: proc(t: ^testing.T) {
	test_str := "This is the end"
	pt, err := init(test_str)
	testing.expect(t, err == nil)
	testing.expect(t, insert(pt, ", or is it?", 15))
	testing.expect(
		t,
		len(pt.pieces) == 2,
		fmt.tprintf("Expected 2 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok := get_span(pt, 0, 26)
	testing.expect(t, ok)
	testing.expect(t, text == "This is the end, or is it?")
}

@(test)
test_inserting_to_the_end_of_mutable_piece_at_the_end_of_the_buffer_does_not_create_a_new_piece :: proc(
	t: ^testing.T,
) {
	test_str := "Start, "
	pt, err := init(test_str)
	testing.expect(t, err == nil)
	testing.expect(t, insert(pt, "one, ", len(test_str)))
	testing.expect(t, insert(pt, "two, ", len(test_str) + 5))
	testing.expect(t, insert(pt, "three.", len(test_str) + 10))
	testing.expect(
		t,
		len(pt.pieces) == 2,
		fmt.tprintf("Expected 2 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok := get_span(pt, 0, 23)
	testing.expect(t, ok)
	testing.expect(t, text == "Start, one, two, three.")
}


@(test)
test_deleting_a_span_in_the_middle_of_an_existing_piece :: proc(t: ^testing.T) {
	pt, err := init("A this part will be deleted nice string")
	testing.expect(t, err == nil)
	testing.expect(t, remove(pt, 2, 26))
	testing.expect(
		t,
		len(pt.pieces) == 2,
		fmt.tprintf("Expected 2 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok := get_span(pt, 0, 13)
	testing.expect(t, ok)
	testing.expect(t, text == "A nice string")
}

@(test)
test_deleting_a_span_at_the_beginning_of_an_existing_piece :: proc(t: ^testing.T) {
	base :: "And have a lovely day!"
	removable :: "DELETE ME "
	pt, err := init(removable + base)
	testing.expect(t, err == nil)
	testing.expect(t, remove(pt, 0, len(removable)))
	testing.expect(
		t,
		len(pt.pieces) == 1,
		fmt.tprintf("Expected 1 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok := get_span(pt, 0, len(base))
	testing.expect(t, ok)
	testing.expect(t, text == base, fmt.tprintf("Expected '%s', but got '%s'\n", base, text))
}

@(test)
test_deleting_a_span_at_the_end_of_an_existing_piece :: proc(t: ^testing.T) {
	base :: "You have been warned!"
	removable :: " DELETE ME"
	pt, err := init(base + removable)
	testing.expect(t, err == nil)
	testing.expect(t, remove(pt, len(base), len(removable)))
	testing.expect(
		t,
		len(pt.pieces) == 1,
		fmt.tprintf("Expected 1 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok := get_span(pt, 0, len(base))
	testing.expect(t, ok)
	testing.expect(t, text == base, fmt.tprintf("Expected '%s', but got '%s'\n", base, text))
}

@(test)
test_deleting_a_span_at_that_spans_multiple_pieces :: proc(t: ^testing.T) {
	base :: "All your base are belong to us."
	insert_one :: " DELETE 1 "
	insert_two :: " DELETE 2 "
	insert_three :: " DELETE 3 "
	pt, err := init(base)
	testing.expect(t, err == nil)
	testing.expect(t, insert(pt, insert_three, 8))
	testing.expect(t, insert(pt, insert_two, 8))
	testing.expect(t, insert(pt, insert_one, 8))
	testing.expect(
		t,
		5 == len(pt.pieces),
		fmt.tprintf("Expected 5 pieces, got %d\n", len(pt.pieces)),
	)
	testing.expect(t, remove(pt, 8, len(insert_one) * 3))
	// Removing the span should have merged the pieces back into one.
	testing.expect(
		t,
		len(pt.pieces) == 1,
		fmt.tprintf("Expected 1 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok := get_span(pt, 0, len(base))
	testing.expect(t, ok)
	testing.expect(t, text == base, fmt.tprintf("Expected '%s', but got '%s'\n", base, text))
}

@(test)
test_deleting_a_span_at_that_spans_multiple_pieces_but_ends_in_the_middle_of_the_final_piece :: proc(
	t: ^testing.T,
) {
	base :: "All your base are belong to us."
	insert_one :: " DELETE 1 "
	insert_two :: " DELETE 2 "
	insert_three :: " DELETE 3 "
	pt, err := init(base)
	testing.expect(t, err == nil)
	testing.expect(t, insert(pt, insert_three, 8))
	testing.expect(t, insert(pt, insert_two, 8))
	testing.expect(t, insert(pt, insert_one, 8))
	testing.expect(
		t,
		5 == len(pt.pieces),
		fmt.tprintf("Expected 5 pieces, got %d\n", len(pt.pieces)),
	)
	testing.expect(t, remove(pt, 8, len(insert_one) * 2 + len(insert_three) / 2))
	// Removing the span should have merged the pieces back into one.
	testing.expect(
		t,
		len(pt.pieces) == 3,
		fmt.tprintf("Expected 1 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok := get_span(pt, 0, len(base) + len(insert_three) / 2)
	testing.expect(t, ok)
	testing.expect(t, text == "All yourTE 3  base are belong to us.")
}


@(test)
test_fetching_line_from_a_multiple_line_buffer :: proc(t: ^testing.T) {
	base :: "Line one\nLine twoish\nLine three\nLine four\nLine five\nLine six\nLine seven\nLine eight\nLine nine\nLine ten."
	pt, err := init(base)
	testing.expect(t, err == nil)
	start, end := get_line_offsets(pt, 1, 1)
	text, ok := get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line one\n")
	start, end = get_line_offsets(pt, 2, 1)
	text, ok = get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line twoish\n")
	start, end = get_line_offsets(pt, 3, 1)
	text, ok = get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line three\n")
	start, end = get_line_offsets(pt, 4, 1)
	text, ok = get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line four\n")
	start, end = get_line_offsets(pt, 5, 1)
	text, ok = get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line five\n")
	start, end = get_line_offsets(pt, 6, 1)
	text, ok = get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line six\n")
	start, end = get_line_offsets(pt, 7, 1)
	text, ok = get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line seven\n")
	start, end = get_line_offsets(pt, 8, 1)
	text, ok = get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line eight\n")
	start, end = get_line_offsets(pt, 9, 1)
	text, ok = get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line nine\n")
	start, end = get_line_offsets(pt, 10, 1)
	text, ok = get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line ten.")

	start, end = get_line_offsets(pt, 2, 2)
	text, ok = get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line twoish\nLine three\n")
}


@(test)
test_fetching_line_data_from_an_inserted_line :: proc(t: ^testing.T) {
	base :: "Line one\nLine two\nLine three\nLine four\nLine five."
	pt, err := init(base)
	testing.expect(t, err == nil)
	testing.expect(t, insert(pt, "\nLine one and a half", 8))
	testing.expect(
		t,
		len(pt.pieces) == 3,
		fmt.tprintf("Expected 3 pieces, got %d\n", len(pt.pieces)),
	)
	start, length := get_line_offsets(pt, 2, 1)
	text, ok := get_span(pt, start, length)
	testing.expect(t, ok)
	testing.expect(t, text == "Line one and a half\n")
}

@(test)
test_fetching_lines_near_boundaries :: proc(t: ^testing.T) {
    base := "First line\nSecond line\nThird line\nFourth line\nFifth line"
    pt, err := init(base)
    testing.expect(t, err == nil)

    // Test fetching the first line
    start, length := get_line_offsets(pt, 1, 1)
    text, ok := get_span(pt, start, length)
    testing.expect(t, ok)
    testing.expect(t, text == "First line\n", fmt.tprintf("Expected 'First line\\n', got '%s'", text))

    // Test fetching the last line
    start, length = get_line_offsets(pt, 5, 1)
    text, ok = get_span(pt, start, length)
    testing.expect(t, ok)
    testing.expect(t, text == "Fifth line", fmt.tprintf("Expected 'Fifth line', got '%s'", text))

    // Test fetching a partial line from the beginning
    start, length = get_line_offsets(pt, 1, 0)
    text, ok = get_span(pt, start, 5)
    testing.expect(t, ok)
    testing.expect(t, text == "First", fmt.tprintf("Expected 'First', got '%s'", text))

    // Test fetching a partial line from the end
    start, length = get_line_offsets(pt, 5, 0)
    text, ok = get_span(pt, start, 5)
    testing.expect(t, ok)
    testing.expect(t, text == "Fifth", fmt.tprintf("Expected 'Fifth', got '%s'", text))
}

@(test)
test_retrieving_lines_across_pieces :: proc(t: ^testing.T) {
	base :: "Line one\nLine two\nLine three."
	pt, err := init(base)
	testing.expect(t, err == nil)
	testing.expect(t, insert(pt, "\nLine one and a half", 8))
	testing.expect(
		t,
		len(pt.pieces) == 3,
		fmt.tprintf("Expected 3 pieces, got %d\n", len(pt.pieces)),
	)
	start, end := get_line_offsets(pt, 1, 4)
	text, ok := get_span(pt, start, end)
	testing.expect(t, ok)
	testing.expect(t, text == "Line one\nLine one and a half\nLine two\nLine three.")
}

@(test)
test_simple_undo_and_redo :: proc(t: ^testing.T) {
	base := "This a test string for initing the piece table."
	pt, err := init(base)
	testing.expect(t, err == nil)

	testing.expect(t, insert(pt, " is", 5))
	testing.expect(t, len(pt.pieces) == 3)

	undo(pt)
	testing.expect(t, len(pt.pieces) == 1)
	redo(pt)
	testing.expect(t, len(pt.pieces) == 3)
	undo(pt)

	text, ok := get_span(pt, 0, len(base))
	testing.expect(t, ok)
	remove(pt, 5, len(base) - 11)
	testing.expect(
		t,
		len(pt.pieces) == 2,
		fmt.tprintf("Expected 2 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok = get_span(pt, 0, 11)
	testing.expect(t, ok)
	testing.expect(t, text == "This table.")

	undo(pt)

	testing.expect(t, len(pt.pieces) == 1)

	text, ok = get_span(pt, 0, len(base))
	testing.expect(t, ok)
	testing.expect(t, text == base)
}

@(test)
test_simple_undo_and_redo_handles_updates_correctly :: proc(t: ^testing.T) {
	base := "This a test string for initing the piece table."
	pt, err := init(base)
	testing.expect(t, err == nil)

	text, ok := get_span(pt, 0, len(base))
	testing.expect(t, ok)
	testing.expect(t, text == base)

	remove(pt, 5, len(base) - 5)
	testing.expect(t, pt.pieces[0].length == 5, fmt.tprintf("Expected 5, got %d\n", pt.pieces[0].length))
	testing.expect(
		t,
		len(pt.pieces) == 1,
		fmt.tprintf("Expected 1 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok = get_span(pt, 0, 5)
	testing.expect(t, ok)
	testing.expect(t, text == "This ")

	undo(pt)
	testing.expect(
		t,
		len(pt.pieces) == 1,
		fmt.tprintf("Expected 1 pieces, got %d\n", len(pt.pieces)))
	testing.expect(t, pt.pieces[0].length == len(base), fmt.tprintf("Expected %d, got %d\n", len(base), pt.pieces[0].length))
	text, ok = get_span(pt, 0, len(base))
	testing.expect(t, ok)
	testing.expect(t, text == base)
}

@(test)
test_more_complex_undo_redo :: proc(t: ^testing.T) {
	s1 := "This "
	s2 := "is "
	s3 := "a "
	s4 := "test string "
	s5 := "for initing "
	s6 := "the "
	s7 := "piece table."
	pt, err := init(s1)
	testing.expect(t, err == nil)

	testing.expect(t, insert(pt, s7, len(s1)))
	testing.expect(t, len(pt.pieces) == 2)

	testing.expect(t, insert(pt, s6, len(s1)))
	testing.expect(t, len(pt.pieces) == 3)

	testing.expect(t, insert(pt, s5, len(s1)))
	testing.expect(t, len(pt.pieces) == 4)

	testing.expect(t, insert(pt, s4, len(s1)))
	testing.expect(t, len(pt.pieces) == 5)

	testing.expect(t, insert(pt, s3, len(s1)))
	testing.expect(t, len(pt.pieces) == 6)

	testing.expect(t, insert(pt, s2, len(s1)))
	testing.expect(t, len(pt.pieces) == 7)

	remove(pt, 5, 45)
	testing.expect(
		t,
		len(pt.pieces) == 1,
		fmt.tprintf("Expected 1 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok := get_span(pt, 0, 11)
	testing.expect(t, ok)

	total_undoables := len(pt.undo_list)
	for x := 0; x < total_undoables; x += 1 {
		undo(pt)
	}
	testing.expect(t, len(pt.pieces) == 1)
	testing.expect(t, pt.pieces[0].length == len(s1), fmt.tprintf("Expected %d, got %d\n", len(s1), pt.pieces[0].length))
	text, ok = get_span(pt, 0, len(s1))
	testing.expect(t, ok)

	testing.expect(t, text == s1)

	for x := 0; x < total_undoables - 1; x += 1 {
		redo(pt)
	}
	testing.expect(t, len(pt.pieces) == 7)
	text, ok = get_span(pt, 0, len(s1) + len(s2) + len(s3) + len(s4) + len(s5) + len(s6) + len(s7))
	testing.expect(t, ok)
	testing.expect(t, text == "This is a test string for initing the piece table.")
}

@(test)
test_getting_a_span_longer_than_the_buffer :: proc(t: ^testing.T) {
	base := "This is a test string for initing the piece table."
	pt, err := init(base)
	testing.expect(t, err == nil)

	text, ok := get_span(pt, 0, len(base) + 1)
	testing.expect(t, ok)
	testing.expect(t, text == base)
}

@(test)
test_getting_line_offsets_for_a_line_that_does_not_exist :: proc(t: ^testing.T) {
	base := "This is a test string for initing the piece table."
	pt, err := init(base)
	testing.expect(t, err == nil)

	start, end := get_line_offsets(pt, 100, 1)
	testing.expect(t, start == 0, fmt.tprintf("Expected 0, got %d\n", start))
	testing.expect(t, end == 0, fmt.tprintf("Expected 0, got %d\n", end))
}

@(test)
test_removing_a_span_across_two_pieces_offset_from_the_start_of_the_first_piece :: proc(t: ^testing.T) {
	base := "This is a test string"
	pt, err := init(base)
	testing.expect(t, err == nil)
	testing.expect(t, insert(pt, " for initing the piece table.", len(base)))

	testing.expect(t, remove(pt, 9, 28))
	text, ok := get_span(pt, 0, 100)
	testing.expect(t, ok)
	testing.expect(t, text == "This is a piece table.", fmt.tprintf("Expected 'This is a piece table.', got '%s'\n", text))
}
