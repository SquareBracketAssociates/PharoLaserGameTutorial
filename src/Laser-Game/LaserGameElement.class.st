"
I am the whole game on the screen: a control panel on the left, a board on the right, and a margin around both. Under the board stands a bar the width of one cell, marking the square the laser comes in through.

I hold a `LaserGameBoardElement` and a `LaserGameControlPanelElement`, and I take my size from them, the panel width and the margin. The colour behind them all is the ramp of `LaserGameColors windowColorRamp`.

```
LaserGameElement openOn: GridFactory defaultGrid
LaserGameElement openRandomOfExtent: 12@12
```

I also count the moves the player makes, and I can start a new game on a randomized grid. I ask before quitting: a `LaserGameConfirmElement` is laid over me, since a Bloc element cannot stop and wait for an answer.

I play on the grid I am given, of any size. The board is one element per location, the panel keeps its width and takes the height of the board, and my own size follows both, so nothing but the grid decides how big the game is.

Instance variables:
- `grid`: the grid played on. Setting it rebuilds what I hold.
- `board`: the `LaserGameBoardElement` showing that grid.
- `controlPanel`: the panel beside it, holding the buttons and the counters.
- `moves`: how many moves have been made on the board.
- `confirmation`: the question laid over me, nil while none is asked.
- `laserHome`: the bar under the board marking where the laser enters it.

I know nothing about the rules. The grid answers those.
"
Class {
	#name : 'LaserGameElement',
	#superclass : 'BlElement',
	#instVars : [
		'grid',
		'board',
		'controlPanel',
		'moves',
		'confirmation',
		'laserHome'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'accessing' }
LaserGameElement class >> extentForGrid: aGrid [
	"Answer the extent a game showing aGrid occupies: the board, the control panel beside it, and
	one margin on each side. The height is the taller of the board and the panel, since a board of
	few rows is shorter than everything the panel holds."

	^ (LaserGameBoardElement extentForGrid: aGrid) x + self panelWidth
	  @ (LaserGameControlPanelElement heightForGrid: aGrid)
	  + (2 * self gameMargin)
]

