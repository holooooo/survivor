extends Node


signal on_equip(player: Player, equipment: EquipmentBase)
signal on_equipment_used(player: Player, equipment: EquipmentBase)
signal on_equipment_cooldown_start(player: Player, equipment: EquipmentBase, last_use_time: float, cooldown_time: float)

signal on_projectile_spawn(player: Player, equipment: EquipmentBase, projectile: ProjectileBase)
signal on_projectile_hit(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType)
signal on_projectile_destroy(player: Player, equipment: EquipmentBase, projectile: ProjectileBase)
signal on_projectile_kill(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType)

# 命中效果相关信号
signal on_hit_effect_triggered(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, effect_name: String)
signal on_knockback_applied(target: Node, direction: Vector2, strength: float)
signal on_explosion_triggered(position: Vector2, radius: float, damage: int)
signal on_projectile_split(original_projectile: ProjectileBase, split_projectiles: Array)
signal on_projectile_ricochet(projectile: ProjectileBase, old_target: Node, new_target: Node)

