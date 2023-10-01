extends Sprite2D
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func move(tarloc):
	self.scale = Vector2(0, 0)
	var tween_scale: Tween = create_tween()
	var tween: Tween = create_tween()
	tween_scale.tween_property(self, "scale", Vector2(.3, .3), .3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_scale.chain().tween_property(self, "scale", Vector2(0.01, 0.01), .35).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", tarloc, 1)\
	.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(1).timeout
	queue_free()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$trail.width = self.scale.x / 0.2 * 16
