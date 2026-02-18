package game

PlayerId :: distinct u8
this_player_id : PlayerId : 1;

Player :: struct {
	id : PlayerId,
}