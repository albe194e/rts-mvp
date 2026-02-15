package simulation

import "../game"
import "vendor:raylib"

update :: proc (world : ^game.World, dt : f32) {

	for &u in world.units {
		if u.has_target {
			dir := u.target_pos - u.pos;
			dir.y = 0;

			distance := raylib.Vector3Distance(u.pos, u.target_pos)

			if distance < 0.1 {
				u.has_target = false;
			} else {
				dir = raylib.Vector3Normalize(dir);

				move_amount := dir * (u.speed * dt);
				u.pos += move_amount;
			}
		}
	}
}