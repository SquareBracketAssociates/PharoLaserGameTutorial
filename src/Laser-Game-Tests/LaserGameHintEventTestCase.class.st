"
I check the part of the hint behaviour that belongs to Bloc rather than to the game: which events a cell element is given when the pointer moves quickly, and what is left on the board afterwards.

Pages 116 and 117 of the original chase ghost rotation arrows. Their cause is that mouse moves are samples: the cursor can cross a cell without the game ever being told, and the cell then keeps the arrow that was drawn onto the shared board form. My tests run in a real, headless space, so the enter and leave events come from the Bloc mouse processor instead of from a test, and they show that a cell the pointer has left keeps no arrow — neither when the pointer jumped over the cells in between, nor when it left the board entirely.

I take my space from `BlParameterizedHostTest`, which opens it on a headless host and closes it again after each test.
"
Class {
	#name : 'LaserGameHintEventTestCase',
	#superclass : 'BlParameterizedHostTest',
	#instVars : [
		'board'
	],
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'accessing' }
LaserGameHintEventTestCase >> cellElementsShowingAHint [
	"Answer the cell elements of my board that hold a hint arrow."

	^ board children select: [ :each | each hintElement notNil ]
]

{ #category : 'accessing' }
LaserGameHintEventTestCase >> positionInCellAt: aGridLocation offset: aPoint [
	"Answer the position in space coordinates of the point aPoint of the cell at aGridLocation.
	The event simulator speaks in space coordinates; a renderer and a click region speak in the
	coordinates of one cell, which is what aPoint is in."

	^ (board cellElementAt: aGridLocation) bounds inSpace bounds origin + aPoint
]

{ #category : 'running' }
LaserGameHintEventTestCase >> setUp [
	"Open a headless space on a board of the demo grid. The space is what makes the mouse
	processor of Bloc deliver the enter and leave events my tests rely on."

	| aSpace |
	super setUp.
	board := LaserGameBoardElement on: GridExample demoGrid.
	aSpace := self newTestingSpace.
	aSpace root addChild: board.
	aSpace settle
]

{ #category : 'tests' }
LaserGameHintEventTestCase >> testMovingOffTheBoardClearsTheArrow [
	"The pointer leaves the board entirely, so no cell is entered next. Bloc sends the leave of the
	cell under the pointer whatever is under it afterwards, so the arrow goes and the board hovers
	nothing."

	board eventSimulator mouseMoveAt:
		(self positionInCellAt: 4 @ 1 offset: CellClickRegionInside regionRectangle center).
	self assert: (board cellElementAt: 4 @ 1) hintElement notNil.
	board eventSimulator mouseMoveAt: board bounds inSpace bounds bottomRight + (20 @ 20).
	self assert: self cellElementsShowingAHint isEmpty.
	self assert: board hoveredCellElement isNil
]

{ #category : 'tests' }
LaserGameHintEventTestCase >> testMovingQuicklyToADistantCellLeavesNoArrowBehind [
	"Move the pointer quickly and whole cells are skipped: the game hears about one cell and then
	about a distant one, with nothing in between. Here those two moves are the only ones the space
	is given, and the mirror that was left keeps no arrow."

	| first second |
	first := board cellElementAt: 4 @ 1.
	second := board cellElementAt: 1 @ 2.
	board eventSimulator mouseMoveAt:
		(self positionInCellAt: 4 @ 1 offset: CellClickRegionInside regionRectangle center).
	self assert: first hintElement notNil.
	board eventSimulator mouseMoveAt:
		(self positionInCellAt: 1 @ 2 offset: CellClickRegionInside regionRectangle center).
	self assert: first hintElement isNil.
	self assert: second hintElement notNil.
	self assert: self cellElementsShowingAHint asArray equals: { second }
]
