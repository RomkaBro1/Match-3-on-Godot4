extends Node2D

signal remove_corrupted

var corrupted_pieces = []
var width = 9
var height = 9
var corrupted = preload("res://scenes/corrupted_figure.tscn")

func _ready():
	if corrupted_pieces.size() == 0:
		corrupted_pieces = make_2d_array()

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

func _on_grid_make_corrupted(board_position):
	if corrupted_pieces.size() == 0:
		corrupted_pieces = make_2d_array()
	var current = corrupted.instantiate()
	add_child(current)
	current.position = Vector2(board_position.x * 108 + 108, -board_position.y * 108 + 1600)
	corrupted_pieces[board_position.x][board_position.y] = current

func _on_grid_damage_corrupted(board_position):
	if corrupted_pieces[board_position.x][board_position.y] != null:
		corrupted_pieces[board_position.x][board_position.y].take_damage(1)
		if corrupted_pieces[board_position.x][board_position.y].health <= 0:
			corrupted_pieces[board_position.x][board_position.y].queue_free()
			corrupted_pieces[board_position.x][board_position.y] = null
			emit_signal("remove_corrupted", board_position)
