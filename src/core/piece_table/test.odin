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
test_deleting_a_span_at_that_spans_multiple_pieces_but_ends_in_the_middle_of_the_final_piece :: proc(t: ^testing.T) {
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
	fmt.println(text)
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
	fmt.printf("start: %d, length: %d\n", start, length)
	text, ok := get_span(pt, start, length)
	fmt.println(text)
	testing.expect(t, ok)
	testing.expect(t, text == "Line one and a half\n")
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
