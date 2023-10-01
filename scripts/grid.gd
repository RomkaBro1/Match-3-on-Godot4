extends Node2D

#State Machine
enum {wait, move}
var state
var attack_in = 5
var damaged_corrupted = false
var current_matches = []
var health_positive = true

var combo = 1
var score = 0

# Grid Variables публичные переменные
@export var width:int
@export var height:int
@export var x_start:int
@export var y_start:int
@export var offset:int
var y_offset = 0.7
var figure_one = null
var figure_two = null

# препятствия
@export var empty_spaces:PackedVector2Array
@export var ice_spaces:PackedVector2Array
@export var lock_spaces:PackedVector2Array
@export var concrete_spaces:PackedVector2Array
@export var corrupted_spaces:PackedVector2Array

# сигналы
signal make_ice
signal damage_ice
signal make_lock
signal damage_lock
signal make_concrete
signal damage_concrete
signal make_corrupted
signal damage_corrupted
signal update_score
signal update_attack_in
signal button_pressable
signal add_mana
signal inflict_corrupted_dmg
signal concrete_stones_rn
signal armor_break

var all_figures = []
var clone_figures = []
var just_exploded = []

var first_touch = Vector2(0, 0)
var final_touch = Vector2(0, 0)

var controlling = false

var possible_color = [
	"void",
	"water",
	"air",
	"fire",
	"earth",
	"lightning"
]
var possible_figures = [ # берём фигуры в массив
preload("res://scenes/water_figure.tscn"),
preload("res://scenes/fire_figure.tscn"),
preload("res://scenes/air_figure.tscn"),
preload("res://scenes/lightning_figure.tscn"),
preload("res://scenes/earth_figure.tscn"),
preload("res://scenes/void_figure.tscn")
]
var bg = preload("res://scenes/bg.tscn")

var debuff_list = [
	'fire_weakness',
	'water_weakness',
	'air_weakness',
	'earth_weakness',
	'void_weakness',
	'lightning_weakness'
	]

# Эффекты
var concrete_destruction_particle = preload("res://scenes/concrete_particle.tscn")
var mana_particle = preload("res://scenes/mana_particle.tscn")

func spawn_effect(effect, column, row):
	var current = effect.instantiate()
	current.get_child(0).position = grid_to_pixel(column, row)
	add_child(current)
	if effect == mana_particle:
		current.get_child(0).move(Vector2(225, 350))

var weight_sum = global_weight()
func global_weight():
	var sum = 0
	for i in possible_figures.size():
		var temp = possible_figures[i].instantiate()
		sum += temp.spawn_weight
	return sum

func get_random_figure():
	var sum = 0
	var rand = randi_range(1, weight_sum) # генерим число от 1 до макс веса
	for i in possible_figures.size(): #профит
		var temp = possible_figures[i].instantiate()
		sum += temp.spawn_weight
		if sum >= rand:
			return possible_figures[i].instantiate()
	print("ОШИБКА")

func _ready(): # главная функция
	randomize()
	all_figures = make_2d_array()
	clone_figures = make_2d_array()
	spawn_figures()
	spawn_ice()
	spawn_locks()
	spawn_concrete()
	spawn_corrupted()

func restricted_fill(place):
	if is_in_array(place, empty_spaces):
		return true
	if is_in_array(place, concrete_spaces):
		return true
	if is_in_array(place, corrupted_spaces):
		return true
	return false

func restricted_move(place):
	if is_in_array(place, empty_spaces): #удалить в случае ошибки
		return true
	if is_in_array(place, lock_spaces):
		return true
	if is_in_array(place, concrete_spaces):
		return true
	if is_in_array(place, corrupted_spaces):
		return true
	return false

func convert_matches_to_mana(value):
	await get_tree().create_timer(1).timeout
	var mana = value
	emit_signal("add_mana", mana)

func make_2d_array(): # создаём сетку width на height
	var array = [];
	for i in width:
		array.append([])
		for j in height:
			array[i] += [null]
	return array

#######################################################################################
# проверка на отсутствие ходов
func switch_and_check(item, direction, array):
	if array[item.x][item.y] != null and !restricted_move(item):
		if is_in_grid(item + direction):
			if array[item.x + direction.x][item.y + direction.y] != null \
			and !restricted_move(item + direction):
				# меняем и проверяем
				var first_figure = array[item.x][item.y]
				var second_figure = array[item.x + direction.x][item.y + direction.y]
				array[item.x][item.y] = second_figure
				array[item.x + direction.x][item.y + direction.y] = first_figure
				if find_matches(true, array):
					array[item.x][item.y] = first_figure
					array[item.x + direction.x][item.y + direction.y] = second_figure
					return true
				array[item.x][item.y] = first_figure
				array[item.x + direction.x][item.y + direction.y] = second_figure
				return false

