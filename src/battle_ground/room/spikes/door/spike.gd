extends Spike

signal enter_door(rotaion: DoorDirection)
enum DoorDirection {
	LEFT,
	RIGHT,
	UP,
	DOWN
}
@export var direction: DoorDirection = DoorDirection.RIGHT # 门的方向
@export var door_pos: Vector2i = Vector2i.ZERO # 门的位置
@export var closed_door_tile: Vector2i = Vector2i(4, 0) # 门所在的Tile
@export var open_door_tile: Vector2i = Vector2i(4, 1) # 开门后的Tile
@export var room_tilelayer: TileMapLayer

var open: bool = false: # 门是否打开
	set(value):
		open = value
		setup_door()


func _ready() -> void:
	super._ready()
	_setup_position()
	setup_door()
	visibility_changed.connect(setup_door)


func setup_door() -> void:
	if not visible:
		return
	var aid: int = 0
	if direction == DoorDirection.LEFT:
		aid = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V
	elif direction == DoorDirection.RIGHT:
		aid = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
	elif direction == DoorDirection.DOWN:
		aid = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
	elif direction == DoorDirection.UP:
		pass

	var door_tile: Vector2i = closed_door_tile if not open else open_door_tile
	room_tilelayer.set_cell(door_pos, 0, door_tile, aid)

	
func _setup_position() -> void:
	# 获取 tilemaplayer 中门所在的绝对坐标，并将该节点移动到该位置
	if room_tilelayer == null:
		return
	var world_pos: Vector2 = room_tilelayer.map_to_local(door_pos)
	position = world_pos


func activate(player: Node2D) -> void:
	if not open:
		return
	enter_door.emit(direction)
