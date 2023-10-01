extends TextureRect

@onready var score_label = $score_label
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_grid_update_score(score):
	score_label.text = str(score)
