extends KinematicBody2D

const WALK_SPEED = 150
const JUMP_SPEED = 230

export (int, 0, 200) var push = 100
export var fall_multiplier = 2

onready var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var velocity = Vector2()
var is_on_rope = false
var rope = null

func drop_rope():
	if Input.is_action_pressed("ui_right"):
		velocity.x += 300
	elif Input.is_action_pressed("ui_left"):
		velocity.x -= 300
	is_on_rope = false

func _physics_process(delta):
	if rope != null:
		if position.distance_to(rope.global_position) > 100:
			rope = null
			set_collision_layer_bit(0, true)
			set_collision_mask_bit(0, true)

	if Input.is_action_pressed("ui_left"):
		$Sprite.flip_h = true
	elif Input.is_action_pressed("ui_right"):
		$Sprite.flip_h = false

	if is_on_rope and Input.is_action_pressed("jump"):
		drop_rope()
	
	if is_on_rope:
		$AnimationPlayer.play("catch")
		set_collision_layer_bit(0, false)
		set_collision_mask_bit(0, false)
		velocity = Vector2(0, 0)
		position = rope.global_position
		if Input.is_action_pressed("ui_right"):
			rope.apply_central_impulse(Vector2.RIGHT * push * 0.05)
		elif Input.is_action_pressed("ui_left"):
			rope.apply_central_impulse(Vector2.LEFT * push * 0.05)
		elif Input.is_action_just_pressed("ui_up"):
			var prev_chunk = rope.get_prev()
			if prev_chunk != null:
				rope = prev_chunk
		elif Input.is_action_just_pressed("ui_down"):
			var next_chunk = rope.get_next()
			if next_chunk != null:
				rope = next_chunk
			else:
				drop_rope()
		return
	
	if !is_on_floor():
		velocity.y += delta * gravity

	if is_on_floor():
		if Input.is_action_pressed("ui_left"):
			velocity.x = -WALK_SPEED
			$AnimationPlayer.play("walk")
		elif Input.is_action_pressed("ui_right"):
			velocity.x = WALK_SPEED
			$AnimationPlayer.play("walk")
		else:
			$AnimationPlayer.play("idle")
			velocity.x = 0

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
		elif collision.collider.is_in_group("rope_chunks"):
			is_on_rope = true
			rope = collision.collider
