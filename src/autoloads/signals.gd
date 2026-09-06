extends Node
## Autoload signal bus.
##
## Holds the global signals of the game, so nothing has to reach into another
## node to find out that something happened.


## This is a signal example for demonstration purposes.
@warning_ignore("unused_signal")
signal signal_example

## Emitted when an enemy dies, for the kill counter, the XP and the coin drop.
@warning_ignore("unused_signal")
signal enemy_died(villain_data: VillainClassData)
