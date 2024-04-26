package main

import "ui"

main :: proc() {
    window, err := ui.init("Bragi - alpha0.0.1", 800, 600)
    if err != nil {
        panic("Failed to create window")
    }

    for !ui.should_exit(window) {
        ui.draw(window)
    }
    ui.destroy(window)
}
