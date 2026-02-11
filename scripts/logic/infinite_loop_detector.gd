class_name InfiniteLoopDetector
extends RefCounted

## Detects cyclic activation patterns in the reader sequence.
## Uses pattern matching to identify when the same sequence of runes is being
## activated repeatedly, indicating an infinite loop.

## Única constante de design: quantas repetições do ciclo confirmam um loop real.
## Valores menores = detecção mais rápida, mas risco de falso positivo.
## Valores maiores = mais seguro, mas o loop roda mais tempo antes de ser interrompido.
## 10 garante confiança alta: um ciclo A→B→C precisa repetir 10 vezes (30 ativações).
const MIN_REPETITIONS: int = 10

## Derivados do grid — calculados em _init():
## O maior ciclo possível é o painel inteiro (5×5 = 25 runas).
## O buffer precisa caber MIN_REPETITIONS ciclos completos para detecção.
var max_cycle_length: int = 25
var buffer_size: int = 250

## Buffer circular de ativações: [{rune_id, slot_position, remaining_activations}]
var activation_buffer: Array[Dictionary] = []

## Loops detectados durante esta sessão
var detected_loops: Array[Dictionary] = []


func _init() -> void:
	# GridManager.GRID_SIZE is 5, so max_cycle_length = 25
	max_cycle_length = 5 * 5  # Hardcoded to avoid dependency on GridManager class
	buffer_size = max_cycle_length * MIN_REPETITIONS  # 250


## Records an activation in the buffer.
## Call this after each rune activation in the reader.
func record_activation(rune_id: StringName, slot_position: Vector2i, remaining_activations: int) -> void:
	var entry := {
		"rune_id": rune_id,
		"slot_position": slot_position,
		"remaining_activations": remaining_activations
	}
	activation_buffer.append(entry)
	
	# Trim buffer if it exceeds max size
	if activation_buffer.size() > buffer_size:
		activation_buffer.pop_front()
	
	print("[InfiniteLoopDetector] Recorded: %s at %s (remaining: %d)" % [
		rune_id, str(slot_position), remaining_activations
	])


## Checks for a cyclic pattern in the activation buffer.
## Returns {} if no loop detected, or a Dictionary with loop data:
## {cycle_runes: Array[StringName], cycle_slots: Array[Vector2i], cycle_length: int, repetitions: int}
func check_for_loop() -> Dictionary:
	var buf_size := activation_buffer.size()
	
	# Need at least MIN_REPETITIONS * 2 activations for the smallest cycle (length 2)
	if buf_size < MIN_REPETITIONS * 2:
		return {}
	
	print("[InfiniteLoopDetector] Checking for loops... buffer_size=%d" % buf_size)
	
	# Test each possible cycle length from smallest (2) to largest
	for k in range(2, max_cycle_length + 1):
		var required_size := k * MIN_REPETITIONS
		if buf_size < required_size:
			continue
		
		var loop_data := _check_cycle_length(k, required_size)
		if not loop_data.is_empty():
			return loop_data
	
	return {}


## Helper: Check if the last (k * MIN_REPETITIONS) entries form a repeating cycle of length k.
func _check_cycle_length(k: int, required_size: int) -> Dictionary:
	var buf_size := activation_buffer.size()
	var start_idx := buf_size - required_size
	
	# Extract the base pattern (first k entries in the window)
	var base_pattern: Array[StringName] = []
	for i in range(k):
		base_pattern.append(activation_buffer[start_idx + i]["rune_id"])
	
	print("[InfiniteLoopDetector] Testing cycle_length=%d... pattern=%s" % [k, str(base_pattern)])
	
	# Check if this pattern repeats MIN_REPETITIONS times
	for rep in range(1, MIN_REPETITIONS):
		var rep_start := start_idx + rep * k
		for i in range(k):
			var entry := activation_buffer[rep_start + i]
			if entry["rune_id"] != base_pattern[i]:
				# Pattern doesn't match at this repetition
				return {}
	
	print("[InfiniteLoopDetector] Pattern repeated %d/%d times. Checking activation stability..." % [
		MIN_REPETITIONS, MIN_REPETITIONS
	])
	
	# Verify that remaining_activations are stable (not decreasing = true infinite loop)
	# Compare the first and last repetition
	var is_stable := _check_activation_stability(start_idx, k)
	if not is_stable:
		print("[InfiniteLoopDetector] Activations are decreasing, loop will converge naturally")
		return {}
	
	# Loop confirmed! Extract cycle data
	var cycle_runes: Array[StringName] = []
	var cycle_slots: Array[Vector2i] = []
	for i in range(k):
		var entry := activation_buffer[start_idx + i]
		cycle_runes.append(entry["rune_id"])
		cycle_slots.append(entry["slot_position"])
	
	var loop_data := {
		"cycle_runes": cycle_runes,
		"cycle_slots": cycle_slots,
		"cycle_length": k,
		"repetitions": MIN_REPETITIONS
	}
	
	detected_loops.append(loop_data)
	
	print("[InfiniteLoopDetector] LOOP DETECTED: cycle_length=%d, runes=%s" % [k, str(cycle_runes)])
	
	return loop_data


## Helper: Check if activations are stable across repetitions.
## Returns true if remaining_activations are NOT decreasing (true infinite loop).
func _check_activation_stability(start_idx: int, k: int) -> bool:
	# Compare remaining_activations between first and last repetition
	for i in range(k):
		var first_entry := activation_buffer[start_idx + i]
		var last_entry := activation_buffer[start_idx + (MIN_REPETITIONS - 1) * k + i]
		
		# If activations are decreasing, the loop will eventually end naturally
		if last_entry["remaining_activations"] < first_entry["remaining_activations"]:
			return false
	
	return true


## Returns the total number of loops detected during this session.
func get_total_loops_detected() -> int:
	return detected_loops.size()


## Clears the buffer and detected loops. Call when starting a new battle.
func reset() -> void:
	activation_buffer.clear()
	detected_loops.clear()
	print("[InfiniteLoopDetector] Reset")
