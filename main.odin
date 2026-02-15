package main

import "vendor:raylib"
import "render"
import "game"
import i "input"
import "simulation"
main :: proc() {

	r : render.Renderer
	render.init(&r)
	defer render.shutdown()

	world : game.World
	world.units[0] = game.Unit{
		pos = {0, 0, 0},
		radius = 1,
		size = {1, 1, 1},
		speed = 1,
	}

	world.units[1] = game.Unit{
		pos = {2, 0, 2},
		radius = 1,
		size = {1, 1, 1},
		speed = 1,
	}

	input : i.Input
	

	for !raylib.WindowShouldClose() {

		dt := raylib.GetFrameTime();
		mouse_pos := raylib.GetMousePosition();
		ray := raylib.GetScreenToWorldRay(mouse_pos, r.camera.c)

		
		i.update_input(&world, ray, mouse_pos, &input, r.camera.c)
		simulation.update(&world, dt)

		render.update_camera(&r, dt)

		// --- UPDATE (simulation goes here) ---
		// sim_update(world)

		// --- RENDER ---
		render.begin_frame()
			render.begin_drawing(&world, &r, &input)


		render.end_frame()
	}
}
