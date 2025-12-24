extends Timer
@export var enabled : bool = true
@export var autoTargetPlayer : bool = true
@export var waves : Array[WaveSpawnerWaveParams]
@export var between_wave_time : float = 5.0
var current_wave : WaveSpawnerWaveParams
var current_wave_index : int = 0
var wave_time : float

var state : int = 0 #0 - idle, 1 - between waves, 2 - in wave, 3 - completed

signal starting_next_wave
signal wave_started
signal all_cleared


func is_cleared() -> bool:
	return current_wave_index > waves.size()


func _process(_delta: float) -> void:
	if state == 3:
		$label.text = "Done."
		return
	if current_wave == null or state == 0:
		if state == 1:
			$label.text = "Starting next wave..."
			return
		$label.text = "No wave..."
		return
	$label.text = "Current Wave %s of %s\nTime Left %d\nEnemies - %s of %s" % [
		current_wave_index,
		waves.size(),
		wave_time,
		current_wave.get_alive_pawns().size(),
		current_wave.get_remaining_in_wave()
	]


func _ready() -> void:
	if enabled:
		one_shot = true
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	if current_wave != null and enabled:
		#If all enemies of the wave are dead, or the time limit for this wave was exceeded, begin the next wave.
		wave_time -= delta
		if current_wave.is_wave_complete() or wave_time < 0.0:
			if is_last_wave():
				#Last wave means we're done.
				print("Done with all waves!!!")
				set_completed()
			else:
				countdown_next_wave()
			set_physics_process(false)
			return


#Starts the next wave.
func start_next_wave() -> void:
	print("Next wave started.")
	current_wave = get_wave_and_advance()
	if current_wave == null:
		print("--- All waves completed.")
		set_completed()
		return #It's all done
	var timeBetween = current_wave.time_between_spawns
	set_physics_process(true)
	state = 2
	wave_time = current_wave.wave_time_limit
	wave_started.emit()
	#Spawn the pawns of the wave.
	if current_wave != null:
		while not current_wave.is_all_spawned():
			if !is_instance_valid(gameManager.getCurrentPawn()):
				break
			print("Wave %d--- Spawned Pawn" % current_wave_index)
			var wavePawn = current_wave.spawn_next_pawn(self)
			if autoTargetPlayer:
				await get_tree().create_timer(0.1).timeout
				if is_instance_valid(gameManager.getCurrentPawn()):
					wavePawn[1].inputComponent.targetedPawns.append(gameManager.getCurrentPawn())
#					wavePawn[1].inputComponent.stateMachine.change_state("Attack")
					wavePawn[1].set_meta(&"ignore_activation_range",true)
					wavePawn[1].inputComponent.lookAtPosition(gameManager.getCurrentPawn().global_position)
				#print(wavePawn[1].inputComponent.pawnFSM.current_state)
			#Wait for the duration before spawning next pawn.
			if is_instance_valid(current_wave):
				await get_tree().create_timer(timeBetween, false, true, false).timeout


# Returns the next wave and advances the wave index
func get_wave_and_advance() -> WaveSpawnerWaveParams:
	if waves.size() <= current_wave_index:
		return null
	var next_wave = waves[current_wave_index]
	current_wave_index += 1
	return next_wave


# Checks if the current wave is the last one
func is_last_wave() -> bool:
	return current_wave_index >= waves.size()


# Starts the countdown before the next wave begins
func countdown_next_wave() -> void:
	if enabled:
		clear_wave()
		starting_next_wave.emit()
		state = 1
		start(between_wave_time)


# Clears the current wave reference
func clear_wave() -> void:
	current_wave = null


# Sets the spawner state to completed and emits the all_cleared signal
func set_completed() -> void:
	state = 3
	set_physics_process(false)
	all_cleared.emit()


# Called when the timer times out to start the next wave
func _on_timeout() -> void:
	if enabled:
		start_next_wave()
