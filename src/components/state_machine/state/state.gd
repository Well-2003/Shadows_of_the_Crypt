class_name State
extends Node
## Base state, inherited by every concrete state.
##
## Holds shared functionality used by all states managed by a [StateMachine].


var state_machine: StateMachine = null
var context: Node = null


## Initializes the state with its owning [param new_context].
func init(new_context: Node) -> void:
	context = new_context


## Runs when the state is entered.
func enter() -> void:
	pass


## Runs when the state is exited.
func exit() -> void:
	pass


## Runs every frame. Return a [State] to transition, or null to stay.
func update() -> State:
	return null


## Runs every physics frame. Return a [State] to transition, or null to stay.
func physics_update() -> State:
	return null


## Runs on unhandled input. Return a [State] to transition, or null to stay.
func input() -> State:
	return null
