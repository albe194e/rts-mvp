package simulation

import "../game"
import "vendor:raylib"

update :: proc (world : ^game.World, dt : f32) {

	for &u in world.units {
		id := u.id;
		tf := game.get_transform(world, id);

		if u.has_target {
			dir := u.target_pos - tf.pos;
			dir.y = 0;

			distance := raylib.Vector3Distance(tf.pos, u.target_pos)

			if distance < 0.1 {
				u.has_target = false;
			} else {
				dir = raylib.Vector3Normalize(dir);

				move_amount := dir * (u.speed * dt);
				tf.pos += move_amount;
			}
		}
	}
}