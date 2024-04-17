package piece_table

import "core:fmt"

ChangeEvent :: enum {
    Insert,
    Delete,
    Update,
}

Change :: struct {
    event: ChangeEvent,
    piece: Piece,
    position: int,
}

ChangeSet :: #type [dynamic]Change

/*
  Initialize a change set to store all changes made to the piece table during a single operation.

  Input: A pointer to the piece table.
*/
init_change_set :: proc(table: ^PieceTable) {
    table.current_change_set = make(ChangeSet)
}

/*
  Add all the recorded changes to the undo list.  Also clears the current change set.

  Input: A pointer to the piece table
*/
record_change_set :: proc(table: ^PieceTable) {
    append(&table.undo_list, table.current_change_set)
    clear(&table.current_change_set)
}

/*
  Undo the last operation on the piece table

  Input: A pointer to the piece table
*/
undo :: proc(table: ^PieceTable) {
    if len(table.undo_list) > 0 {
        change_set := pop(&table.undo_list)
        rewind_changes(table, change_set[:])
        append(&table.redo_list, change_set)
    }
}

/*
  Redo the last operation that was undone

  Input: A pointer to the piece table
*/
redo :: proc(table: ^PieceTable) {
    if len(table.redo_list) > 0 {
        change_set := pop(&table.redo_list)
        replay_changes(table, change_set[:])
        append(&table.undo_list, change_set)
    }
}

/*
  Iterate through the change set and apply the changes to the piece table in reverse order.

  Input: A pointer to the piece table, a set of changes
*/
rewind_changes :: proc(pt: ^PieceTable, change_set: []Change) {
    assert(pt != nil)
    #reverse for change in change_set {
        switch change.event {
        case .Insert:
            ordered_remove(&pt.pieces, change.position)
        case .Delete:
            inject_at(&pt.pieces, change.position, change.piece)
        case .Update:
            pt.pieces[change.position] = change.piece
        }
    }
}

/*
  Iterate through the change set and apply the changes to the piece table in order.

  Input: A pointer to the piece table, a set of changes
*/
replay_changes :: proc(pt: ^PieceTable, change_set: []Change) {
    assert(pt != nil)
    for change in change_set {
        switch change.event {
        case .Insert:
            inject_at(&pt.pieces, change.position, change.piece)
        case .Delete:
            ordered_remove(&pt.pieces, change.position)
        case .Update:
            pt.pieces[change.position] = change.piece
        }
    }
}
