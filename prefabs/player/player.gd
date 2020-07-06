extends KinematicBody2D

## PENDULUM-PHYSIC vars
# STATIC VARIABLES
export var l = 2.0 #length of the pendulum; 1/100 of the pendulum graphic
export var g = 9.81 #m/s^2, gravitational acceleration
export var gamma = 0.1 #damping ratio to take friction into account
export var factor = 200
# PENDULUM CHANGING VARIABLES
var phi = 0 #starting angle of the pendulum
var phi_first = 0 #starting angular velocity of the pendulum
var pendulum_pos = Vector2()
var pendulum_velocity = Vector2()

const WALK_SPEED = 180
const JUMP_SPEED = 230
const MAX_SPEED = 180
const MAX_V_SPEED = 230
const FRICTION_GROUND = 0.5
const FRICTION_AIR = 1

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
var hooked = false
onready var rope_start_pos = $rope_start.position

func init_pendulum(length, _phi):
	l = length
	phi = _phi
	pendulum_pos = updatePhi() * factor
	global_position = get_node($rope.end_node).global_position + pendulum_pos

func reset_pendulum():
	phi = 0 
	phi_first = 0
	pendulum_pos = Vector2()
	pendulum_velocity = Vector2()

func updatePhi(a=phi):
	var offset = 5*PI/2 #offset factor to correct angles
	return Vector2(l * cos(a + offset), l * sin(a + offset))

func phiSecond(a, ao):
	return ( - g / l * sin(a) - gamma * ao )
	
func update_pendulum_position(delta):
	phi += phi_first * delta
	phi_first += phiSecond(phi, phi_first) * delta
	
	var new_position = updatePhi() * factor
	pendulum_velocity = (new_position - pendulum_pos) / delta
	pendulum_pos = new_position

func reset_rope():
	$rope.end_pin = false
	reset_pendulum()
	hooked = false
	var end_node = get_node($rope.end_node)
	$rope.end_node = ""
	$rope_joint.node_b = ""
	if end_node.is_in_group("rope_end"):
		end_node.disconnect("body_entered", self, "rope_end_collides")
		end_node.get_parent().remove_child(end_node)

func throw_rope():
	var rope_end_instance = rope_end.instance()
	rope_end_instance.position = $rope_start.global_position + Vector2.RIGHT * sign($rope_start.position.x) * 10
	rope_end_instance.connect("body_entered", self, "rope_end_collides")
	get_tree().root.get_child(0).add_child(rope_end_instance)
	$rope.end_pin = true
	$rope.end_node = rope_end_instance.get_path()
	$rope_joint.node_b = $rope.end_node
	var throw_vector = ($rot/Sprite.global_position - $rot.global_position).normalized()
	rope_end_instance.apply_central_impulse(throw_vector * throw_rope_force)
	
func get_pull_vector() -> Vector2:
	if $rope.start_pin && $rope.end_pin:
		var end_node = get_node($rope.end_node)
		var pull_vector = ($rope_start.global_position - end_node.global_position).normalized()
		return pull_vector
	else:
		return Vector2(0, 0)

func pull_rope():
	var end_node = get_node($rope.end_node)
	var pull_vector = get_pull_vector()
	if end_node.is_in_group("rope_end"):
		var dist = clamp($rope_start.global_position.distance_to(end_node.global_position) / 500, 0, 1)
		end_node.apply_central_impulse(pull_vector * pull_rope_force * dist)
	elif end_node is RigidBody2D:
		end_node.apply_central_impulse(pull_vector * pull_rope_force)
		
func hook_rope():
	var end_node = get_node($rope.end_node)
	var pull_vector = get_pull_vector()
	if end_node is StaticBody2D:
		var angle = pull_vector.angle() - PI/2
		print(rad2deg(angle))
		init_pendulum(global_position.distance_to(end_node.global_position) / factor, angle)
		hooked = true

func mirror_node_position(s, node, start_pos):
	node.position.x = s * start_pos.x

func rope_end_collides(body: Node):
	if body.is_in_group("rope_interactive"):
		var end_node = get_node($rope.end_node)
		$rope.end_node = body.get_path()
		$rope_joint.node_b = ""
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

func _physics_process(delta):
	if Input.is_action_just_pressed("throw_rope") && !$rope.end_pin:
		throw_rope()
	elif Input.is_action_just_pressed("reset_rope") && $rope.end_pin:
		reset_rope()
	elif Input.is_action_just_pressed("super_pull_rope") && $rope.end_pin && !get_node($rope.end_node).is_in_group("rope_end"):
		var end_node = get_node($rope.end_node)
		var pull_vector = ($rope_start.global_position - end_node.global_position).normalized()
		if end_node is RigidBody2D:
			end_node.apply_central_impulse(pull_vector * pull_rope_force * super_pull_factor)
	elif Input.is_action_pressed("pull_rope") && $rope.end_pin:
		pull_rope()
	elif !hooked && !is_on_floor() && Input.is_action_just_pressed("hook_rope") && $rope.end_pin:
		hook_rope()
	
	var walk = (Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")) * WALK_SPEED
	
	if is_on_floor():
		if sign(walk) != 0:
			$AnimationPlayer.play("walk")
		else:
			$AnimationPlayer.play("idle")
	
	if sign(walk) < 0:
		$Sprite.flip_h = true
		mirror_node_position(-1, $rope_start, rope_start_pos)
		if $rot.rotation_degrees >= -90 && $rot.rotation_degrees <= 90:
			$rot.rotation_degrees = 180 - $rot.rotation_degrees
	elif sign(walk) > 0:
		$Sprite.flip_h = false
		mirror_node_position(1, $rope_start, rope_start_pos)
		if $rot.rotation_degrees >= 90 && $rot.rotation_degrees <= 270:
			$rot.rotation_degrees = 180 - $rot.rotation_degrees
	
	velocity.y += delta * gravity
	
	if hooked and Input.is_action_just_pressed("jump"):
		reset_rope()
		$AnimationPlayer.play("jump")
		velocity.y = -JUMP_SPEED
	
	# Hook physics
	if hooked:
		$AnimationPlayer.play("catch")
		update_pendulum_position(delta)
		velocity = pendulum_velocity
		move_and_slide(velocity, Vector2.UP, false, 4, PI/4, false)
		return

	if !is_on_floor() and velocity.y > -220:
		velocity += Vector2.UP * -9.81 * fall_multiplier
	
	velocity.x += walk
		
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	velocity.y = clamp(velocity.y, -MAX_V_SPEED, MAX_V_SPEED * 2)

	move_and_slide(velocity, Vector2.UP, false, 4, PI/4, false)
	
	var grounded = is_on_floor()
	if grounded:
		velocity.x *= FRICTION_GROUND	# Apply friction only on x (we are not moving on y anyway)
		if velocity.y >= 5:		# Keep the y-velocity small such that
			velocity.y = 5		# gravity doesn't make this number huge
	elif is_on_ceiling() and velocity.y <= -5:	# Same on ceilings
		velocity.y = -5
		
	if !grounded:
		velocity.x *= FRICTION_AIR
		if velocity.y > 0:
			velocity.y *= FRICTION_AIR
			
	if grounded and Input.is_action_just_pressed("jump"):
		$AnimationPlayer.play("jump")
		velocity.y = -JUMP_SPEED

	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider.is_in_group("bodies"):
			collision.collider.apply_central_impulse(-collision.normal * push)
