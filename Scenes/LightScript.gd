extends DirectionalLight3D

@export var cycleSpeed := 0.025

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.rotation.x += cycleSpeed * delta
	
	if rad_to_deg(self.rotation.x) >= 360:
		var rotationOff := rad_to_deg(self.rotation.x) - 360
		self.rotation.x = deg_to_rad(0 + rotationOff)
