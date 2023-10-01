extends Node2D

signal attack_enemy
signal change_move
signal stone_defend
signal player_negative_hp

enum {wait, move}
var player_scene = preload("res://scenes/player.tscn")
var current_player
var can_use_spells
var concrete_stones_rn = 0

func _ready():
	spawn_player()
	$MarginContainer/ScrollContainer/spells_container/spell_fireball.disabled = true
	$MarginContainer/ScrollContainer/spells_container/spell_stonedefend.disabled = true

func spawn_player():
	var play = player_scene.instantiate()
	add_child(play)
	current_player = play
	current_player.position = Vector2(225, 535)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_enemy_grid_attack_player(dmg):
	current_player.take_damage(dmg)
	if current_player.health <= 0:
		emit_signal("player_negative_hp", current_player.health)

func check_on_spells():
	if current_player.mana >= 60:
		$MarginContainer/ScrollContainer/spells_container/spell_fireball.disabled = false
	else:
		$MarginContainer/ScrollContainer/spells_container/spell_fireball.disabled = true
	if current_player.mana >= 30 and concrete_stones_rn <= 8:
		$MarginContainer/ScrollContainer/spells_container/spell_stonedefend.disabled = false
	else:
		$MarginContainer/ScrollContainer/spells_container/spell_stonedefend.disabled = true

func _on_grid_button_pressable(state):
	if state == move:
		check_on_spells()
	elif state == wait:
		$MarginContainer/ScrollContainer/spells_container/spell_stonedefend.disabled = true
		$MarginContainer/ScrollContainer/spells_container/spell_fireball.disabled = true

func _on_grid_add_mana(mana):
	current_player.mana_change(-mana)
	check_on_spells()

func _on_spell_fireball_pressed():
	emit_signal("attack_enemy", 25)
	emit_signal("change_move")
	current_player.mana_change(60)
	check_on_spells()

func _on_spell_stonedefend_pressed():
	current_player.mana_change(30)
	current_player.armor_change(30)
	emit_signal("stone_defend")
	emit_signal("change_move")
	check_on_spells()

func _on_grid_inflict_corrupted_dmg(dmg):
	current_player.take_damage(dmg)
	if current_player.health <= 0:
		emit_signal("player_negative_hp", current_player.health)

func _on_grid_concrete_stones_rn(num):
	concrete_stones_rn = num

func _on_grid_armor_break(num):
	current_player.armor_change(-num)
	if current_player.armor < 0:
		current_player.armor = 0
