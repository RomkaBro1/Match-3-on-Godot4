extends Node2D

signal remove_concrete

var concrete_pieces = []
var width = 9
var height = 9
var concrete = preload("res://scenes/concrete.tscn")
var concrete_tex = preload("res://art/figures/concrete.png")
var concrete_damaged_tex = preload("res://art/figures/concrete_damaged.png")

func _ready():
	if concrete_pieces.size() == 0:
		concrete_pieces = make_2d_array()

func make_2d_array(): # создаём сетку width на height
	var array = [];
	for i in width:
		array.append([])
		for j in height:
			array[i] += [null]
	return array

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_grid_make_concrete(board_position):
	if concrete_pieces.size() == 0:
		concrete_pieces = make_2d_array()
	var current = concrete.instantiate()
	add_child(current)
	current.get_child(0).texture = concrete_tex
	concrete_pieces[board_position.x][board_position.y] = current
	current.position = Vector2(board_position.x * 108 + 108, -board_position.y * 108 + 1600 - 20)
	var tween: Tween = create_tween()
	tween.tween_property(current, "position", \
	Vector2(board_position.x * 108 + 108, -board_position.y * 108 + 1600), 0.75) \
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_grid_damage_concrete(board_position):
	if concrete_pieces[board_position.x][board_position.y] != null:
		concrete_pieces[board_position.x][board_position.y].take_damage(1)
		SoundManager.play_fixed_sound(0)
		if concrete_pieces[board_position.x][board_position.y].health <= 0:
			concrete_pieces[board_position.x][board_position.y].queue_free()
			concrete_pieces[board_position.x][board_position.y] = null
			emit_signal("remove_concrete", board_position)
		elif concrete_pieces[board_position.x][board_position.y].health <= 1:
			concrete_pieces[board_position.x][board_position.y].get_child(0).texture = concrete_damaged_tex
