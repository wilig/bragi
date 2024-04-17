package font

import "core:os"
import "core:math"

import gl "vendor:OpenGL"
import stbtt "vendor:stb/truetype"

Character :: struct {
    texture_offset: [2]f32,
    texture_size: [2]f32,
    size: [2]i32,
    bearing: [2]f32,
}

Font :: struct {
    data: stbtt.fontinfo,
    size: i32,
    texture_atlas: u32,
    base_color: [3]f32,
    characters: map[rune]Character,
    cursor_size: [2]f32,
    line_height: f32,
    max_glyph_height: i32,
    max_glyph_width: i32,
}

// Builds a character atlas for the specified font at the specified size.
// OpenGL must be initialized before fonts can be initialized.
//
// path: The path to the font file
// size: The size of the font
// Returns: The font and an error message
init_font :: proc(path: string, size: i32) -> (font: Font, err: string) {
    font_data, ok := os.read_entire_file(path)
    if !ok {
        return Font{}, "Failed to read font file"
    }

    if !stbtt.InitFont(&font.data, raw_data(font_data), size) {
        return Font{}, "Failed to initialize font"
    }

    font.size = size
    atlas_width : i32 = 1024
    atlas_height : i32 = 1024

    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
    gl.GenTextures(1, &font.texture_atlas)
    gl.BindTexture(gl.TEXTURE_2D, font.texture_atlas)
    // Initialize to all zeros
    buffer := make([]u8, atlas_width * atlas_height * 4) // RGBA
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, atlas_width, atlas_height, 0, gl.RED, gl.UNSIGNED_BYTE, raw_data(buffer))
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    scale := stbtt.ScaleForPixelHeight(&font.data, f32(font.size))
    x : i32 = 0
    y : i32 = 0
    font.max_glyph_height = 0
    font.max_glyph_width = 0

    ascent, descent, line_gap : i32
    stbtt.GetFontVMetrics(&font.data, &ascent, &descent, &line_gap)
    font.line_height = math.round(f32(ascent - descent + line_gap) * scale)

    // Find the max width of all the glyphs
    for r in 0..=128 {
        advance_width, left_bearing : i32
        stbtt.GetCodepointHMetrics(&font.data, rune(r), &advance_width, &left_bearing)
        if f32(advance_width) * scale > f32(font.max_glyph_width) {
            font.max_glyph_width = i32(f32(advance_width) * scale)
        }
    }

    for r in 0..=128 {
        width, height, xoff, yoff : i32
        bitmap := stbtt.GetCodepointBitmap(&font.data, scale, scale, rune(r), &width, &height, &xoff, &yoff)
        defer stbtt.FreeBitmap(bitmap, nil)
        if x + width >= atlas_width {
            x = 0
            y += font.max_glyph_height// + 1
            font.max_glyph_height = 0
        }

        gl.TexSubImage2D(gl.TEXTURE_2D, 0, x, y, width, height, gl.RED, gl.UNSIGNED_BYTE, bitmap)

        character := Character{
            texture_offset = {f32(x) / f32(atlas_width), f32(y) / f32(atlas_height)},
            texture_size = {f32(width) / f32(atlas_width), f32(height) / f32(atlas_height)},
            size = {width, height},
            bearing = {f32((font.max_glyph_width - width) / 2.0), f32(yoff)},
        }
        font.characters[rune(r)] = character

        x += font.max_glyph_width
        font.max_glyph_height = max(font.max_glyph_height, height)
    }

    gl.BindTexture(gl.TEXTURE_2D, 0)
    return
}