{ #category : 'accessing' }
LaserGameElement class >> gameMargin [
	"Answer the margin, in pixels, between the edge of the game and what it holds."

	^ 10
]

{ #category : 'constants' }
LaserGameElement class >> laserHomeExtent [
	"Answer the size, in pixels, of the bar marking where the laser enters the board: one cell
	wide and one margin tall."

	^ CellRenderer cellExtent x @ self gameMargin
]

{ #category : 'instance creation' }
LaserGameElement class >> on: aGrid [
	"Answer a game element playing on aGrid."

	| element |
	element := self new.
	element grid: aGrid.
	^ element
]

{ #category : 'instance creation' }
LaserGameElement class >> onRandomOfExtent: aPoint [
	"Answer a game on a freshly dealt board of aPoint columns by aPoint rows. Dealing the board is
	all this does; #on: is what builds a game around a grid."

	^ self on: (GridFactory randomizedGridOfExtent: aPoint)
]

{ #category : 'instance creation' }
LaserGameElement class >> openOn: aGrid [
	"Open a space showing a game on aGrid and answer it. The space starts at the size the game is
	drawn at, and the game follows it from there: a window the player resizes scales the game to
	match.

	LaserGameElement openOn: GridFactory defaultGrid"

	| space element |
	space := BlSpace new.
	element := self on: aGrid.
	space extent: (self extentForGrid: aGrid).
	space title: 'Laser Game'.
	space root addChild: element.
	space root
		addEventHandlerOn: BlElementExtentChangedEvent
		do: [ :anEvent | element fitIn: space root extent ].
	element fitIn: space extent.
	space show.
	^ space
]

{ #category : 'instance creation' }
LaserGameElement class >> openRandomOfExtent: aPoint [
	"Open a game on a freshly dealt board of aPoint columns by aPoint rows and answer the space.

	LaserGameElement openRandomOfExtent: 8@10"

	^ self openOn: (GridFactory randomizedGridOfExtent: aPoint)
]

{ #category : 'constants' }
LaserGameElement class >> panelWidth [
	"Answer the width, in pixels, of the control panel beside the board: exactly two buttons and
	the three gaps a row of two stands in. That identity is what makes a row of two fill the panel
	and a row of three not fit, so the panel is stated from the buttons rather than beside them."

	^ (2 * LaserGameControlPanelElement buttonWidth)
	  + (3 * LaserGameControlPanelElement buttonGap)
]

{ #category : 'accessing' }
LaserGameElement class >> windowBackgroundPaint [
	"Answer the paint behind the whole game: the window ramp, running in the direction
	`LaserGameColors windowColorRampDirection` gives. An element takes one paint, so the ramp is
	the whole of it; `LaserGameColors gameWindowColor` stays for whatever needs a single color."

	^ BlLinearGradientPaint new
		  stops: LaserGameColors windowColorRamp;
		  start: 0 @ 0;
		  end: LaserGameColors windowColorRampDirection;
		  yourself
]

{ #category : 'actions' }
LaserGameElement >> ask: aString onConfirm: aBlock [
	"Lay the question aString over me, and evaluate aBlock if the player answers yes. Either answer
	takes the question off first. One question is asked at a time, so a second click on Quit while
	the question stands does nothing."

	| question |
	self confirmation ifNotNil: [ ^ self ].
	question := LaserGameConfirmElement asking: aString.
	question extent: (self class extentForGrid: self grid).
	question whenAnsweredDo: [ :answer |
		self dismissQuestion.
		answer ifTrue: [ aBlock value ] ].
	confirmation := question.
	self addChild: question
]

{ #category : 'accessing' }
LaserGameElement >> board [
	"Answer the element showing the board."

	^ board
]

{ #category : 'actions' }
LaserGameElement >> close [
	"Close the game, by closing the space it is shown in."

	self space ifNotNil: [ :aSpace | aSpace close ]
]

{ #category : 'accessing' }
LaserGameElement >> confirmation [
	"Answer the question laid over me, or nil while none is asked."

	^ confirmation
]

{ #category : 'accessing' }
LaserGameElement >> controlPanel [
	"Answer the panel beside the board. It is empty until the controls are added."

	^ controlPanel
]

{ #category : 'actions' }
LaserGameElement >> dismissQuestion [
	"Take the question off me. Answering does this, whichever answer it was."

	confirmation ifNil: [ ^ self ].
	self removeChild: confirmation.
	confirmation := nil
]

{ #category : 'geometry' }
LaserGameElement >> fitIn: anExtent [
	"Scale the game to a window of anExtent and centre it there. Scaling costs nothing here,
	because every cell is drawn from geometries rather than from a bitmap. A window of no size is
	left alone, since a space announces one while it opens."

	(anExtent x > 0 and: [ anExtent y > 0 ]) ifFalse: [ ^ self ].
	self transformDo: [ :aBuilder |
		aBuilder
			topLeftOrigin;
			scaleBy: (self scaleToFitIn: anExtent) ].
	self position: (self positionToCenterIn: anExtent)
]

{ #category : 'accessing' }
LaserGameElement >> grid [
	"Answer the grid the game plays on. A game built with no grid at all plays the standard board
	of eight columns by ten rows, so that `LaserGameElement new` answers something worth looking
	at. The board is dealt when it is first asked for, so a game that is given a grid never deals
	one it would throw away."

	^ grid ifNil: [
		  self grid: GridFactory defaultGrid.
		  grid ]
]

{ #category : 'accessing' }
LaserGameElement >> grid: aGrid [
	"Play on aGrid. Setting the grid rebuilds what I hold, so the same game element can show
	another grid."

	grid := aGrid.
	self rebuild
]

{ #category : 'updating' }
LaserGameElement >> incrementMoves [
	"Count one more move."

	self moves: self moves + 1
]

{ #category : 'initialization' }
LaserGameElement >> initialize [
	"A game is a row of two: the control panel, and the board beside it. The margin around both is
	padding, and the ramp behind them shows through it. There is none at the bottom: the mark of
	the laser's home stands in that band, so the bottom margin belongs to the panel and to the
	board column, and they carry it as a margin instead. No move has been made yet."

	super initialize.
	self background: self class windowBackgroundPaint.
	self layout: BlLinearLayout horizontal.
	self padding: (BlInsets
			 top: self class gameMargin
			 left: self class gameMargin
			 bottom: 0
			 right: self class gameMargin).
	moves := 0
]

{ #category : 'accessing' }
LaserGameElement >> laserHome [
	"Answer the bar that marks where the laser enters the board."

	^ laserHome
]

{ #category : 'accessing' }
LaserGameElement >> laserIsActive [
	"Answer whether the laser is firing. The grid knows; I only ask."

	^ self grid laserIsActive
]

{ #category : 'updating' }
LaserGameElement >> moveMade [
	"A move was made on my board: count it, and set the counters. The board has already drawn its
	cells by the time it tells me, so nothing else is left to do."

	self incrementMoves.
	self controlPanel updateCounters
]

{ #category : 'accessing' }
LaserGameElement >> moves [
	"Answer how many moves the player has made. Every click on the board counts, and the player is
	meant to solve the puzzle in as few as possible."

	^ moves
]

{ #category : 'accessing' }
LaserGameElement >> moves: anInteger [
	"Say that anInteger moves have been made."

	moves := anInteger
]

{ #category : 'geometry' }
LaserGameElement >> naturalExtent [
	"Answer the extent the game is drawn at: the board, the panel and the margins, in pixels. The
	window can be any size; this one is the size the drawing is scaled from."

	^ self class extentForGrid: self grid
]

{ #category : 'initialization' }
LaserGameElement >> newBoardColumn [
	"Answer the column standing where the board stands: the board itself, and under its first
	column of cells the bar marking where the laser enters. The bar is the last child, so it
	falls under the bottom row, and it is as tall as my bottom margin, which is why I have no
	bottom padding: the column ends where I end and the bar fills the band under the board."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: BlLinearLayout vertical.
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ].
	column addChild: board.
	column addChild: laserHome.
	^ column
]

{ #category : 'initialization' }
LaserGameElement >> newControlPanel [
	"Answer the control panel: the fixed-width column of buttons that sits beside the board."

	^ LaserGameControlPanelElement on: self
]

{ #category : 'actions' }
LaserGameElement >> newGame [
	"Start again on a fresh random grid. The stack of moves the grid keeps is left alone: it is
	emptied where Undo and Reset are added."

	self grid initializeCells.
	self grid stopLaser.
	self moves: 0.
	GridFactory randomizeGrid: self grid.
	self refresh
]

{ #category : 'initialization' }
LaserGameElement >> newLaserHome [
	"Answer the bar that marks where the laser comes from: one cell wide, one margin tall, in the
	colour the beam splatters the board with. An element with a background is the whole of it, and
	it scales with the rest of the game."

	^ BlElement new
		  background: LaserGameColors laserBeamSplatterColor;
		  extent: self class laserHomeExtent;
		  yourself
]

{ #category : 'geometry' }
LaserGameElement >> positionToCenterIn: anExtent [
	"Answer where the scaled game sits in a window of anExtent: in the middle of it, with the
	leftover of the looser direction split between the two sides."

	^ (anExtent - (self naturalExtent * (self scaleToFitIn: anExtent))) / 2
]

{ #category : 'actions' }
LaserGameElement >> quit [
	"Ask before closing. Quit sits next to Fire and is easy to hit by accident. A Bloc element
	cannot stop and wait for an answer, so the question is laid over the game and answers back."

	self ask: 'Are you sure you want to quit?' onConfirm: [ self close ]
]

{ #category : 'initialization' }
LaserGameElement >> rebuild [
	"Replace what I hold with a control panel for me and a board showing my grid beside it, and
	take the size the two of them and my margins need. The panel is added first, so it stands to
	the left of the board. The board tells me when a move changed the grid, so the counters follow
	a click as well as the fire button. The board goes in inside a column that also holds the mark
	of the laser's home, and the panel carries the bottom margin that mark stands in."

	self removeChildren.
	confirmation := nil.
	board := LaserGameBoardElement on: self grid.
	laserHome := self newLaserHome.
	controlPanel := self newControlPanel.
	controlPanel margin: (BlInsets bottom: self class gameMargin).
	self addChild: controlPanel.
	self addChild: self newBoardColumn.
	board whenMoveMadeDo: [ self moveMade ].
	self extent: (self class extentForGrid: self grid)
]

{ #category : 'updating' }
LaserGameElement >> refresh [
	"Show what the model says now: redraw the cells, put the right label on the fire button and
	set the counters."

	self board rebuildCells.
	self controlPanel updateFireButtonLabel.
	self controlPanel updateCounters
]

{ #category : 'actions' }
LaserGameElement >> reset [
	"Put the board back where the game started: unwind the whole undo stack, stop the laser and
	set the move count to zero."

	self grid reset.
	self grid stopLaser.
	self moves: 0.
	self refresh
]

{ #category : 'geometry' }
LaserGameElement >> scaleToFitIn: anExtent [
	"Answer how much the game has to be scaled by to fill a window of anExtent without changing
	its shape: the tighter of the two directions, so the whole board stays in view and the cells
	stay square."

	| natural |
	natural := self naturalExtent.
	^ ((anExtent x / natural x) min: (anExtent y / natural y)) asFloat
]

{ #category : 'actions' }
LaserGameElement >> toggleLaser [
	"Fire the laser, or stop it if it is already firing, and show the result. This is what the fire
	button does."

	self laserIsActive
		ifTrue: [ self grid stopLaser ]
		ifFalse: [ self grid fireLaser ].
	self refresh
]

{ #category : 'actions' }
LaserGameElement >> undo [
	"Take the last move back, and count the undo as a move of its own: an undo must not remove any
	count from the player's total, so the counter goes up, not down. The grid answers whether it
	undid anything, and on an empty stack there is nothing to draw again."

	self grid undo ifFalse: [ ^ self ].
	self incrementMoves.
	self refresh
]
