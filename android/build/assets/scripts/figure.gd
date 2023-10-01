extends Node2D

@export var color:String
@export var spawn_weight:int
@export var value:int
@export var mana_value:int

@export var col_tex:Texture
@export var row_tex:Texture
@export var mega_tex:Texture
@export var rainbow_tex:Texture
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var is_row_bomb = false
var is_col_bomb = false
var is_mega_bomb = false
var is_rainbow_bomb = false

var matched = false

func make_col_bomb():
	is_col_bomb = true
	value = 0
	$figure_sprite.texture = col_tex
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1, 0.1).set_delay(0.05)

func make_row_bomb():
	is_row_bomb = true
	value = 0
	$figure_sprite.texture = row_tex
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1, 0.1).set_delay(0.05)

func make_mega_bomb():
	is_mega_bomb = true
	value = 0
	$figure_sprite.texture = mega_tex
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1, 0.1).set_delay(0.05)
	
func make_rainbow_bomb():
	is_rainbow_bomb = true
	value = 0
	$figure_sprite.texture = rainbow_tex
	color = "rainbow"
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1, 0.1).set_delay(0.05)

func move(target):
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", target, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
func be_destroyed():
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.10, 0.10), 0.5).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
