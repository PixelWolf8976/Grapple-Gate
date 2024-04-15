extends Node3D

var peer := ENetMultiplayerPeer.new()
@export var playerScene : PackedScene

@onready var ip := $Multiplayer/TextEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	print(1/delta)

func _on_host_pressed():
	peer.create_server(1027)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$Multiplayer.hide()

func _on_join_pressed():
	if peer.create_client(ip.text, 1027) != ERR_CANT_CREATE:
		multiplayer.multiplayer_peer = peer
		$Multiplayer.hide()
	else:
		ip.text = "Invalid IP!"

func add_player(id = 1):
	var player := playerScene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id):
	get_node(str(id)).queue_free()
