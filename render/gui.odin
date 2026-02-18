package render

import "../game"
import clay "../ext_libraries/clay/bindings/odin/clay-odin"
import "core:c"
import "vendor:raylib"

Raylib_Font :: struct {
    fontId: u16,
    font:   raylib.Font,
}

raylib_fonts := [dynamic]Raylib_Font{}

init_gui :: proc (world : ^game.World) {
	minMemorySize: c.size_t = cast(c.size_t)clay.MinMemorySize()
	memory := make([^]u8, minMemorySize)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(minMemorySize, memory)
	clay.Initialize(arena, {cast(f32)raylib.GetScreenWidth(), cast(f32)raylib.GetScreenHeight()}, { handler = errorHandler })
	clay.SetMeasureTextFunction(measure_text, nil)
}

update_gui :: proc(world : ^game.World) {

}

// Clay functions needed to make it work
errorHandler :: proc "c" (errorData: clay.ErrorData) {
    if (errorData.errorType == clay.ErrorType.DuplicateId) {
        // etc
    }
}

measure_text :: measure_text_ascii
measure_text_ascii :: proc "c" (text: clay.StringSlice, config: ^clay.TextElementConfig, userData: rawptr) -> clay.Dimensions {    
	line_width: f32 = 0
    
	font := raylib_fonts[config.fontId].font
	text_str := string(text.chars[:text.length])

	for i in 0..<len(text_str) {
		glyph_index := text_str[i] - 32

        glyph := font.glyphs[glyph_index]

		if glyph.advanceX != 0 {
			line_width += f32(glyph.advanceX)
		} else {
			line_width += font.recs[glyph_index].width + f32(font.glyphs[glyph_index].offsetX)
		}
	}

	scaleFactor := f32(config.fontSize) / f32(font.baseSize)

    // Note: 
    //   I'd expect this to be `len(text_str) - 1`, 
    //   but that seems to be one letterSpacing too small
    //   maybe that's a raylib bug, maybe that's Clay?
	total_spacing := f32(len(text_str)) * f32(config.letterSpacing)

	return {width = line_width * scaleFactor + total_spacing, height = f32(config.fontSize)}
}

