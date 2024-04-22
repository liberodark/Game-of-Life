extends TileMap

## The sensitivity of the mouse. Controls how fast you can pan around.
@onready var mouse_sen: float = 10
## The number of seconds between each generation. Controls the speed of such.
@onready var delay_time: float = 0.125
## The rules of the game. The first arr contains the number of neighbors needed for a living cell to
## stay alive. The second arr contains the number of neighbors needed to bring a dead cell to life.
@onready var rules: Array[PackedInt32Array] = [[2, 3], [3]]

func _input(
	## Represents what the user just did.
	event: InputEvent
) -> void:
	# Handles mouse button inputs:
	if event is InputEventMouseButton:
		# Lets the user zoom in and out:
		if event.is_action_released("zoom in"):
			$Camera2D.zoom *= 1.175
			mouse_sen /= 1.175
		elif event.is_action_released("zoom out"):
			$Camera2D.zoom /= 1.175
			mouse_sen *= 1.175
	# Handles mouse motion inputs:
	elif event is InputEventMouseMotion:
		# Lets the user pan around the World.
		if Input.is_action_pressed("pan"):
			#$Camera2D.position += event.velocity * -mouse_sen
			$Camera2D.position += event.relative * -mouse_sen
	
	# Lets the player draw and erase cells:
	if Input.is_action_pressed("draw"):
		set_cell(0, local_to_map(get_local_mouse_position()), 0, Vector2i(0, 0))
	elif Input.is_action_pressed("erase"):
		erase_cell(0, local_to_map(get_local_mouse_position()))

func _process(
	## The time since the last frame.
	delta: float
) -> void:
	pass

func _ready() -> void:
	# Puts the Camera2D at the center of the viewport.
	$Camera2D.offset = get_viewport().size / 2
	
	$Timer.wait_time = delay_time
	$GUI/Control/DelayText.text = str(delay_time)
	
	# Sets the default rules for keeping a living cell alive.
	for i: int in rules[0]:
		$GUI/Control/AliveRuleItems.select(i - 1, false)
		
	# Sets the default rule for bringing a dead cell to life.
	for i: int in rules[1]:
		$GUI/Control/DeadRuleItems.select(i - 1, false)
	
## Makes the next generation in the game.
func make_generation() -> void:
	$WorldUpdate.clear()
	
	## An array of all World positions that have a living cell.
	var living_cells: Array[Vector2i] = get_used_cells(0)
	## An array of all World positions that will have the rules applied to them.
	var cells_to_process: Dictionary
	
	# Iterates over all of the living cells and adds their neighbors to cells_to_process.
	for living_cell_pos: Vector2i in living_cells:
		cells_to_process[living_cell_pos] = null
		
		# Iterates over all of the neighboring cell positions in a clockwise order.
		for neighbor_pos: Vector2i in [
			# Top left cell.
			Vector2i(-1, -1),
			# Top cell.
			Vector2i(0, -1),
			# Top right cell.
			Vector2i(1, -1),
			# Right cell.
			Vector2i(1, 0),
			# Bottom right cell.
			Vector2i(1, 1),
			# Bottom cell.
			Vector2i(0, 1),
			# Bottom left cell.
			Vector2i(-1, 1),
			# Left cell.
			Vector2i(-1, 0)
		]:
			cells_to_process[living_cell_pos + neighbor_pos] = null
	
	# Iterates over all of the cells which may need to be updated, applying the rules to them.
	for cell_pos: Vector2i in cells_to_process:
		## The number of living cells around it (the 8 neighboring cells).
		var neighbor_count = count_neighbors(cell_pos)
		
		# Applies the rules to a cell, determining whether it lives or dies. The executioner.
		apply_rules(cell_pos, neighbor_count)
	
	# Iterate over all of the same cells again, but they're now just copied from WorldUpdate to
	# World.
	for cell_pos: Vector2i in cells_to_process:
		## Holds whether a cell from WorldUpdate is dead or alive.
		var cell_update_status: Vector2i = $WorldUpdate.get_cell_atlas_coords(0, cell_pos)
		
		# Copies a cell from WorldUpdate to World, but only if it's alive.
		if cell_update_status != Vector2i(-1, -1):
			set_cell(0, cell_pos, 0, cell_update_status)
		else:
			erase_cell(0, cell_pos)

## Counts the number of living cells around func_cell.
func count_neighbors(
	## Tilemap coords for the cell to count the neighbors of.
	cell_pos: Vector2i
) -> int:
	var neighbor_count: int = 0
	
	# Iterates over all of the neighboring cell positions in a clockwise order.
	for neighbor_pos: Vector2i in [
		# Top left cell.
		Vector2i(-1, -1),
		# Top cell.
		Vector2i(0, -1),
		# Top right cell.
		Vector2i(1, -1),
		# Right cell.
		Vector2i(1, 0),
		# Bottom right cell.
		Vector2i(1, 1),
		# Bottom cell.
		Vector2i(0, 1),
		# Bottom left cell.
		Vector2i(-1, 1),
		# Left cell.
		Vector2i(-1, 0)
	]:
		# If the neighbor is living, then increase the neighbor count.
		if get_cell_atlas_coords(0, cell_pos + neighbor_pos) != Vector2i(-1, -1):
			neighbor_count += 1
	
	return neighbor_count

## Applies the rules of Conway's Game of Life to a cell. The (default) rules are this: First, if a
## living cell has 2 or 3 neighbors, then it survives. Second, if a dead cell has 3 neighbors, then
## it comes to life.
func apply_rules(
	## Tilemap coords for the cell to count the neighbors of.
	cell_pos: Vector2i,
	## The number of living neighbors that the cell has.
	neighbor_count: int
) -> void:
	# Rule for living cells:
	if get_cell_atlas_coords(0, cell_pos) != Vector2i(-1, -1):
		for n: int in rules[0]:
			if n == neighbor_count:
				$WorldUpdate.set_cell(0, cell_pos, 0, Vector2i(0, 0))
	# Rule for dead cells:
	else:
		for n: int in rules[1]:
			if n == neighbor_count:
				$WorldUpdate.set_cell(0, cell_pos, 0, Vector2i(0, 0))

## The Timer is used to pace how quickly generations are made.
func _on_timer_timeout() -> void:
	make_generation()

## PlayButton is used to start and pause generation creation.
func _on_check_button_toggled(
	## State of the button currently.
	toggled_on: bool
) -> void:
	if toggled_on:
		$Timer.start($Timer.wait_time)
	else:
		$Timer.stop()

## EraseButton is used to erase all cells in the World.
func _on_erase_button_pressed() -> void:
	clear()

## DelayText is used to set the time between generations.
func _on_delay_text_text_submitted(new_text: String) -> void:
	$Timer.wait_time = float(new_text)

## Updates the rules for living cells based on what AliveRuleItems items were clicked.
func _on_alive_rule_items_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	rules[0].clear()
	
	for n: int in $GUI/Control/AliveRuleItems.get_selected_items():
		rules[0].append(n + 1)

## Updates the rules for dead cells based on what DeadRuleItems items were clicked.
func _on_dead_rule_items_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	rules[1].clear()
	
	for n: int in $GUI/Control/DeadRuleItems.get_selected_items():
		rules[1].append(n + 1)
