package input

import "../game"
import "vendor:raylib"
import "core:math"

Input :: struct {
	is_dragging    : bool,
	drag_start_pos : [2]f32, // screen space
	drag_end_pos   : [2]f32, // screen space
}

dist2_screen :: proc(a, b: [2]f32) -> f32 {
	dx := a[0] - b[0]
	dy := a[1] - b[1]
	return dx*dx + dy*dy
}

point_in_rect :: proc(p: raylib.Vector2, min_x, min_y, max_x, max_y: f32) -> bool {
	return p.x >= min_x && p.x <= max_x && p.y >= min_y && p.y <= max_y
}

update_input :: proc (world : ^game.World, ray : raylib.Ray, mouse_pos : [2]f32, input : ^Input, cam: raylib.Camera3D) {

	right_click_pressed : bool = raylib.IsMouseButtonPressed(.RIGHT)

	left_click_pressed : bool = raylib.IsMouseButtonPressed(.LEFT)
	left_click_down    : bool = raylib.IsMouseButtonDown(.LEFT)
	left_click_release : bool = raylib.IsMouseButtonReleased(.LEFT)

	hit : raylib.RayCollision
	if right_click_pressed {
		ground_y : f32 = -0.5
		half     : f32 = 50.0

		p1 := raylib.Vector3{-half, ground_y, -half}
		p2 := raylib.Vector3{ half, ground_y, -half}
		p3 := raylib.Vector3{ half, ground_y,  half}
		p4 := raylib.Vector3{-half, ground_y,  half}

		hit = raylib.GetRayCollisionQuad(ray, p1, p2, p3, p4)
	}

	// --- Drag state ---
	drag_threshold_px : f32 = 6.0
	drag_threshold2   : f32 = drag_threshold_px * drag_threshold_px

	if left_click_pressed {
		input.drag_start_pos = mouse_pos
		input.drag_end_pos   = mouse_pos
		input.is_dragging    = false
	}

	if left_click_down {
		input.drag_end_pos = mouse_pos

		if !input.is_dragging {
			if dist2_screen(input.drag_start_pos, input.drag_end_pos) > drag_threshold2 {
				input.is_dragging = true
			}
		}
	}

	// --- On release: click OR drag (mutually exclusive) ---
	if left_click_release {
		if input.is_dragging {
			// Build normalized screen-rect
			x1 := input.drag_start_pos[0]
			y1 := input.drag_start_pos[1]
			x2 := input.drag_end_pos[0]
			y2 := input.drag_end_pos[1]

			min_x := math.min(x1, x2)
			min_y := math.min(y1, y2)
			max_x := math.max(x1, x2)
			max_y := math.max(y1, y2)

			// Box select: project each unit to screen, test in rect
			for &u in world.units {
				wp := raylib.Vector3{u.pos.x, u.pos.y, u.pos.z}
				sp := raylib.GetWorldToScreen(wp, cam) // screen-space Vector2

				u.selected = point_in_rect(sp, min_x, min_y, max_x, max_y)
			}
		} else {
			// Click selection (ray pick) - run ONCE here
			for &u in world.units {
				collision := raylib.GetRayCollisionBox(
					ray,
					{{
						u.pos.x - u.size.x / 2,
						u.pos.y - u.size.y / 2,
						u.pos.z - u.size.z / 2,
					},
					{
						u.pos.x + u.size.x / 2,
						u.pos.y + u.size.y / 2,
						u.pos.z + u.size.z / 2,
					}}
				)

				if collision.hit {
					u.selected = true
				} else {
					u.selected = false
				}
			}
		}

		input.is_dragging = false
	}

	// --- Right click commands ---
	if hit.hit {
		for &u in world.units {
			if u.selected {
				u.has_target = true
				u.target_pos = hit.point
			}
		}
	}
}
