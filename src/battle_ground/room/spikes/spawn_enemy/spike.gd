extends Spike

enum EnemyType {
近战普通,
近战Boss,
}

@export var enemy_diction: Dictionary[EnemyType,PackedScene] = {
EnemyType.近战普通: preload("res://src/entities/enemies/types/melee/melee.tscn"),
EnemyType.近战Boss: preload("res://src/entities/enemies/types/melee/melee_boss.tscn"),
}

@export var type: EnemyType = EnemyType.近战普通 # 默认敌人类型
@export var level: int = 1 # 默认敌人等级
@export var entries: Array[String] = [] # 默认词条列表


func activate(_n: Node2D) -> void:
	var enemy_scene: PackedScene = enemy_diction.get(type, null)
	if not enemy_scene:
		return
	var enemy: EnemyBase = enemy_scene.instantiate()
	enemy.level = level
	enemy.entries = entries
	get_parent().add_child(enemy)
	enemy.global_position = global_position
	
	
