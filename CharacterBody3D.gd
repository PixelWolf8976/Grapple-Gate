extends CharacterBody3D

@export var walkSpeed := 1000.0
@export var jumpStrength := 250.0
@export var gravity := 9.8

@onready var twistPivot := $TwistPivot
@onready var pitchPivot := $TwistPivot/PitchPivot

@onready var mesh := $MeshInstance3D
@onready var collision := $CollisionShape3D

var mouseSensitivity := 0.001
var twistInput := 0.0
var pitchInput := 0.0
var speed := walkSpeed
var isCrouching := false

@onready var cam := $TwistPivot/PitchPivot/Camera3D

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called when the node enters the scene tree for the first time.
func _ready():
	cam.current = is_multiplayer_authority()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_multiplayer_authority():
		velocity.y += -gravity * delta
		
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
		
		if is_on_floor() && !isCrouching && Input.is_action_pressed("Jump"):
			velocity.y += jumpStrength * delta
		
		var direction = mesh.global_transform.basis.z.normalized()
		
		if is_on_floor():
			if Input.is_action_pressed("Walk Forward"):
				velocity.x += direction.x * speed * delta
				velocity.y += direction.y * speed * delta
		
		twistPivot.rotate_y(twistInput)
		mesh.rotate_y(twistInput)
		collision.rotate_y(twistInput)
		pitchPivot.rotate_x(pitchInput)
		pitchPivot.rotation.x = clamp(pitchPivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		twistInput = 0.0
		pitchInput = 0.0
		
		if Input.is_action_just_pressed("ui_cancel") && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.is_action_just_pressed("ui_accept") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			$"../".exit_game(name.to_int())
			get_tree().quit()
		elif Input.is_action_just_pressed("ui_cancel") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	move_and_slide()

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			twistInput = - event.relative.x * mouseSensitivity
			pitchInput = - event.relative.y * mouseSensitivity
