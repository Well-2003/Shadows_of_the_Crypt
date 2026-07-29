class_name StateMachine
extends Node
## Handles changing and managing states.
##
## Holds child [State] nodes, manages transitions between them, and forwards
## per-frame/physics/input updates to the current state.


var current_state: State = null
## Owner for this state machine.
var context: Node = null


## Initializes the state machine and all children.
func init(new_context: Node, new_state: State) -> void:
	context = new_context

	for child: State in get_children():
		child.init(context)

	change_state(new_state)


## Will transition states.
func change_state(new_state: State) -> void:
	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()


## Will update every frame.
func update() -> void:
	var new_state: State = current_state.update()
	if new_state:
		change_state(new_state)


## Will update every physics tick.
func physics_update() -> void:
	var new_state: State = current_state.physics_update()
	if new_state:
		change_state(new_state)


## Will be called when user executes one action.
func input() -> void:
	var new_state: State = current_state.input()
	if new_state:
		change_state(new_state)