func is_deadlocked():
	clone_figures = all_figures.duplicate()
	for i in width:
		for j in height:
			if switch_and_check(Vector2(i, j), Vector2(1, 0), clone_figures):
				return false
			if switch_and_check(Vector2(i, j), Vector2(0, 1), clone_figures):
				return false
	return true
	
func shuffle_board():
	var flag = false
	clone_figures = all_figures.duplicate()
	all_figures.clear()
	all_figures = make_2d_array()
	for i in width:
		for j in height:
			if !restricted_fill(Vector2(i, j)):
				var rand = Vector2(randi_range(0, width-1), randi_range(0, height-1))
				var loops = 0
				while (restricted_fill(rand) or \
				clone_figures[rand.x][rand.y] == null or \
				check_for_similarity(i, j, clone_figures[rand.x][rand.y].color)) and \
				loops < 100:
					rand = Vector2(randi_range(0, width-1), randi_range(0, height-1))
					loops += 1
				
				if loops >= 100:
					flag = true
					print("GG")
				
				clone_figures[rand.x][rand.y].move(grid_to_pixel(i, j))
				all_figures[i][j] = clone_figures[rand.x][rand.y]
				clone_figures[rand.x][rand.y] = null
	if find_matches(true) and flag: # если каким-то образом нашли 3 в ряд (только в случае луп+100)
		shuffle_board()
#######################################################################################

func spawn_figures(): # спавним фигуры
	for i in width:
		for j in height:
			if !restricted_fill(Vector2(i, j)):
				var br = bg.instantiate()
				add_child(br)
				br.position = grid_to_pixel(i, j)
				var figure = get_random_figure()
				var loops = 0
				while (check_for_similarity(i, j, figure.color)) and (loops < 666): # чтобы без решённых вариантов
					figure = get_random_figure()
					loops += 1
				add_child(figure)
				figure.position = grid_to_pixel(i, j) + Vector2(0, -30)
				var tween: Tween = create_tween()
				tween.tween_property(figure, "position", grid_to_pixel(i, j), 0.5)\
				.set_trans(Tween.TRANS_ELASTIC)\
				.set_ease(Tween.EASE_OUT)
				all_figures[i][j] = figure
				await get_tree().create_timer(0.01).timeout
	state = move
	while is_deadlocked():
		shuffle_board()
	emit_signal("button_pressable", move)

func spawn_ice():
	for i in ice_spaces.size():
		emit_signal("make_ice", ice_spaces[i])

func spawn_locks():
	for i in lock_spaces.size():
		emit_signal("make_lock", lock_spaces[i])
		
func spawn_corrupted():
	for i in corrupted_spaces.size():
		var br = bg.instantiate() # спавним фон
		add_child(br)
		br.position = grid_to_pixel(corrupted_spaces[i].x, corrupted_spaces[i].y)
		
		emit_signal("make_corrupted", corrupted_spaces[i])
		
func spawn_concrete():
	for i in concrete_spaces.size():
		var coord = grid_to_pixel(concrete_spaces[i].x, concrete_spaces[i].y)
		var br = bg.instantiate() # спавним фон
		add_child(br)
		br.position = coord
		
		var figure = get_random_figure()
		add_child(figure)
		figure.position = coord
		all_figures[concrete_spaces[i].x][concrete_spaces[i].y] = figure
		
		emit_signal("make_concrete", concrete_spaces[i])

func check_for_similarity(i, j, color):
	if i > 1:
		if !is_figure_null(i - 1, j) && !is_figure_null(i - 2, j) and \
		!restricted_fill(Vector2(i - 1, j)) && !restricted_fill(Vector2(i - 2, j)):
			if all_figures[i-1][j].color == color && all_figures[i-2][j].color == color:
				return true
	if j > 1:
		if !is_figure_null(i, j - 1) && !is_figure_null(i, j - 2) and \
		!restricted_fill(Vector2(i, j - 1)) && !restricted_fill(Vector2(i, j - 2)):
			if all_figures[i][j-1].color == color && all_figures[i][j-2].color == color:
				return true
	return false
	
