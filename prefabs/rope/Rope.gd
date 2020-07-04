extends Node2D

var chunk = preload("res://prefabs/rope/rope_chunk.tscn")

export (int) var chunks = 1
var last_chunk = null

func _ready():
	var parent = $anchor
	for i in range(chunks):
		parent = add_link(parent)
		if i == chunks - 1:
			last_chunk = parent

func add_link(parent):
	var joint = parent.get_node("CollisionShape2D/joint")
	var chunk_instance = chunk.instance()
	joint.add_child(chunk_instance)
	joint.node_a = parent.get_path()
	joint.node_b = chunk_instance.get_path()
	return chunk_instance
