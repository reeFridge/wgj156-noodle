extends KinematicBody2D

# STATIC VARIABLES
export var l = 2 #length of the pendulum; 1/100 of the pendulum graphic
export var g = 9.81 #m/s^2, gravitational acceleration
export var gamma = 0.1 #damping ratio to take friction into account
export var factor = 200
export var initial_phi = PI / 2

# PENDULUM CHANGING VARIABLES
onready var phi = initial_phi #starting angle of the pendulum
var phi_first = 0 #starting angular velocity of the pendulum

var velocity = Vector2()
var pos = Vector2()

func _ready():
	pos = updatePhi() * factor
	position = pos

func updatePhi(a=phi):
	var offset = 5*PI/2 #offset factor to correct angles
	return Vector2(l * cos(a + offset), l * sin(a + offset))

func phiSecond(a, ao):
	return ( - g / l * sin(a) - gamma * ao )

# UPDATE PHI EACH FRAME
func _physics_process(delta):
	phi += phi_first * delta
	phi_first += phiSecond(phi, phi_first) * delta #phi_second * delta
	
	var new_position = updatePhi() * factor
	velocity = (new_position - pos) / delta
	pos = new_position
	
	move_and_slide(velocity)
	update()
	
func _draw():
	draw_line(Vector2(0, 0), velocity.normalized() * 100, Color.red)
