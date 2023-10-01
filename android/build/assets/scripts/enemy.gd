extends Node2D

@export var enemy_name:String
@export var health:int
@export var damage:int
@export var debuffs:PackedStringArray

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func take_damage(inc_damage):
	health -= inc_damage
	$health_bar.value = health

func _process(_delta):
	pass
