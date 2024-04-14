extends CharacterBody3D

@export var walkSpeed := 500.0
@export var jumpStrength := 300.0
@export var frictionSubtractor := 0.75
@export var gravity := 9.8
@export var grappleLine := MeshInstance3D.new()

@onready var twistPivot := $TwistPivot
@onready var pitchPivot := $TwistPivot/PitchPivot

@onready var mesh := $MeshInstance3D
@onready var collision := $CollisionShape3D
@onready var aim := $TwistPivot/PitchPivot/RayCast3D

var mouseSensitivity := 0.001
var twistInput := 0.0
var pitchInput := 0.0
var speed := walkSpeed
var isCrouching := false
var isGrappleing := false

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
		
		if is_on_floor() && !isGrappleing:
			var fdirection := Vector3(0, 0, -1).rotated(Vector3(0, 1, 0), mesh.rotation.y)
			var ldircetion := Vector3(0, 0, -1).rotated(Vector3(0, 1, 0), mesh.rotation.y + deg_to_rad(90))
			if Input.is_action_pressed("Walk Forward"):
				velocity.x += fdirection.x * speed * delta
				velocity.z += fdirection.z * speed * delta
			if Input.is_action_pressed("Walk Backwards"):
				velocity.x -= fdirection.x * speed * delta
				velocity.z -= fdirection.z * speed * delta
			if Input.is_action_pressed("Walk Left"):
				velocity.x += ldircetion.x * speed * delta
				velocity.z += ldircetion.z * speed * delta
			if Input.is_action_pressed("Walk Right"):
				velocity.x -= ldircetion.x * speed * delta
				velocity.z -= ldircetion.z * speed * delta
		
		twistPivot.rotate_y(twistInput)
		mesh.rotate_y(twistInput)
		collision.rotate_y(twistInput)
		pitchPivot.rotate_x(pitchInput)
		pitchPivot.rotation.x = clamp(pitchPivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		twistInput = 0.0
		pitchInput = 0.0
		
		if Input.is_action_pressed("Equipment Primary"):
			isGrappleing = true
		if Input.is_action_just_released("Equipment Primary"):
			isGrappleing = false
		
		if isGrappleing:
			if aim.is_colliding():
				var grapHitPoint = aim.get_collision_point()
				grappleLine = grapLine(self.position, grapHitPoint)
				get_tree().get_root().add_child(grappleLine)
				isGrappleing = true
			else:
				isGrappleing = false
		
		if Input.is_action_just_pressed("ui_cancel") && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.is_action_just_pressed("ui_accept") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			$"../".exit_game(name.to_int())
			get_tree().quit()
		elif Input.is_action_just_pressed("ui_cancel") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	move_and_slide()

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
