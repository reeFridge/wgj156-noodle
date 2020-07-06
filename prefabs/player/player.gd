extends KinematicBody2D

const WALK_SPEED = 180
const JUMP_SPEED = 230

export (int, 0, 200) var push = 100
export var fall_multiplier = 2
export var throw_rope_force = 100
export var pull_rope_force = 50
export var super_pull_factor = 50

var rope_end = preload("res://prefabs/rope/rope_end.tscn")

onready var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var velocity = Vector2()
var walk_force = 0
var jump_force = 0
onready var rope_start_pos = $rope_start.position
	
func reset_rope():
	$rope.end_pin = false
	var end_node = get_node($rope.end_node)
	$rope.end_node = ""
	if end_node.is_in_group("rope_end"):
		end_node.disconnect("body_entered", self, "rope_end_collides")
		end_node.get_parent().remove_child(end_node)
	
func _process(delta):
	if sign($rope_start.position.x) > 0:
		if Input.is_action_pressed("ui_down"):
			$rot.rotation_degrees = clamp($rot.rotation_degrees + 60 * delta, -90, 90)
		elif Input.is_action_pressed("ui_up"):
			$rot.rotation_degrees = clamp($rot.rotation_degrees - 60 * delta, -90, 90)
	elif sign($rope_start.position.x) < 0:
		if Input.is_action_pressed("ui_up"):
			$rot.rotation_degrees = clamp($rot.rotation_degrees + 60 * delta, 90, 270)
		elif Input.is_action_pressed("ui_down"):
			$rot.rotation_degrees = clamp($rot.rotation_degrees - 60 * delta, 90, 270)

	if Input.is_action_just_pressed("throw_rope") && !$rope.end_pin:
		var rope_end_instance = rope_end.instance()
		rope_end_instance.position = $rope_start.global_position + Vector2.RIGHT * sign($rope_start.position.x) * 10
		rope_end_instance.connect("body_entered", self, "rope_end_collides")
		get_tree().root.get_child(0).add_child(rope_end_instance)
		$rope.end_pin = true
		$rope.end_node = rope_end_instance.get_path()
		var throw_vector = ($rot/Sprite.global_position - $rot.global_position).normalized()
		rope_end_instance.apply_central_impulse(throw_vector * throw_rope_force)
	elif Input.is_action_just_pressed("reset_rope") && $rope.end_pin:
		reset_rope()
	elif Input.is_action_just_pressed("super_pull_rope") && $rope.end_pin && !get_node($rope.end_node).is_in_group("rope_end"):
		var end_node = get_node($rope.end_node)
		var pull_vector = ($rope_start.global_position - end_node.global_position).normalized()
		if end_node is RigidBody2D:
			end_node.apply_central_impulse(pull_vector * pull_rope_force * super_pull_factor)
	elif Input.is_action_pressed("pull_rope") && $rope.end_pin:
		var end_node = get_node($rope.end_node)
		var pull_vector = ($rope_start.global_position - end_node.global_position).normalized()
		if end_node.is_in_group("rope_end"):
			var dist = clamp($rope_start.global_position.distance_to(end_node.global_position) / 500, 0, 1)
			end_node.apply_central_impulse(pull_vector * pull_rope_force * dist)
		elif end_node is RigidBody2D:
			end_node.apply_central_impulse(pull_vector * pull_rope_force)
		elif end_node is StaticBody2D:
			velocity = -pull_vector * pull_rope_force
			
func mirror_node(s, node, start_pos):
	node.position.x = s * start_pos.x

func rope_end_collides(body: Node):
	if body.is_in_group("rope_interactive"):
		var end_node = get_node($rope.end_node)
		$rope.end_node = body.get_path()
		end_node.get_parent().remove_child(end_node)

func _physics_process(delta):
	if Input.is_action_pressed("ui_left"):
		$Sprite.flip_h = true
		jump_force = -WALK_SPEED
		mirror_node(-1, $rope_start, rope_start_pos)
		if $rot.rotation_degrees >= -90 && $rot.rotation_degrees <= 90:
			$rot.rotation_degrees = 180 - $rot.rotation_degrees
	elif Input.is_action_pressed("ui_right"):
		jump_force = WALK_SPEED
		$Sprite.flip_h = false
		mirror_node(1, $rope_start, rope_start_pos)
		if $rot.rotation_degrees >= 90 && $rot.rotation_degrees <= 270:
			$rot.rotation_degrees = 180 - $rot.rotation_degrees
	
	if !is_on_floor():
		velocity.y += delta * gravity

	if is_on_floor():
		walk_force = 0
		jump_force = 0
		if Input.is_action_pressed("ui_left"):
			walk_force = -WALK_SPEED
			$AnimationPlayer.play("walk")
		elif Input.is_action_pressed("ui_right"):
			walk_force = WALK_SPEED
			$AnimationPlayer.play("walk")
		else:
			$AnimationPlayer.play("idle")
	
	if is_on_floor():
		velocity.x = walk_force
	else:
		velocity.x = jump_force

	if !is_on_floor() and velocity.y > -220:
		velocity += Vector2.UP * -9.81 * fall_multiplier
		
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		$AnimationPlayer.play("jump")
		velocity.y = -JUMP_SPEED

	move_and_slide(velocity, Vector2.UP, false, 4, PI/4, false)
	
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider.is_in_group("bodies"):
			collision.collider.apply_central_impulse(-collision.normal * push)
