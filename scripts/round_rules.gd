extends RefCounted
## Pure round state, independent of drawing and input.

const DURATION := 30.0
const POINTS_PER_CATCH := 10

var remaining := DURATION
var score := 0


func advance(delta: float) -> void:
	remaining = maxf(0.0, remaining - maxf(0.0, delta))


func catch_item() -> void:
	if remaining > 0.0:
		score += POINTS_PER_CATCH


func is_finished() -> bool:
	return remaining <= 0.0
