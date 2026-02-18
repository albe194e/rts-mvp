package game

EntityId :: distinct u32
INVALID_INDEX : i32 : -1

World :: struct {
	// Entity id management
	next_id : EntityId,
	free    : [dynamic]EntityId,

	// Dense component storage
	transforms  : [dynamic]Transform,
	selectables : [dynamic]Selectable,
	units       : [dynamic]Unit,
	buildings   : [dynamic]Building,

	transform_index  : [dynamic]i32,
	selectable_index : [dynamic]i32,
	unit_index       : [dynamic]i32,
	building_index   : [dynamic]i32,

	players : [dynamic]Player,

	gui : Gui,
}

Unit :: struct {
	id         : EntityId,
	speed      : f32,
	target_pos : [3]f32,
	has_target : bool,
	type       : UnitType,
	playerId   : PlayerId,
}

Building :: struct {
	id        : EntityId,
	type      : BuildingType,
	footprint : [2]f32,
	playerId  : PlayerId,
}

Transform :: struct {
	id  : EntityId,
	pos : [3]f32,
	size : [3]f32
}

Selectable :: struct {
	id       : EntityId,
	selected : bool,
	radius   : f32,
}

init_world :: proc(w: ^World, ) {
	w.next_id = EntityId(0)
	initial_entity_capacity := 0

	// Clear dense arrays
	w.free = nil
	w.transforms = nil
	w.selectables = nil
	w.units = nil
	w.buildings = nil

	// Clear index arrays
	w.transform_index = nil
	w.selectable_index = nil
	w.unit_index = nil
	w.building_index = nil

	if initial_entity_capacity < 0 {
		initial_entity_capacity = 0
	}

	if initial_entity_capacity > 0 {
		// resize sets len (and zero-fills), then we overwrite with INVALID_INDEX
		resize(&w.transform_index,  initial_entity_capacity)
		resize(&w.selectable_index, initial_entity_capacity)
		resize(&w.unit_index,       initial_entity_capacity)
		resize(&w.building_index,   initial_entity_capacity)

		for i in 0..<initial_entity_capacity {
			w.transform_index[i]  = INVALID_INDEX
			w.selectable_index[i] = INVALID_INDEX
			w.unit_index[i]       = INVALID_INDEX
			w.building_index[i]   = INVALID_INDEX
		}
	}
}

ensure_entity_capacity :: proc(w: ^World, id: EntityId) {
	need := int(id) + 1
	if need <= len(w.transform_index) {
		return
	}

	old := len(w.transform_index)

	// Grow length to at least need (doubling strategy)
	new_len := old
	if new_len < 1 {
		new_len = 1
	}
	for new_len < need {
		new_len *= 2
	}

	// Resize all index arrays to new_len
	resize(&w.transform_index,  new_len)
	resize(&w.selectable_index, new_len)
	resize(&w.unit_index,       new_len)
	resize(&w.building_index,   new_len)

	// Fill ONLY the new region with INVALID_INDEX (because resize zero-fills)
	for i in old..<new_len {
		w.transform_index[i]  = INVALID_INDEX
		w.selectable_index[i] = INVALID_INDEX
		w.unit_index[i]       = INVALID_INDEX
		w.building_index[i]   = INVALID_INDEX
	}
}

// ------------------------------------------------------------
// Entity creation / destruction
// ------------------------------------------------------------

create_entity :: proc(w: ^World) -> EntityId {
	// reuse id if available
	if len(w.free) > 0 {
		return pop(&w.free)
	}

	id := w.next_id
	w.next_id = EntityId(u32(w.next_id) + 1)
	ensure_entity_capacity(w, id)
	return id
}

destroy_entity :: proc(w: ^World, id: EntityId) {
	remove_unit(w, id)
	remove_building(w, id)
	remove_selectable(w, id)
	remove_transform(w, id)

	// recycle id (optional)
	append_elem(&w.free, id)
}

// ------------------------------------------------------------
// Has / Get helpers
// NOTE: Call has_* before get_* if you're not sure the component exists.
// ------------------------------------------------------------

has_transform :: proc(w: ^World, id: EntityId) -> bool {
	return w.transform_index[int(id)] != INVALID_INDEX
}
get_transform :: proc(w: ^World, id: EntityId) -> ^Transform {
	return &w.transforms[w.transform_index[int(id)]]
}

has_selectable :: proc(w: ^World, id: EntityId) -> bool {
	return w.selectable_index[int(id)] != INVALID_INDEX
}
get_selectable :: proc(w: ^World, id: EntityId) -> ^Selectable {
	return &w.selectables[w.selectable_index[int(id)]]
}

has_unit :: proc(w: ^World, id: EntityId) -> bool {
	return w.unit_index[int(id)] != INVALID_INDEX
}
get_unit :: proc(w: ^World, id: EntityId) -> ^Unit {
	return &w.units[w.unit_index[int(id)]]
}

