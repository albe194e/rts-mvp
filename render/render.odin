package render

import "vendor:raylib"
import "../game"
import i "../input"
import "core:math"

Renderer :: struct {
	camera : Camera
}

Camera :: struct {
	c : raylib.Camera3D,
	sensitivity : f32,
}

init :: proc(r : ^Renderer) {
	raylib.InitWindow(1200, 900, "RTS")
	raylib.SetTargetFPS(60)

	r.camera.c.position = { 0, 10, 10 }
	r.camera.c.target = { 0, 0, 0 }
	r.camera.c.up = { 0, 1, 0 }
	r.camera.c.fovy = 45
	r.camera.c.projection = .PERSPECTIVE
	r.camera.sensitivity = 5
}

begin_frame :: proc() {
	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.RAYWHITE)
}

begin_drawing :: proc(world: ^game.World, r : ^Renderer, input : ^i.Input) {
	// --- 3D world ---
	raylib.BeginMode3D(r.camera.c)
	raylib.DrawGrid(100, 1)
	raylib.DrawPlane({0,-0.5,0}, {100, 100}, {102, 137, 116, 255})

	// Unit draw
	for u in world.units {
		pos := raylib.Vector3{u.pos.x, u.pos.y, u.pos.z}
		color := raylib.Color{255, 0, 255, 255}

		if u.selected {
			color = {0, 0, 0, 255}
		}
		raylib.DrawCube(pos, u.size.x, u.size.y, u.size.z, color)
	}

	raylib.EndMode3D()

	if input.is_dragging {
		x1 := input.drag_start_pos.x
		y1 := input.drag_start_pos.y
		x2 := input.drag_end_pos.x
		y2 := input.drag_end_pos.y

		min_x := math.min(x1, x2)
		min_y := math.min(y1, y2)
		max_x := math.max(x1, x2)
		max_y := math.max(y1, y2)

		pos := raylib.Vector2{min_x, min_y}
		size := raylib.Vector2{max_x - min_x, max_y - min_y}

		// filled + outline (optional but feels RTS-y)
		raylib.DrawRectangleV(pos, size, raylib.Color{100, 255, 100, 80})
		raylib.DrawRectangleLines(
			cast(i32)min_x, cast(i32)min_y,
			cast(i32)(max_x - min_x), cast(i32)(max_y - min_y),
			raylib.Color{50, 180, 50, 255},
		)
	}
}

end_frame :: proc() {
	raylib.EndDrawing()
}

shutdown :: proc() {
	raylib.CloseWindow()
}

update_camera :: proc(r : ^Renderer, dt : f32) {
	edge_threshold : i32 = 10

	mouse_pos := raylib.GetMousePosition()

	screen_size_x := raylib.GetScreenWidth()
	screen_size_y := raylib.GetScreenHeight()

	movement := raylib.Vector3{ 0, 0, 0 }

	// X Axis
	if cast(i32)mouse_pos.x < edge_threshold {
		movement.x -= 1
	}
	if cast(i32)mouse_pos.x > screen_size_x - edge_threshold {
		movement.x += 1
	}

	// Y Axis
	if cast(i32)mouse_pos.y < edge_threshold {
		movement.z -= 1
	}
	if cast(i32)mouse_pos.y > screen_size_y - edge_threshold {
		movement.z += 1
	}

	actual_movement := movement * (r.camera.sensitivity * dt)

	r.camera.c.position += actual_movement
	r.camera.c.target += actual_movement
}
