extends Actor

signal player_died

export var min_speed = 50

export var max_jump_force = 700
var jump_force = max_jump_force

export var stomp_impulse: float = 500

onready var stomp_detector: Area2D = $StompDetector
onready var anim_player: AnimationPlayer = $AnimationPlayer

var dead: bool = false

func _on_StompDetector_area_entered(area: Area2D) -> void:
	print("Player: ", stomp_detector.global_position.y, "\nEnemy: ", area.global_position)
	if stomp_detector.global_position.y > area.global_position.y:
		return
	print("IMPULSE DATA\n=======")
	print("Enemy Y: ", area.global_position.y)
	print("Player Y: ", stomp_detector.global_position.y)
	_velocity = calculate_stomp_velocity(_velocity, stomp_impulse)


func _on_EnemyDetector_body_entered(_body: Node) -> void:
	print("ENTROU")
	die()


func _physics_process(delta: float) -> void:
	var is_jump_interrupted = Input.is_action_just_released("jump") and _velocity.y < 0.0
	var direction = get_direction()
	_velocity = calculate_move_velocity(_velocity, direction, acceleration, deacceleration, is_jump_interrupted, delta)
	var snap: Vector2 = Vector2.DOWN if direction.y == 0 else Vector2.ZERO
	_velocity = move_and_slide_with_snap(_velocity, snap, FLOOR_NORMAL, true)
	print(_velocity.x)


func get_direction() -> Vector2:
	var x_dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	# For the jump to occur the player must be on the ground (is_on_floor), the
	# jump key must just have been pressed and it cannot have been released.
	var y_dir = -Input.get_action_strength("jump") if is_on_floor() and \
	Input.is_action_just_pressed("jump") else 0.0
	
	return Vector2(x_dir, y_dir)


func calculate_move_velocity(
		linear_velocity: Vector2,
		direction: Vector2,
		acceleration: float,
		deacceleration: float,
		is_jump_interrupted: bool,
		delta: float
	) -> Vector2:
	
	var velocity: = linear_velocity
	if dead:
		return Vector2.ZERO
	# X Movement		/\/\/\/\/\/\/\/\/\/\
	
	# Deacceleration when changing directions
	if direction.x != 0 and velocity.x != 0:
		var velocity_dir: = velocity.x/abs(velocity.x)
		if direction.x + velocity_dir == 0:
			velocity.x = lerp(velocity.x, 0, deacceleration*delta) #The deacceleration is slower when changing directions.
	# Deacceleration when stoping
	if direction.x == 0:
		velocity.x = lerp(_velocity.x, 0, (deacceleration*delta)/1.5)
	# Accelerating
	elif direction.x != 0:
		var vel_dir := 1 if not abs(velocity.x) - velocity.x else -1
		vel_dir = direction.x if not velocity.x else vel_dir
#		print("Vx: %s\nMd: %s" % [velocity.x, min_speed*vel_dir])
		var is_accel = vel_dir == direction.x or abs(velocity.x) < 20
		if is_accel and abs(velocity.x) < min_speed:
			velocity.x = min_speed * direction.x
		else:
			velocity.x += direction.x * acceleration * delta
			velocity.x = clamp(velocity.x, -max_spd.x, max_spd.x)

		
	# Y Movement		/\/\/\/\/\/\/\/\/\/\
	
	## TODO: Better jump (at the moment this code just doesnt make difference)
	if direction.y != 0:
		velocity.y += direction.y * jump_force
		velocity.y = clamp(velocity.y, -max_spd.y, max_spd.y)
		jump_force /= 2
	elif direction.y == 0:
		jump_force = max_jump_force
	if is_jump_interrupted:
		velocity.y = 0.0
		jump_force = max_jump_force
	return velocity


func calculate_stomp_velocity(linear_velocity: Vector2, stomp_force: float) -> Vector2:
	var velocity = linear_velocity
	var impulse = stomp_force
	
	# There is no deacelleration when bouncing so the velocity will start at max at 0 (more will be equal to 0)
	if velocity.y > 0:
		velocity.y = 0

	velocity.y -= impulse #  and then be subtracted to add the jump impulse
	velocity.y = clamp(velocity.y, -max_jump_force, max_jump_force)
	
	return velocity


func die() -> void:
	if !dead:
		dead = true
		PlayerData.lifes -= 1
		$CollisionShape2D.set_deferred("disabled", true)
		print($CollisionShape2D.disabled)
		anim_player.play("death")
	yield(anim_player, "animation_finished")
	queue_free()
	emit_signal("player_died")
