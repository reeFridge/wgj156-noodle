extends TileMap

var tilemap_merge_class := load("res://Tilemap_MergeCells.gd")
var tilemap_merge = tilemap_merge_class.new()
var rect_list : Array

func _ready():
	# Build collision edges and add to level collision object
	rect_list = tilemap_merge.merge(self)
	for rect in rect_list:
		var collision_rect := RectangleShape2D.new()
		var tile_size = cell_size
		# For one way collision to work the shape must be horizontal and then rotated to fit position
		collision_rect.set_extents(rect.size * tile_size / 2)
		var collision_shape := CollisionShape2D.new()
		collision_shape.set_shape(collision_rect)
		#collision_shape.one_way_collision = true
		collision_shape.set_position(rect.position * tile_size + collision_rect.extents)
		$"StaticBody2D".add_child(collision_shape)


func _draw():
	#print("Debug Draw")
	for child in $"StaticBody2D".get_children():
		if child is CollisionShape2D:
			draw_rect(Rect2(child.position - child.shape.extents, child.shape.extents * 2 - Vector2(1, 1)), 0x00FFFF8F)
			draw_circle(child.position, 4, 0xFF000080)

