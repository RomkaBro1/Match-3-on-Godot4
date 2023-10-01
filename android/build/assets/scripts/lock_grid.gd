extends Node2D

signal remove_lock

var lock_pieces = []
var width = 9
var height = 9
var lock = preload("res://scenes/rusty_lock.tscn")
var silver_lock = preload("res://scenes/silver_lock.tscn")
var golden_lock = preload("res://scenes/golden_lock.tscn")

var locks = [
	lock,
	silver_lock,
	golden_lock
]

func _ready():
	if lock_pieces.size() == 0:
		lock_pieces = make_2d_array()

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


func _on_grid_make_lock(board_position):
	if lock_pieces.size() == 0:
		lock_pieces = make_2d_array()
	var current = locks[randi_range(0,2)].instantiate()
	add_child(current)
	current.position = Vector2(board_position.x * 108 + 108, -board_position.y * 108 + 1600)
	lock_pieces[board_position.x][board_position.y] = current


func _on_grid_damage_lock(board_position):
	if lock_pieces[board_position.x][board_position.y] != null:
		lock_pieces[board_position.x][board_position.y].take_damage(1)
		if lock_pieces[board_position.x][board_position.y].health <= 0:
			var plusscore = 0
			plusscore = lock_pieces[board_position.x][board_position.y].value
			lock_pieces[board_position.x][board_position.y].queue_free()
			lock_pieces[board_position.x][board_position.y] = null
			emit_signal("remove_lock", board_position, plusscore)
