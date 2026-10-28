"
I offer boards to open on their own, without a control panel around them.

Each of my examples opens a window on a `LaserGameBoardElement` and answers the `BlSpace` it opened, which is how the earlier chapters look at the board before there is a game to put it in.
"
Class {
	#name : 'LaserGameBoardExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
LaserGameBoardExample class >> openExample [
	"Open the demo grid of the tests, which holds mirrors and a target.
	LaserGameBoardExample openExample"

	<sampleInstance>
	^ LaserGameBoardElement openOn: GridExample demoGrid
]

{ #category : 'examples' }
LaserGameBoardExample class >> openExampleWithLaserFired [
	"Open the demo grid with the laser already fired, which lights the target and draws the beam
	over the blank cells it crosses.
	LaserGameBoardExample openExampleWithLaserFired"

	<sampleInstance>
	| grid |
	grid := GridExample demoGrid.
	grid fireLaser.
	^ LaserGameBoardElement openOn: grid
]
