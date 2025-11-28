class_name BattleContext
extends RefCounted

## A context object passed through the effect chain during execution.
## Acts as the API for effects to interact with the game state (Grid, Score, etc.)
## without coupling directly to Nodes like Reader or Main.

signal score_event(amount: int, source: RuneInstance)

var grid: GridManager

func _init(p_grid: GridManager):
	grid = p_grid

func add_score(amount: int, source: RuneInstance) -> void:
	score_event.emit(amount, source)
