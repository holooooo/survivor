extends Node2D
class_name Room

signal door_entered(rotation: DoorSpike.DoorDirection)

const DoorSpike = preload("res://src/battle_ground/room/spikes/door/spike.gd")
var doors: Dictionary[DoorSpike.DoorDirection,DoorSpike]

@export var doors_config: Array[DoorSpike.DoorDirection]



func _ready() -> void:
	var door_nodes: Array[Node] = get_tree().get_nodes_in_group("door")
	for door_node in door_nodes:
		if door_node is DoorSpike:
			doors[door_node.direction] = door_node
			door_node.enter_door.connect(_on_door_entered)
	for direction in doors_config:
		if  direction in doors:
			doors[direction].visible = true
			doors[direction].open = true
			doors[direction].on_player_entered = true
			
			
		
func _on_door_entered(direction: DoorSpike.DoorDirection) -> void:
	door_entered.emit(direction)