has_building :: proc(w: ^World, id: EntityId) -> bool {
	return w.building_index[int(id)] != INVALID_INDEX
}
get_building :: proc(w: ^World, id: EntityId) -> ^Building {
	return &w.buildings[w.building_index[int(id)]]
}

// ------------------------------------------------------------
// Add component (assumes not already present)
// ------------------------------------------------------------

add_transform :: proc(w: ^World, id: EntityId, pos: [3]f32) {
	ensure_entity_capacity(w, id)
	idx := i32(len(w.transforms))
	append_elem(&w.transforms, Transform{id=id, pos=pos, size={1,1,1}}) // TODO either remove size or add it to method.
	w.transform_index[int(id)] = idx
}

add_selectable :: proc(w: ^World, id: EntityId, radius: f32) {
	ensure_entity_capacity(w, id)
	idx := i32(len(w.selectables))
	append_elem(&w.selectables, Selectable{id=id, selected=false, radius=radius})
	w.selectable_index[int(id)] = idx
}

add_unit :: proc(w: ^World, id: EntityId, t: UnitType, speed: f32, playerId: PlayerId) {
	ensure_entity_capacity(w, id)
	idx := i32(len(w.units))
	append_elem(&w.units, Unit{
		id = id,
		type = t,
		speed = speed,
		target_pos = {0, 0, 0},
		has_target = false,
		playerId = playerId
	})
	w.unit_index[int(id)] = idx
}

add_building :: proc(w: ^World, id: EntityId, t: BuildingType, footprint: [2]f32, playerId: PlayerId) {
	ensure_entity_capacity(w, id)
	idx := i32(len(w.buildings))
	append_elem(&w.buildings, Building{
		id=id, 
		type=t, 
		footprint=footprint,
	playerId = playerId})
	w.building_index[int(id)] = idx
}

// ------------------------------------------------------------
// Remove component (swap-remove keeps dense arrays packed)
// IMPORTANT: update swapped entity's index!
// NOTE: unordered_remove does the swap+shrink; we only need to fix indices.
// ------------------------------------------------------------

remove_transform :: proc(w: ^World, id: EntityId) {
	i := w.transform_index[int(id)]
	if i == INVALID_INDEX { return }

	last := i32(len(w.transforms) - 1)
	if i != last {
		// The last element will get swapped into i by unordered_remove.
		// Capture its entity id NOW (before it moves).
		swapped_id := w.transforms[last].id
		w.transform_index[int(swapped_id)] = i
	}

	unordered_remove(&w.transforms, int(i))
	w.transform_index[int(id)] = INVALID_INDEX
}

remove_selectable :: proc(w: ^World, id: EntityId) {
	i := w.selectable_index[int(id)]
	if i == INVALID_INDEX { return }

	last := i32(len(w.selectables) - 1)
	if i != last {
		swapped_id := w.selectables[last].id
		w.selectable_index[int(swapped_id)] = i
	}

	unordered_remove(&w.selectables, int(i))
	w.selectable_index[int(id)] = INVALID_INDEX
}

remove_unit :: proc(w: ^World, id: EntityId) {
	i := w.unit_index[int(id)]
	if i == INVALID_INDEX { return }

	last := i32(len(w.units) - 1)
	if i != last {
		swapped_id := w.units[last].id
		w.unit_index[int(swapped_id)] = i
	}

	unordered_remove(&w.units, int(i))
	w.unit_index[int(id)] = INVALID_INDEX
}

remove_building :: proc(w: ^World, id: EntityId) {
	i := w.building_index[int(id)]
	if i == INVALID_INDEX { return }

	last := i32(len(w.buildings) - 1)
	if i != last {
		swapped_id := w.buildings[last].id
		w.building_index[int(swapped_id)] = i
	}

	unordered_remove(&w.buildings, int(i))
	w.building_index[int(id)] = INVALID_INDEX
}

// ------------------------------------------------------------
// Spawn helpers
// ------------------------------------------------------------

spawn_unit :: proc(w: ^World, 
									 pos: [3]f32, 
									 radius: f32, 
									 t: UnitType, 
									 speed: f32,
									 playerId: PlayerId) -> EntityId {
	id := create_entity(w)
	add_transform(w, id, pos)
	add_selectable(w, id, radius)
	add_unit(w, id, t, speed, playerId)
	return id
}

spawn_building :: proc(w: ^World, 
											 pos: [3]f32, 
											 radius: f32, 
											 t: BuildingType, 
											 footprint: [2]f32, 
											 playerId: PlayerId) -> EntityId {
	id := create_entity(w)
	add_transform(w, id, pos)
	add_selectable(w, id, radius)
	add_building(w, id, t, footprint, playerId)
	return id
}
