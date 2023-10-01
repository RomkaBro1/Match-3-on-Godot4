extends Node2D

var ice_pieces = []
var width = 9
var height = 9
var ice = preload("res://scenes/ice.tscn")

func _ready():
	if ice_pieces.size() == 0:
		ice_pieces = make_2d_array()

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


func _on_grid_make_ice(board_position):
	if ice_pieces.size() == 0:
		ice_pieces = make_2d_array()
	var current = ice.instantiate()
	add_child(current)
	current.position = Vector2(board_position.x * 108 + 108, -board_position.y * 108 + 1600)
	ice_pieces[board_position.x][board_position.y] = current


func _on_grid_damage_ice(board_position):
	
	if ice_pieces[board_position.x][board_position.y] != null:
		ice_pieces[board_position.x][board_position.y].take_damage(1)
		if ice_pieces[board_position.x][board_position.y].health <= 0:
			ice_pieces[board_position.x][board_position.y].queue_free()
			ice_pieces[board_position.x][board_position.y] = null
