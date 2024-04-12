extends RigidBody3D

@export var walkSpeed := 1200.0
@export var jumpStrength := 1.0

@onready var twistPivot := $TwistPivot
@onready var pitchPivot := $TwistPivot/PitchPivot

@onready var mesh := $MeshInstance3D
@onready var collision := $CollisionShape3D

var mouseSensitivity := 0.001
var twistInput := 0.0
var pitchInput := 0.0
var speed := walkSpeed
var isCrouching := false

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("Crouch"):
		speed = walkSpeed * 0.7
		mesh.scale.y = 0.5
		collision.scale.y = 0.5
		isCrouching = true
	elif Input.is_action_just_released("Crouch"):
		speed = walkSpeed
		mesh.scale.y = 1
		collision.scale.y = 1
		isCrouching = false
	
	var input := Vector3.ZERO
	
	if searchForStand(self.get_colliding_bodies()) && !isCrouching && Input.is_action_pressed("Jump"):
		input.y = jumpStrength
	
	if searchForStand(self.get_colliding_bodies()):
		input.x = Input.get_axis("Walk Left", "Walk Right")
		input.z = Input.get_axis("Walk Forward", "Walk Backwards")
		
		apply_central_force(twistPivot.basis * input * speed * delta)
		
		self.linear_damp = 3
	else:
		self.linear_damp = 0
	
	twistPivot.rotate_y(twistInput)
	mesh.rotate_y(twistInput)
	collision.rotate_y(twistInput)
	pitchPivot.rotate_x(pitchInput)
	pitchPivot.rotation.x = clamp(pitchPivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	twistInput = 0.0
	pitchInput = 0.0
	
	if Input.is_action_just_pressed("ui_cancel") && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif Input.is_action_just_pressed("ui_cancel") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func searchForStand(nodes):
	for node in nodes:
		if node.get_collision_layer_value(1):
			return true
	return false

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			twistInput = - event.relative.x * mouseSensitivity
			pitchInput = - event.relative.y * mouseSensitivity
