extends RigidBody2D

func get_next():
	var child = get_node("CollisionShape2D/joint/rope_chunk")
	while child != null and !child.is_in_group("rope_chunks"):
		child = child.get_node("CollisionShape2D/joint/rope_chunk")
	return child

func get_prev():
	var parent = get_parent()
	while parent != null and !parent.is_in_group("rope_chunks"):
		parent = parent.get_parent()
	return parent

func get_root():
	var parent = get_parent()
	while parent != null and !parent.is_in_group("rope_root"):
		parent = parent.get_parent()
	return parent
