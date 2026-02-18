package render

import "../game"
import clay "../ext_libraries/clay/bindings/odin/clay-odin"
import "core:c"
import "vendor:raylib"
import "core:math"

Raylib_Font :: struct {
    fontId: u16,
    font:   raylib.Font,
}

raylib_fonts := [dynamic]Raylib_Font{}

init_gui :: proc () {
	minMemorySize: c.size_t = cast(c.size_t)clay.MinMemorySize()
	memory := make([^]u8, minMemorySize)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(minMemorySize, memory)
	clay.Initialize(arena, {cast(f32)raylib.GetScreenWidth(), cast(f32)raylib.GetScreenHeight()}, { handler = errorHandler })
	clay.SetMeasureTextFunction(measure_text, nil)
}

update_gui :: proc() {
	clay.SetPointerState(transmute(clay.Vector2)raylib.GetMousePosition(), raylib.IsMouseButtonDown(raylib.MouseButton.LEFT)) // TODO:  Get from params
	clay.UpdateScrollContainers(false, transmute(clay.Vector2)raylib.GetMouseWheelMoveV(), raylib.GetFrameTime())
	clay.SetLayoutDimensions({cast(f32)raylib.GetScreenWidth(), cast(f32)raylib.GetScreenHeight()})

	commands := createLayout()

	render_gui(&commands)
}

render_gui :: proc(cmds: ^clay.ClayArray(clay.RenderCommand)) {
	for i in 0 ..< cmds.length {
		render_command := clay.RenderCommandArray_Get(cmds, i)
		bounds := render_command.boundingBox

		#partial switch render_command.commandType {
			case .Rectangle:
				raylib.DrawRectangle(
					i32(math.round(bounds.x)), i32(math.round(bounds.y)), i32(math.round(bounds.width)), i32(math.round(bounds.height)),
					{0, 0, 0, 255}
				)
			case:
				panic("Render command not implemented yet")
		}
	}
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

createLayout :: proc() -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI(clay.ID("OuterContainer"))({
        layout = { layoutDirection = .TopToBottom, sizing = { clay.SizingFixed(300), clay.SizingFixed(200) } },
        backgroundColor = {255, 0, 0, 255},
    }) {

		}

	return clay.EndLayout()
}