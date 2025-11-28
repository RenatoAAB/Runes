# Rune Grid Auto-Battler Setup Instructions

This guide details how to assemble the provided scripts into a functional Godot 4.5 project.

## 1. Scene Structure

Create a new Scene (e.g., `Main.tscn`) with a **Control** or **Node2D** root. Create the following hierarchy:

```text
Main (Node)
├── Managers (Node)
│   ├── GameManager (Script: res://scripts/logic/game_manager.gd)
│   ├── GridManager (Script: res://scripts/logic/grid_manager.gd)
│   ├── InventoryManager (Script: res://scripts/logic/inventory_manager.gd)
│   └── Reader (Script: res://scripts/logic/reader.gd)
├── UI (CanvasLayer)
│   ├── GameUI (Control)
│   │   ├── GridContainer (GridContainer)
│   │   │   └── (This will hold your 25 SlotUIs)
│   │   ├── InventoryContainer (HBoxContainer)
│   │   │   └── (This will hold Inventory SlotUIs)
│   │   ├── BattleButton (Button)
│   │   └── ScoreLabel (Label)
│   ├── GridHighlighter (Script: res://scripts/ui/grid_highlighter.gd)
│   └── TooltipManager (Script: res://scripts/ui/tooltip_manager.gd)
```

## 2. Node Configuration & Wiring

Select the nodes in the Scene Tree and configure them in the Inspector:

### **GameManager**
- **Reader:** Assign the `Reader` node.
- **Inventory Manager:** Assign the `InventoryManager` node.
- **Grid Manager:** Assign the `GridManager` node.
- **Available Runes:** (Leave empty for now, we will fill this in Step 4).

### **Reader**
- **Grid Manager:** Assign the `GridManager` node.
- **Step Delay:** Set to `0.5` (or your preference).

### **GridHighlighter**
- **Grid Manager:** Assign the `GridManager` node.
- **Groups:** Go to the "Node" tab -> "Groups" and add `grid_highlighter`.

### **TooltipManager**
- **Groups:** Go to the "Node" tab -> "Groups" and add `tooltip_manager`.

## 3. UI Setup

### **Grid Container**
- Set **Columns** to `5`.
- You need to fill this with 25 instances of a Slot Scene.
    1. Create a new Scene `Slot.tscn`.
    2. Root Node: `PanelContainer` (Script: `res://scripts/ui/slot_ui.gd`).
    3. Add a `ColorRect` child (for highlighting) and ensure it's behind the content.
    4. Instantiate this `Slot.tscn` 25 times inside the `GridContainer`.
    5. **Important:** You need a script to assign coordinates to these slots. You can do this in `Main.gd` (see Step 5) or manually set a `grid_coord` variable if you expose it.

### **Inventory Container**
- Add instances of `Slot.tscn` here as well (e.g., 5-10 slots).

### **Battle Button**
- Connect its `pressed` signal to `GameManager.start_battle()`.

## 4. Creating Data Resources

You need to create actual Rune data to play.

### A. Shared Logic (Files)
Create resources for logic that doesn't change values (Reusable):
1.  In FileSystem, right-click -> Create New -> Resource.
2.  Create `TargetAdjacent`, `TargetSelf`, `ConditionAlways`.
3.  Save them in `res://resources/effects/`.

### B. Specific Logic (Sub-Resources)
For logic that has specific numbers (like Score Amount), create them **inside** the RuneData:

1.  **Create Runes:**
    *   Right-click -> Create New -> Resource -> `RuneData`.
    *   Save as `res://resources/runes/FireRune_T1.tres`.
    *   Set `Name`, `Element`, `Tier`.
    *   **Effects:** Add an element to the array.
    *   **Crucial Step:** Instead of dragging a file, click the dropdown -> **New RuneEffect**.
    *   Expand the new effect.
    *   **Condition:** Drag your shared `ConditionAlways.tres` (or create a New ConditionNeighborCount if you need specific numbers).
    *   **Target:** Drag your shared `TargetSelf.tres`.
    *   **Payload:** Click dropdown -> **New PayloadAddScore**.
    *   Expand the payload and set **Score Amount** to whatever value you want for *this specific rune*.

2.  **Register Runes:**
    *   Select `GameManager`.
    *   Add your created `RuneData` resources to the **Available Runes** array.

## 5. Connecting Logic to UI (The Missing Link)

The provided scripts handle logic, but you need a small "glue" script on your `Main` node to initialize the UI slots.

Create a script for `Main` (root node):

```gdscript
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
```

## 6. Running the Game

1.  Press F5 (Play).
2.  The `GameManager` will auto-start.
3.  It will populate the inventory with random runes (from your `Available Runes` list).
4.  Drag runes to the grid.
5.  Press the "Battle" button.
6.  Watch the Reader traverse the grid and trigger effects!
