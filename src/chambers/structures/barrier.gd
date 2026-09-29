@tool
class_name Barrier
extends StaticBody2D


@export var tile_set: TileSet:
	set(value):
		tile_set = value
		_refresh()
@export var source_id: int = 0:
	set(value):
		source_id = value
		_refresh()
@export var atlas_coords: Vector2i = Vector2i(1, 11):
	set(value):
		atlas_coords = value
		_refresh()
@export var size_in_tiles: Vector2i = Vector2i(1, 3):
	set(value):
		size_in_tiles = value
		_refresh()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 0
	set_collision_layer_value(_get_barrier_layer(), true)
	collision_mask = 0
	_refresh()


func _get_barrier_layer() -> int:
	return 1 


func _draw() -> void:
	if tile_set == null:
		return
	var source := tile_set.get_source(source_id) as TileSetAtlasSource
	if source == null:
		return
	var tile_size := Vector2(tile_set.tile_size)
	var region := source.get_tile_texture_region(atlas_coords)
	for x in size_in_tiles.x:
		for y in size_in_tiles.y:
			draw_texture_rect_region(source.texture, Rect2(Vector2(x, y) * tile_size, tile_size), region)


func _refresh() -> void:
	if not is_node_ready() or tile_set == null:
		return
	var size := Vector2(size_in_tiles) * Vector2(tile_set.tile_size)
	var rect := collision_shape.shape as RectangleShape2D
	if rect != null:
		rect.size = size
		collision_shape.position = size / 2.0
	queue_redraw()
