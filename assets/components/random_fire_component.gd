extends Node


@export_range(0.0, 100.0, 0.01, "suffix:%") var chance_percent : float = 50.0


signal rng_triggered
signal rng_failed


func roll_random() -> bool:
	if (randf() * 100.0) < chance_percent:
		rng_triggered.emit()
		return true
	else:
		rng_failed.emit()
		return false
