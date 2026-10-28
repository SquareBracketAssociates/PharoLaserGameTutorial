"
I am the game board: the element that shows every cell of one grid.

I hold a grid and one child element per cell of it, built by the CellRenderer of each cell. A BlGridLayout places those children, one column per grid column, so a cell never computes where it sits.

`LaserGameBoardElement class >> extentForGrid:` answers the size a board of a given grid takes, because a window still has to be given a size. Nothing depends on it internally: I take the size of my cells through fitContent constraints, and cell borders are painted inside the cells, so they cost no space.

I also hold what the mouse is doing to my cells. Each cell element handles its own mouse events and tells me: `hoverCellElement:` and `unhoverCellElement:` keep `hoveredCellElement` current, `clickCellElement:` records `clickedCell`, and `moveMade` says that a click changed the grid. So `hoveredCell` answers the cell under the pointer without any arithmetic: the pointer is over a cell when that cell's own element says so.

`moveMade` draws my cells again and then evaluates `moveAction`, which is how the game hears that its counters are out of date. Nothing is registered there when I am opened on my own.

`LaserGameBoardElement openOn:` opens a board on any grid in a space of its own. The one-click openers of the fixed board live in the examples package.

Instance variables:
	grid	<Grid>	the model I show; setting it rebuilds my children
	hoveredCellElement	<LaserGameCellElement>	the cell element under the pointer, nil when the pointer is off the board
	clickedCell	<Cell>	the cell of the last click, nil until a cell is clicked
	moveAction	<BlockClosure>	evaluated after a move, nil when nobody listens
"
Class {
	#name : 'LaserGameBoardElement',
	#superclass : 'BlElement',
	#instVars : [
		'grid',
		'hoveredCellElement',
		'clickedCell',
		'moveAction'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'geometry' }
LaserGameBoardElement class >> extentForGrid: aGrid [
	"Answer the extent a board showing aGrid occupies. Cells are laid out edge to edge and
	their borders are painted inside them, so the borders add nothing to this."

	^ CellRenderer cellExtent
	  * (aGrid numberOfColumns @ aGrid numberOfRows)
]

{ #category : 'instance creation' }
LaserGameBoardElement class >> on: aGrid [
	"Answer a board element showing aGrid."

	| element |
	element := self new.
	element grid: aGrid.
	^ element
]

{ #category : 'instance creation' }
LaserGameBoardElement class >> openOn: aGrid [
	"Open a space showing aGrid and answer it. The space is sized from the grid.

	LaserGameBoardElement openOn: GridFactory defaultGrid"

	| space |
	space := BlSpace new.
	space extent: (self extentForGrid: aGrid).
	space title: 'Laser Game'.
	space root addChild: (self on: aGrid).
	space show.
	^ space
]

{ #category : 'constants' }
LaserGameBoardElement class >> shadowOffset [
	"Answer how far the board casts its shadow, in pixels: three down and three to the right."

	^ 3 @ 3
]

{ #category : 'accessing' }
LaserGameBoardElement >> cellElementAt: aPoint [
	"Answer the element showing the cell at aPoint, x being the column and y the row."

	| index |
	index := aPoint y - 1 * self grid numberOfColumns + aPoint x.
	^ self children at: index
]

{ #category : 'interaction' }
LaserGameBoardElement >> clickCellElement: aCellElement [
	"Record the cell of aCellElement as the one just clicked. A cell tells me this when a click
	lands on it, that is when a press and a release fall in the same cell."

	clickedCell := aCellElement cell
]

{ #category : 'accessing' }
LaserGameBoardElement >> clickedCell [
	"Answer the cell of the last click, or nil while no cell has been clicked. Nothing acts on the
	click yet: the click regions decide what a click does from *Determine Push Regions* on."

	^ clickedCell
]

{ #category : 'accessing' }
LaserGameBoardElement >> grid [
	"Answer the grid I show."

	^ grid
]

{ #category : 'accessing' }
LaserGameBoardElement >> grid: aGrid [
	"Show aGrid. Setting the grid rebuilds the cells, so the same board can show another game."

	grid := aGrid.
	self rebuildCells
]

{ #category : 'interaction' }
LaserGameBoardElement >> hoverCellElement: aCellElement [
	"Remember that the pointer is over aCellElement. A cell tells me this when the pointer enters
	it and while it moves inside it. The cell I hovered before loses its hint here: mouse moves
	arrive as samples, so a cell the pointer crossed quickly is never told that it was left. One
	cell can hold a hint at a time, so clearing the previous one is this single line."

	hoveredCellElement == aCellElement ifTrue: [ ^ self ].
	hoveredCellElement ifNotNil: [ :each | each clearPositionHint ].
	hoveredCellElement := aCellElement
]

{ #category : 'accessing' }
LaserGameBoardElement >> hoveredCell [
	"Answer the cell the pointer is over, or nil when the pointer is off the board. No arithmetic
	is needed: the cell element under the pointer knows which cell it shows."

	^ hoveredCellElement ifNotNil: [ :element | element cell ]
]

{ #category : 'accessing' }
LaserGameBoardElement >> hoveredCellElement [
	"Answer the cell element the pointer is over, or nil when the pointer is off the board."

	^ hoveredCellElement
]

{ #category : 'initialization' }
LaserGameBoardElement >> initialize [
	"A board lays its cells out in a grid, one column per grid column, and takes exactly the
	size of the cells it holds. It casts a shadow down and to the right, which is an element
	effect: Alexandrie draws it under the board, and it costs no layout space."

	super initialize.
	self background: LaserGameColors gameBoardBackgroundColor.
	self effect: (BlSimpleShadowEffect
			 color: LaserGameColors boardShadowColor
			 offset: self class shadowOffset).
	self layout: BlGridLayout horizontal.
	self constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ]
]

{ #category : 'interaction' }
LaserGameBoardElement >> moveMade [
	"A move was made on one of my cells. Every cell is drawn again, and whoever asked to hear
	about moves is told. The counters belong to the panel and not to me, so I announce the move
	instead of reaching for them, and a board opened on its own still works."

	self redrawCells.
	moveAction ifNotNil: [ :anAction | anAction value ]
]

{ #category : 'private' }
LaserGameBoardElement >> rebuildCells [
	"Replace my children with one element per cell of my grid, row by row. The grid layout
	places them, so no cell has to work out where it is on a shared surface."

	self removeChildren.
	self layout columnCount: self grid numberOfColumns.
	1 to: self grid numberOfRows do: [ :row |
		1 to: self grid numberOfColumns do: [ :column |
			| location |
			location := column @ row.
			self addChild: (CellRenderer
					 rendererFor: (self grid at: location)
					 grid: self grid) newElement ] ]
]

{ #category : 'drawing' }
LaserGameBoardElement >> redrawCells [
	"Draw every cell again. One action on one cell changes more than that cell: a turned mirror
	sends the beam somewhere else, and a pushed mirror leaves its old place empty, so nothing
	tries to work out which cells are affected."

	self children do: [ :each | each redraw ]
]

{ #category : 'interaction' }
LaserGameBoardElement >> unhoverCellElement: aCellElement [
	"Forget the pointer position, but only when aCellElement is the cell I hover. Moving from
	one cell to the next can deliver the enter of the new cell before the leave of the old one."

	hoveredCellElement == aCellElement ifTrue: [ hoveredCellElement := nil ]
]

{ #category : 'interaction' }
LaserGameBoardElement >> whenMoveMadeDo: aBlock [
	"Evaluate aBlock after every move made on one of my cells."

	moveAction := aBlock
]
