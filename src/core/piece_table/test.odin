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
	insertable :: " DELETE ME "
	pt, err := init(base)
	testing.expect(t, err == nil)
	testing.expect(t, insert(pt, insertable, 7))
	testing.expect(t, insert(pt, insertable, 7))
	testing.expect(t, insert(pt, insertable, 7))
	testing.expect(t, remove(pt, 7, len(insertable) * 3))
	fmt.println(pt.pieces)
	testing.expect(
		t,
		len(pt.pieces) == 1,
		fmt.tprintf("Expected 1 pieces, got %d\n", len(pt.pieces)),
	)
	text, ok := get_span(pt, 0, len(base))
	testing.expect(t, ok)
	testing.expect(t, text == base, fmt.tprintf("Expected '%s', but got '%s'\n", base, text))
}
