package game

World :: struct {
	units : [2]Unit
}

Unit :: struct {
	pos : [3]f32,
	size : [3]f32,
	speed : f32,
	selected : bool,
	radius : f32,
	target_pos : [3]f32,
	has_target : bool
}
