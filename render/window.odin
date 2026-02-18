package render

Window :: struct {
	title : string,

	screen_height, screen_width : i32
}

init_window :: proc (win : ^Window) {
	win.title = "RTS - MVP"
	win.screen_height = 1000
	win.screen_width = 1200
}
