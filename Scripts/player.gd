extends CharacterBody3D

@export var walkSpeed := 500.0
@export var jumpStrength := 300.0
@export var grappleStrength := 10.0
@export var frictionSubtractor := 0.75
@export var gravity := 9.8

var grappleLine := MeshInstance3D.new()

@onready var twistPivot := $TwistPivot
@onready var pitchPivot := $TwistPivot/PitchPivot

@onready var mesh := $MeshInstance3D
@onready var collision := $CollisionShape3D
@onready var aim := $TwistPivot/PitchPivot/RayCast3D

var mouseSensitivity := 0.0025
var twistInput := 0.0
var pitchInput := 0.0
var speed := walkSpeed
var isCrouching := false
var isGrappleing := false
var lineOut := false
var grapHitPoint := Vector3.ZERO

@onready var cam := $TwistPivot/PitchPivot/Camera3D

func _enter_tree():
	set_multiplayer_authority(name.to_int())

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.current = is_multiplayer_authority()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_multiplayer_authority():
		if grappleLine != null:
			get_tree().get_root().remove_child(grappleLine)
			grappleLine.queue_free()
		velocity.y += -gravity * delta
		if is_on_floor():
			velocity.x = 0
			velocity.z = 0
		
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
		
		if is_on_floor() && !lineOut:
			var fdirection := Vector3(0, 0, -1).rotated(Vector3(0, 1, 0), mesh.rotation.y)
			var ldircetion := Vector3(0, 0, -1).rotated(Vector3(0, 1, 0), mesh.rotation.y + deg_to_rad(90))
			if Input.is_action_pressed("Walk Forward"):
				velocity.x += fdirection.x
				velocity.z += fdirection.z
			if Input.is_action_pressed("Walk Backwards"):
				velocity.x -= fdirection.x
				velocity.z -= fdirection.z
			if Input.is_action_pressed("Walk Left"):
				velocity.x += ldircetion.x
				velocity.z += ldircetion.z
			if Input.is_action_pressed("Walk Right"):
				velocity.x -= ldircetion.x
				velocity.z -= ldircetion.z
		
		var yVel = velocity.y
		velocity.y = 0
		velocity = velocity.normalized()
		velocity.y = yVel
		velocity.x *= speed * delta
		velocity.z *= speed * delta
		
		print("Player Speed: ", velocity.length())
		
		twistPivot.rotate_y(twistInput)
		mesh.rotate_y(twistInput)
		collision.rotate_y(twistInput)
		pitchPivot.rotate_x(pitchInput)
		pitchPivot.rotation.x = clamp(pitchPivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		twistInput = 0.0
		pitchInput = 0.0
		
		if Input.is_action_just_pressed("Equipment Primary"):
			if aim.is_colliding() && !lineOut:
				grapHitPoint = aim.get_collision_point()
				lineOut = true
			elif lineOut:
				lineOut = false
		
		if lineOut:
			grappleLine = grapLine(self.position, grapHitPoint)
			get_tree().get_root().add_child(grappleLine)
			var pullDirection = (self.position - grapHitPoint).normalized() * grappleStrength
			velocity = -pullDirection
			#lastPos = self.position
		
		if Input.is_action_just_pressed("ui_cancel") && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.is_action_just_pressed("ui_accept") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			$"../".exit_game(name.to_int())
			get_tree().quit()
		elif Input.is_action_just_pressed("ui_cancel") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	move_and_slide()

func angle_between_vectors_on_xy_plane(vec1: Vector3, vec2: Vector3) -> float:
	var vect1 = Vector2(vec1.x, vec1.z)
	var vect2 = Vector2(vec2.x, vec2.z)
	var angles = (vect1 - vect2).angle()
	return angles

func grapLine(pos1: Vector3, pos2: Vector3, color = Color.SADDLE_BROWN, thickness: float = 0.1) -> MeshInstance3D:
	var meshInstance = MeshInstance3D.new()
	var immediateMesh = ImmediateMesh.new()
	var material = ORMMaterial3D.new()
	
	meshInstance.mesh = immediateMesh
	
	var dir = (pos2 - pos1).normalized()
	var right = dir.cross(Vector3(0, 1, 0)).normalized()
	var up = right.cross(dir).normalized()
	
	var halfThickness = thickness / 2.0
	
	var p1 = pos1 - right * halfThickness
	var p2 = pos2 - right * halfThickness
	var p3 = pos2 + right * halfThickness
	var p4 = pos1 + right * halfThickness
	
	immediateMesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	
	immediateMesh.surface_add_vertex(p1)
	immediateMesh.surface_add_vertex(p2)
	immediateMesh.surface_add_vertex(p3)
	
	immediateMesh.surface_add_vertex(p3)
	immediateMesh.surface_add_vertex(p4)
	immediateMesh.surface_add_vertex(p1)
	
	immediateMesh.surface_end()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	return meshInstance

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			twistInput = - event.relative.x * mouseSensitivity
			pitchInput = - event.relative.y * mouseSensitivity