func pixel_to_grid(x, y):
	var new_x = (x - x_start) / offset
	var new_y = (y - y_start) / -offset
	new_x = round(new_x)
	new_y = round(new_y)
	return Vector2(new_x, new_y)

func grid_to_pixel(x, y): # переводим место в списке в координату
	var new_x = x_start + offset * x
	var new_y = y_start + -offset * y
	return Vector2(new_x, new_y)

func is_in_grid(grid_position):
	if 0 <= grid_position.x && grid_position.x < width && 0 <= grid_position.y && grid_position.y < height:
		return true
	return false

func is_in_array(item, array):
	for i in array.size():
		if array[i] == item:
			return true
	return false

func add_to_array(item, array = current_matches):
	if !array.has(item):
		array.append(item)

func is_figure_null(column, row):
	if all_figures[column][row] == null:
		return true
	return false

func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, \
		get_global_mouse_position().y)):
			first_touch = get_global_mouse_position()
			controlling = true
	if Input.is_action_just_released("ui_touch"):
		final_touch = get_global_mouse_position()
		if controlling and is_in_grid(pixel_to_grid(get_global_mouse_position().x, \
		get_global_mouse_position().y)):
			touch_difference(pixel_to_grid(first_touch.x, first_touch.y), \
			pixel_to_grid(final_touch.x, final_touch.y))
		controlling = false
		
