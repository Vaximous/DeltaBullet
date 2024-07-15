extends Node
class_name AiMemoryManager
signal brainUpdated
signal memoryFound
signal memoriesRefreshed
signal memoryCreated

@export_category("Memory Manager")
@export var maxMemories : int = 15
@export var aiMemories : Array = []

func forgetMemories(olderThan:float)->void:
	var oldMemories = aiMemories.filter(func(mem): return mem.memoryAge > olderThan)
	for memory in oldMemories:
		var memInt = aiMemories.find(memory)
		aiMemories.remove_at(memInt)


func updateBrain(ai:AIComponent)->void:
	if ai != null:
		for tgt in ai.visibleObjects:
			refreshMemories(tgt,ai.pawnOwner)
			brainUpdated.emit()

func refreshMemories(target:Node3D,sensorOwner:Node3D)->void:
	if getMemory(target) != null:
		var mem = getMemory(target)
		mem.memoryOwner = target
		mem.memoryDirection = target.global_position - sensorOwner.global_position
		mem.memoryPosition = target.global_position
		mem.lastSeen = Time.get_ticks_usec()/1000000
		mem.distance = sensorOwner.global_position.distance_to(target.global_position)
		memoriesRefreshed.emit()
	else:
		createMemory(target,sensorOwner)

func getMemory(memoryObject:Node3D)->Memory:
	for _memory in aiMemories:
		if _memory.memoryOwner == memoryObject:
			return _memory
	return null

func createMemory(object:Node3D,sensorOwner:Node3D)->Memory:
	if !aiMemories.size() >= maxMemories:
		var _memory = Memory.new()
		_memory.memoryOwner = object
		_memory.memoryDirection = object.global_position - sensorOwner.global_position
		_memory.memoryPosition = object.global_position
		_memory.lastSeen = Time.get_ticks_usec()/1000000
		_memory.distance = sensorOwner.global_position.distance_to(object.global_position)
		aiMemories.append(_memory)
		memoryCreated.emit()
		return _memory
	else:
		return null
class Memory extends RefCounted:
	var memoryAge : float:
		set(value):
			memoryAge = Time.get_ticks_usec()/1000000 - lastSeen
		get:
			return Time.get_ticks_usec()/1000000 - lastSeen
	var memoryPosition : Vector3
	var memoryDirection : Vector3
	var memoryOwner : Node3D
	var distance : float
	var lastSeen : float
	var score : float
