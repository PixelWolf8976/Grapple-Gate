extends RigidBody3D

@export var speed := 1200.0

@onready var twistPivot := $TwistPivot
@onready var pitchPivot := $TwistPivot/PitchPivot

var mouseSensitivity := 0.001
var twistInput := 0.0
var pitchInput := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var input := Vector3.ZERO
	input.x = Input.get_axis("Walk Left", "Walk Right")
	input.z = Input.get_axis("Walk Forward", "Walk Backwards")
	
	apply_central_force(twistPivot.basis * input * speed * delta)
	
	twistPivot.rotate_y(twistInput)
	pitchPivot.rotate_x(pitchInput)
	pitchPivot.rotation.x = clamp(pitchPivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	twistInput = 0.0
	pitchInput = 0.0

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			twistInput = - event.relative.x * mouseSensitivity
			pitchInput = - event.relative.y * mouseSensitivity
