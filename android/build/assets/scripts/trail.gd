extends Line2D

var point
var target
@export var targetpath:NodePath
@export var traillength:int
# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_top_level(true)
	target = get_node(targetpath)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	point = target.global_position
	add_point(point)
	while get_point_count() > traillength:
		remove_point(0)
