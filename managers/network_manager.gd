extends Node

var multiplayer_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new();

const PORT = 9999
const ADDRESS = "localhost"

var connected_peer_ids = []
var is_host: bool = false
var peer_id: int

signal on_connected_peer_update
signal on_server_shutdown

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func create_server():
	connected_peer_ids = []
	multiplayer_peer.create_server(PORT)
	# multiplayer is an built-in object
	# tells it current multiplayer_peer is incharge of the multi-player
	multiplayer.multiplayer_peer = multiplayer_peer
	# each multiplayer_peer has an unique ID
	# multiplayer.get_unique_id()
	add_player(1)
	peer_id = 1
	# when client connects , it emits a signal with its unique ID
	multiplayer_peer.peer_connected.connect(
		func(new_peer_id):
			rpc("add_newly_connected_player" , new_peer_id)
			# only calls rpc on specified client id
			rpc_id(new_peer_id , "add_previously_connected_players" , connected_peer_ids)
			rpc_id(new_peer_id , "assign_peer_id" , new_peer_id)
			add_player(new_peer_id)
			# fires on host
			on_connected_peer_update.emit()
	)

func join_server(address):
	connected_peer_ids = []
	multiplayer_peer.create_client(address, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer

@rpc()
func assign_peer_id(id):
	self.peer_id = id

# annotate with rpc to make it available from rpc() calls
@rpc
func add_newly_connected_player(new_peer_id):
	add_player(new_peer_id)

@rpc
func add_previously_connected_players(peer_ids):
	for id in peer_ids:
		add_player(id)
	# Calls on remote to refresh the list
	on_connected_peer_update.emit();

func add_player(id):
	connected_peer_ids.append(id)

func disconnect_server():
	for id in connected_peer_ids:
		if(id != peer_id):
			multiplayer_peer.disconnect_peer(id , true)

@rpc
func server_shutdown():
	on_server_shutdown.emit()
	pass
