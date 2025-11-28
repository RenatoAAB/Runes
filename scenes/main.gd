extends Node

@onready var grid_manager = $Managers/GridManager
@onready var inventory_manager = $Managers/InventoryManager
@onready var grid_container = $UI/GameUI/GridContainer
@onready var inventory_container = $UI/GameUI/InventoryContainer

func _ready():
    # 1. Link Grid Slots
    var grid_slots = grid_container.get_children()
    for i in range(grid_slots.size()):
        var slot_ui = grid_slots[i]
        var y = i / 5
        var x = i % 5
        slot_ui.grid_coord = Vector2i(x, y)
        
        # Connect UI drop signal to Logic
        slot_ui.rune_dropped.connect(_on_rune_dropped_on_grid)

    # 2. Link Inventory Slots
    var inv_slots = inventory_container.get_children()
    for i in range(inv_slots.size()):
        var slot_ui = inv_slots[i]
        slot_ui.inventory_index = i
        slot_ui.rune_dropped.connect(_on_rune_dropped_on_inventory)

    # 3. Listen for Logic Updates to Refresh UI
    # (You would ideally connect to GridManager/InventoryManager signals here 
    # to call slot_ui.set_rune(rune) when data changes)

func _on_rune_dropped_on_grid(rune: RuneInstance, target_slot_ui: SlotUI):
    # Handle logic: Remove from old location, place in new location
    # Update GridManager
    grid_manager.place_rune(rune.data, target_slot_ui.grid_coord)
    # Update UI
    target_slot_ui.set_rune(rune)

func _on_rune_dropped_on_inventory(rune: RuneInstance, target_slot_ui: SlotUI):
    # Handle logic moving back to inventory
    pass