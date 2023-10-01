extends Node2D

@export var player_name:String
@export var health:int
@export var mana:int
@export var armor:int
@export var debuffs:PackedStringArray

enum {fireball, defend_stone} #spells

# Called when the node enters the scene tree for the first time.
func _ready():
	self.take_damage(0)
	self.mana_change(0)

func take_damage(inc_damage):
	armor -= inc_damage
	if armor <= 0:
		health += armor
		armor = 0
		$health_bar/hp_label.text = str(health)
		$health_bar/hp_label.add_theme_color_override("font_color", Color("ffffff"))
	elif armor > 0:
		$health_bar/hp_label.text = str(armor + health)
		$health_bar/hp_label.add_theme_color_override("font_color", Color("ffff00"))
	$armor_bar.value = armor
	$health_bar.value = health
	
func mana_change(change):
	mana -= change
	if mana > 100:
		mana = 100
	$mana_bar.value = mana
	$mana_bar/mana_label.text = str(mana)

func armor_change(change):
	armor += change
	if armor < 0:
		armor = 0
	$armor_bar.value = armor
	if armor > 0:
		$health_bar/hp_label.text = str(armor + health)
		$health_bar/hp_label.add_theme_color_override("font_color", Color("ffff00"))
		$armor_bar.value = armor
		$health_bar.value = health
	else:
		$health_bar/hp_label.text = str(armor + health)
		$health_bar/hp_label.add_theme_color_override("font_color", Color("ffffff"))

func _process(_delta):
	pass
