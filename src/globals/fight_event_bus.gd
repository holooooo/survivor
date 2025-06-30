extends Node


signal on_equip(player: Player, equipment: EquipmentBase)
signal on_equipment_used(player: Player, equipment: EquipmentBase)
signal on_equipment_cooldown_start(player: Player, equipment: EquipmentBase, last_use_time: float, cooldown_time: float)

signal on_projectile_spawn(player: Player, equipment: EquipmentBase, projectile: ProjectileBase)
signal on_projectile_hit(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType)
signal on_projectile_destroy(player: Player, equipment: EquipmentBase, projectile: ProjectileBase)
signal on_projectile_kill(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType)

