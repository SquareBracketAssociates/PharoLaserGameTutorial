"
I offer whole games to open.

Each of my examples opens a window on a board and answers the `BlSpace` it opened, so a playground can keep the handle and reach the game inside it: `space root children first`.
From there `grid` gives the board the inspector tabs of the rules live on.
"
Class {
	#name : 'LaserGameElementExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
LaserGameElementExample class >> openExample [
	"Open the demo grid of the tests: the five by five board with ten mirrors and one target.
	LaserGameElementExample openExample"

	<sampleInstance>
	^ LaserGameElement openOn: GridExample demoGrid
]

{ #category : 'examples' }
LaserGameElementExample class >> openStandardExample [
	"Open the standard board: eight columns by ten rows, dealt. The demo board of #openExample is
	the five by five one the earlier chapters play on.
	LaserGameElementExample openStandardExample"

	<sampleInstance>
	^ LaserGameElement openOn: GridFactory defaultGrid
]
