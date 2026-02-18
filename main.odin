package main

import "vendor:raylib"
import "render"
import "game"
import i "input"
import "simulation"
import "core:fmt"


main :: proc() {

	r : render.Renderer
	render.init(&r)
	defer render.shutdown()

	world : game.World;
	game.init_world(&world);

	hardcode_entities(&world)

	input : i.Input

	for !raylib.WindowShouldClose() {

		dt := raylib.GetFrameTime();
		mouse_pos := raylib.GetMousePosition();
		ray := raylib.GetScreenToWorldRay(mouse_pos, r.camera.c)

		i.update_input(&world, ray, mouse_pos, &input, r.camera.c)
		simulation.update(&world, dt)

		render.update_camera(&r, dt)

		render.begin_frame()
			render.begin_drawing(&world, &r, &input)


		render.end_frame()
	}
}


hardcode_entities :: proc (w : ^game.World) {

	append(&w.players, game.Player{
		id = 1
	})
	append(&w.players, game.Player{
		id = 2
	})

	// Player 1
	game.spawn_unit(
		w,
		{2,0,0},
		1,
		.WORKER,
		1,
		game.this_player_id
	)

	game.spawn_building(
		w,
		{2, 0, 2},
		1,
		.CITY,
		{2,2},
		game.this_player_id
	)

	// Player 2
	game.spawn_unit(
		w,
		{-2,0,0},
		1,
		.WORKER,
		1,
		2
	)

	game.spawn_building(
		w,
		{-2, 0, 2},
		1,
		.CITY,
		{2,2},
		2
	)
}
