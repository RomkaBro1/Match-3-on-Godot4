extends Node2D

var enemy_list = [
	preload("res://scenes/enemy.tscn")
]

var current_enemy

signal attack_player
signal enemy_negative_hp

func _ready():
	spawn_enemy()
	_on_grid_update_attack_in(5)

func spawn_enemy():
	var enemy = enemy_list[0].instantiate()
	add_child(enemy)
	current_enemy = enemy
	enemy.position = Vector2(850, 535)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_grid_update_attack_in(num):
	current_enemy.get_node("dialogue_container/dialogue/label_text").text = str(num)
	if num == -1:
		emit_signal("attack_player", current_enemy.damage)

func _on_player_grid_attack_enemy(dmg):
	current_enemy.take_damage(dmg)
	print('ataka')
	if current_enemy.health <= 0:
		emit_signal("enemy_negative_hp", current_enemy.health)