func swapper(column, row, direction, flag=true):
	var first_figure = all_figures[column][row]
	var final_figure = all_figures[column + direction.x][row + direction.y]
	if first_figure != null and final_figure != null and \
	!restricted_move(Vector2(column, row)) and \
	!restricted_move(Vector2(column, row) + direction):
		figure_one = first_figure
		figure_two = final_figure
		state = wait
		emit_signal("button_pressable", wait)
		all_figures[column][row] = final_figure
		all_figures[column + direction.x][row + direction.y] = first_figure
		first_figure.move(grid_to_pixel(column + direction.x, row + direction.y))
		final_figure.move(grid_to_pixel(column, row))
		if figure_one.color == "rainbow":
			destroy_colored_figures(figure_two.color)
			match_and_destroy(figure_one)
			get_parent().get_node("destroy_timer").start()
		elif figure_two.color == "rainbow":
			destroy_colored_figures(figure_one.color)
			match_and_destroy(figure_two)
			get_parent().get_node("destroy_timer").start()
		elif find_matches() and flag:
			await get_tree().create_timer(.3).timeout
			swapper(column, row, direction, false)
			state = move
			emit_signal("button_pressable", move)

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swapper(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swapper(grid_1.x, grid_1.y, Vector2(-1, 0))
	elif abs(difference.x) < abs(difference.y):
		if difference.y > 0:
			swapper(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swapper(grid_1.x, grid_1.y, Vector2(0, -1))

func find_matches(checking = false, array = all_figures):
	var found_matches = false
	for i in width:
		for j in height:
			if !is_figure_null(i, j) && !restricted_fill(Vector2(i, j)):
				var current_color = array[i][j].color
				if i > 0 && i < width - 1:
					if !is_figure_null(i - 1, j) and \
					!is_figure_null(i + 1, j) and \
					!restricted_fill(Vector2(i + 1, j)) and \
					!restricted_fill(Vector2(i - 1, j)):
						if array[i - 1][j].color == current_color && \
						array[i + 1][j].color == current_color:
							if checking:
								return true
							found_matches = true
							match_and_destroy(array[i - 1][j])
							match_and_destroy(array[i][j])
							match_and_destroy(array[i + 1][j])
							add_to_array(Vector2(i - 1, j))
							add_to_array(Vector2(i, j))
							add_to_array(Vector2(i + 1, j))
				if j > 0 && j < height - 1:
					if !is_figure_null(i, j - 1) and \
					!is_figure_null(i, j + 1) and \
					!restricted_fill(Vector2(i, j + 1)) and \
					!restricted_fill(Vector2(i, j - 1)):
						if array[i][j - 1].color == current_color && \
						array[i][j + 1].color == current_color:
							if checking:
								return true
							found_matches = true
							match_and_destroy(array[i][j - 1])
							match_and_destroy(array[i][j])
							match_and_destroy(array[i][j + 1])
							add_to_array(Vector2(i, j - 1))
							add_to_array(Vector2(i, j))
							add_to_array(Vector2(i, j + 1))
	if checking:
		return false
	if found_matches:
		combo += 1
		get_bombed_figures()
		get_parent().get_node("destroy_timer").start()
		return false
	else:
		return true

func destroy_colored_figures(color):
	for i in width:
		for j in height:
			if !is_figure_null(i, j) && \
			!restricted_fill(Vector2(i, j)):
				if all_figures[i][j].color == color:
					match_and_destroy(all_figures[i][j])
	get_bombed_figures()

func get_bombed_figures():
	for i in width:
		for j in height:
			if !is_figure_null(i, j) && !just_exploded.has(Vector2(i, j)):
				if all_figures[i][j].matched:
					if all_figures[i][j].is_col_bomb:
						match_all_in_column(i)
						just_exploded.append(Vector2(i, j))
						get_bombed_figures()
						attack_in += 1
					elif all_figures[i][j].is_row_bomb:
						match_all_in_row(j)
						just_exploded.append(Vector2(i, j))
						get_bombed_figures()
						attack_in += 1
					elif all_figures[i][j].is_mega_bomb:
						match_all_in_column(i)
						match_all_in_row(j)
						attack_in += 1
						just_exploded.append(Vector2(i, j))
						get_bombed_figures()
					elif all_figures[i][j].is_rainbow_bomb:
						possible_color.shuffle()
						just_exploded.append(Vector2(i, j))
						destroy_colored_figures(possible_color[0])

func corrupt():
	if corrupted_spaces.size() > 0 && damaged_corrupted == false:
		var corrupted_list = corrupted_spaces.duplicate()
		while corrupted_list.size() > 0:
			var rand = randi_range(0, corrupted_list.size() - 1)
			var rand_place = corrupted_list[rand]
			corrupted_list.remove_at(rand)
			var rand_neighbour = find_normal_neighbour(rand_place.x, rand_place.y)
			if rand_neighbour == null:
				continue
			else:
				all_figures[rand_neighbour.x][rand_neighbour.y].be_destroyed()
				await get_tree().create_timer(.3).timeout
				all_figures[rand_neighbour.x][rand_neighbour.y].queue_free()
				all_figures[rand_neighbour.x][rand_neighbour.y] = null
				corrupted_spaces.append(Vector2(rand_neighbour.x, rand_neighbour.y))
				emit_signal("make_corrupted", Vector2(rand_neighbour.x, rand_neighbour.y))
				return
	pass

func find_normal_neighbour(column, row):
	var rand = []
	while rand.size() < 4:
		var rand_int = randi_range(0, 4)
		if !is_in_array(rand_int, rand):
			rand.append(rand_int)
	var rand_int
	while rand.size() > 0:
		rand_int = rand.pop_front()
		if rand_int == 0 && is_in_grid(Vector2(column + 1, row)) && \
		!is_figure_null(column + 1, row) && \
		!restricted_fill(Vector2(column + 1, row)) && \
		!is_in_array(Vector2(column + 1, row), corrupted_spaces): # проверка справа
			return Vector2(column + 1, row)
		if rand_int == 1 && is_in_grid(Vector2(column - 1, row)) && \
		!is_figure_null(column - 1, row) && \
		!restricted_fill(Vector2(column - 1, row)) && \
		!is_in_array(Vector2(column - 1, row), corrupted_spaces): # проверка слева
			return Vector2(column - 1, row)
		if rand_int == 2 && is_in_grid(Vector2(column, row + 1)) && \
		!is_figure_null(column, row + 1) && \
		!restricted_fill(Vector2(column, row + 1)) and \
		!is_in_array(Vector2(column, row + 1), corrupted_spaces): # check right firs
			return Vector2(column, row + 1)
		if rand_int == 3 && is_in_grid(Vector2(column, row - 1)) && \
		!is_figure_null(column, row - 1) && \
		!restricted_fill(Vector2(column, row - 1)) and \
		!is_in_array(Vector2(column, row - 1), corrupted_spaces): # check right firs
			return Vector2(column, row - 1)
	return null

func match_and_destroy(item):
	item.matched = true
	item.be_destroyed()

func destroy_matched():
	find_bombs()
	check_concrete()
	check_corrupted()
	for i in width:
		for j in height:
			if !is_figure_null(i, j):
				if all_figures[i][j].matched:
					score += all_figures[i][j].value * combo
					spawn_effect(mana_particle, i, j)
					convert_matches_to_mana(all_figures[i][j].mana_value)
					emit_signal("update_score", score)
					damage_special(i, j)
					all_figures[i][j].queue_free()
					all_figures[i][j] = null
					get_parent().get_node("collapse_timer").start()
	current_matches.clear()

func damage_special(column, row):
	emit_signal("damage_ice", Vector2(column, row))
	emit_signal("damage_lock", Vector2(column, row))

func find_bombs():
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		var current_color = all_figures[current_column][current_row].color
		var col_matched = 0
		var row_matched = 0
		for j in current_matches.size():
			var this_column = current_matches[j].x
			var this_row = current_matches[j].y
			var this_color = all_figures[this_column][this_row].color
			if this_column == current_column and this_color == current_color:
				col_matched += 1
			if this_row == current_row and this_color == current_color:
				row_matched += 1
		if (4 == col_matched or col_matched == 3) and (4 == row_matched or row_matched == 3):
			make_bomb(2, current_color)
			return
		if col_matched == 4:
			make_bomb(1, current_color)
		if row_matched == 4:
			make_bomb(0, current_color)
		if col_matched == 5 or row_matched == 5:
			make_bomb(3, current_color)

func make_bomb(type, color):
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		if all_figures[current_column][current_row] == figure_one && \
		color == figure_one.color:
			figure_one.matched = false
			change_bomb(type, figure_one)
		if all_figures[current_column][current_row] == figure_two && \
		color == figure_two.color:
			figure_two.matched = false
			change_bomb(type, figure_two)

func change_bomb(type, figure):
	if type == 0:
		figure.make_col_bomb()
	elif type == 1:
		figure.make_row_bomb()
	elif type == 2:
		figure.make_mega_bomb()
	elif type == 3:
		figure.make_rainbow_bomb()

func collapse_columns():
	for i in width:
		for j in height:
			if is_figure_null(i, j) and !restricted_fill(Vector2(i, j)):
				for k in range(j + 1, height):
					if !is_figure_null(i, k) and !is_in_array(Vector2(i, k), concrete_spaces) and \
					!is_in_array(Vector2(i, k), corrupted_spaces):
						all_figures[i][k].move(grid_to_pixel(i, j))
						all_figures[i][j] = all_figures[i][k]
						all_figures[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	for i in width:
		for j in height:
			if is_figure_null(i, j) and !restricted_fill(Vector2(i, j)):
				#var rand = randi_range(0, possible_figures.size()-1)
				#var figure = possible_figures[rand].instantiate()
				var figure = get_random_figure()
				var loops = 0
				while (check_for_similarity(i, j, figure.color)) and (loops < 666): 
					# чтобы без решённых вариантов
					#rand = randi_range(0, possible_figures.size()-1)
					#figure = possible_figures[rand].instantiate()
					figure = get_random_figure()
					loops += 1
				add_child(figure)
				figure.position = grid_to_pixel(i, j - y_offset)
				figure.move(grid_to_pixel(i, j))
				all_figures[i][j] = figure
	post_refill()

func post_refill():
	for i in width:
		for j in height:
			if !is_figure_null(i, j):
				if check_for_similarity(i, j, all_figures[i][j].color) and \
				!restricted_fill(Vector2(i, j)):
					find_matches()
					return
	await get_tree().create_timer(.5).timeout # чтобы помедленнее шло
	emit_signal("concrete_stones_rn", concrete_spaces.size())
	combo = 1
	corrupt()
	change_moves()
	damaged_corrupted = false
	while is_deadlocked():
		shuffle_board()
	just_exploded.clear()
	state = move # ход полностью закончился
	if !health_positive:
		declare_gameover()
	emit_signal("button_pressable", state)

func declare_gameover():
	print("GAME OVER")
	state = wait
	get_tree().change_scene_to_file("res://scenes/game_menu.tscn")

func spawn_random_concrete():
	var rand = randi_range(2, 4)
	for k in rand:
		var ranx = randi_range(0, width-1)
		var rany = randi_range(0, height-1)
		var loops = 0
		while restricted_fill(Vector2(ranx, rany)) or loops > 666:
			ranx = randi_range(0, width-1)
			rany = randi_range(0, height-1)
			loops += 1
		if loops <= 666:
			concrete_spaces.append(Vector2(ranx, rany))
			emit_signal("make_concrete", concrete_spaces[-1])
		else:
			print('ОШИБКА=)')

func change_moves(counter = 1):
	for i in counter:
		if damaged_corrupted == false and randi_range(0,2) == 0: 
			emit_signal("inflict_corrupted_dmg", corrupted_spaces.size())
		if attack_in >= 0:
			attack_in -= 1
			emit_signal("update_attack_in", attack_in)
		if attack_in == -1:
			attack_in = 5
			emit_signal("update_attack_in", attack_in)
		else:
			emit_signal("armor_break", 5)

func check_concrete():
	for i in range(concrete_spaces.size()-1, -1, -1):
		var coord = concrete_spaces[i]
		if is_in_grid(coord + Vector2(1, 0)):
			if !is_figure_null(coord.x + 1, coord.y) && \
			all_figures[coord.x + 1][coord.y].matched == true:
				emit_signal("damage_concrete", coord)
				spawn_effect(concrete_destruction_particle, coord.x, coord.y)
		if is_in_grid(coord + Vector2(-1, 0)):
			if !is_figure_null(coord.x - 1, coord.y) && \
			all_figures[coord.x - 1][coord.y].matched == true:
				emit_signal("damage_concrete", coord)
				spawn_effect(concrete_destruction_particle, coord.x, coord.y)
		if is_in_grid(coord + Vector2(0, 1)):
			if !is_figure_null(coord.x, coord.y + 1) && \
			all_figures[coord.x][coord.y + 1].matched == true:
				emit_signal("damage_concrete", coord)
				spawn_effect(concrete_destruction_particle, coord.x, coord.y)
		if is_in_grid(coord + Vector2(0, -1)):
			if !is_figure_null(coord.x, coord.y - 1) && \
			all_figures[coord.x][coord.y - 1].matched == true:
				emit_signal("damage_concrete", coord)
				spawn_effect(concrete_destruction_particle, coord.x, coord.y)

func check_corrupted():
	for i in range(corrupted_spaces.size()-1, -1, -1):
		var coord = corrupted_spaces[i]
		if is_in_grid(coord + Vector2(1, 0)):
			if !is_figure_null(coord.x + 1, coord.y) && \
			all_figures[coord.x + 1][coord.y].matched == true:
				emit_signal("damage_corrupted", coord)
				damaged_corrupted = true
		if is_in_grid(coord + Vector2(-1, 0)):
			if !is_figure_null(coord.x - 1, coord.y) && \
			all_figures[coord.x - 1][coord.y].matched == true:
				emit_signal("damage_corrupted", coord)
				damaged_corrupted = true
		if is_in_grid(coord + Vector2(0, 1)):
			if !is_figure_null(coord.x, coord.y + 1) && \
			all_figures[coord.x][coord.y + 1].matched == true:
				emit_signal("damage_corrupted", coord)
				damaged_corrupted = true
		if is_in_grid(coord + Vector2(0, -1)):
			if !is_figure_null(coord.x, coord.y - 1) && \
			all_figures[coord.x][coord.y - 1].matched == true:
				emit_signal("damage_corrupted", coord)
				damaged_corrupted = true

func _process(_delta):
	if state == move:
		touch_input()

func match_all_in_column(column):
	for i in height:
		if !is_figure_null(column, i):
			match_and_destroy(all_figures[column][i])
		elif is_in_array(Vector2(column, i), corrupted_spaces):
			emit_signal("damage_corrupted", Vector2(column, i))
			damaged_corrupted = true

func match_all_in_row(row):
	for i in width:
		if !is_figure_null(i, row):
			match_and_destroy(all_figures[i][row])
		elif is_in_array(Vector2(i, row), corrupted_spaces):
			emit_signal("damage_corrupted", Vector2(i, row))
			damaged_corrupted = true

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

func _on_lock_grid_remove_lock(place, plusscore):
	for i in range(lock_spaces.size() - 1, -1, -1):
		if lock_spaces[i] == place:
			score += plusscore
			emit_signal("update_score", score)
			lock_spaces.remove_at(i)

func _on_concrete_grid_remove_concrete(place):
	for i in range(concrete_spaces.size() - 1, -1, -1):
		if concrete_spaces[i] == place:
			score += 10
			emit_signal("update_score", score)
			concrete_spaces.remove_at(i)

func _on_corrupted_grid_remove_corrupted(place):
	for i in range(corrupted_spaces.size() - 1, -1, -1):
		if corrupted_spaces[i] == place:
			corrupted_spaces.remove_at(i)

func _on_player_grid_change_move():
	change_moves()
	emit_signal("button_pressable", move)

func _on_player_grid_stone_defend():
	spawn_random_concrete()
	emit_signal("concrete_stones_rn", concrete_spaces.size())

func _on_player_grid_player_negative_hp(hp):
	health_positive = false

func _on_enemy_grid_enemy_negative_hp(hp):
	declare_gameover()
	# заглушка ИЗМЕНИТЬ
