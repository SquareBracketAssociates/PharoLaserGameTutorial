"
I am the model of the whole board: a dictionary of `Cell`s keyed by `column @ row` points, `numberOfColumns` of them across and `numberOfRows` down, plus the state of the laser. Every location holds a cell; `BlankCell` fills the empty ones.

`fireLaser` lights the cells the beam crosses and `stopLaser` clears them again. The beam is `laserBeamPath`, an ordered collection of `LaserPathElement`s built by `calculatePath`, which walks from `startingCell` until the beam stops. `movesStack` records the player's moves so `undo` can take them back.

Cells are moved with the `pushCell...FromLocation:` methods, each guarded by its `canPushCell...FromLocation:`, and mirrors are turned with `rotateCellClockwiseAt:` and `rotateCellCounterClockwiseAt:`. Inspect me for a picture of the board and a list of the beam path.
"
Class {
	#name : 'Grid',
	#superclass : 'Object',
	#instVars : [
		'cells',
		'laserIsActive',
		'numberOfColumns',
		'numberOfRows',
		'laserBeamPath',
		'movesStack'
	],
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'instance creation' }
Grid class >> newOfSize: aPoint [
	| model |
	model := self basicNew.
	model
		numberOfRows: aPoint y;
		numberOfColumns: aPoint x.
	model initialize.
	^model
]

{ #category : 'action' }
Grid >> activateCellsInPath [
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe activateCell]
]

{ #category : 'accessing' }
Grid >> at: aPoint [
	"Answer the cell at aPoint, a column @ row location, or nil when I hold no cell there."

	^self cells at: aPoint ifAbsent: []
]

{ #category : 'accessing' }
Grid >> at: aPoint put: aCell [
	"Put aCell at aPoint, a column @ row location, and tell the cell where it now sits."

	aCell gridLocation: aPoint.
	self cells at: aPoint put: aCell
]

{ #category : 'action' }
Grid >> calculatePath [
	| cell dirSym element next |
	self laserBeamPath: OrderedCollection new.
	cell := self startingCell.
	dirSym := #south.
	element := LaserPathElement cell: cell entrySide: dirSym.
	[self laserBeamPath addLast: element.
	next := element nextElementIn: self.
	next isNil] whileFalse: [
		element := next]
]

{ #category : 'action' }
Grid >> canPushCell: aGridDirection fromLocation: aPoint [
	"Answer whether the cell at aPoint could be pushed one step in aGridDirection, without moving
	anything. The arrow drawn on a mirror asks this before any click, so that a push the rules
	refuse can be shown as refused. The three questions are the push rules themselves."

	| cell vector swapLoc swapCell |
	cell := self at: aPoint.
	cell class = MirrorCell ifFalse: [^false].
	vector := aGridDirection vector.
	swapLoc := aPoint + vector.
	swapCell := self at: swapLoc.
	swapCell isNil ifTrue: [^false].
	swapCell class = BlankCell ifFalse: [^false].
	^true

]

{ #category : 'action' }
Grid >> canPushCellEastFromLocation: aPoint [
	"Answer whether the cell at aPoint could be pushed one column to the right."

	| direction |
	direction := GridDirection directionFor: #east.
	^self canPushCell: direction fromLocation: aPoint.
]

{ #category : 'action' }
Grid >> canPushCellNorthFromLocation: aPoint [
	"Answer whether the cell at aPoint could be pushed one row up."

	| direction |
	direction := GridDirection directionFor: #north.
	^self canPushCell: direction fromLocation: aPoint.
]

{ #category : 'action' }
Grid >> canPushCellSouthFromLocation: aPoint [
	"Answer whether the cell at aPoint could be pushed one row down."

	| direction |
	direction := GridDirection directionFor: #south.
	^self canPushCell: direction fromLocation: aPoint.

]

{ #category : 'action' }
Grid >> canPushCellWestFromLocation: aPoint [
	"Answer whether the cell at aPoint could be pushed one column to the left."

	| direction |
	direction := GridDirection directionFor: #west.
	^self canPushCell: direction fromLocation: aPoint.
]

{ #category : 'accessing' }
Grid >> cells [
	"Answer the value of cells"

	^ cells
]

{ #category : 'accessing' }
Grid >> cells: anObject [
	"Set the value of cells"

	cells := anObject
]

{ #category : 'action' }
Grid >> clearCellsInPath [
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe clearCell]
]

{ #category : 'action' }
Grid >> fireLaser [
	self laserIsActive: true.
	self activateCellsInPath.
	
]

{ #category : 'initialization' }
Grid >> initialize [
	super initialize.
	self laserIsActive: false.
	self initializeCells.
	
]

{ #category : 'initialize-release' }
Grid >> initializeCells [
	self cells: Dictionary new.
	1 to: self numberOfColumns do: [:x |
		1 to: self numberOfRows do: [:y |
			| pt cell |
			pt := x@y.
			cell := BlankCell new.
			self at: pt put: cell]]
]

{ #category : 'inspecting' }
Grid >> inspectionBeam: aBuilder [
	"Show the path the laser takes, one row per step, which is the collection to read when the beam
	goes somewhere unexpected."

	<inspectorPresentationOrder: 2 title: 'Beam'>
	^ aBuilder newTable
		  items: (self laserBeamPath ifNil: [ #(  ) ]);
		  addColumn: (SpStringTableColumn title: 'Cell' evaluated: [ :each |
					   each cell printString ]);
		  addColumn:
			  (SpStringTableColumn title: 'Enters from' evaluated: [ :each |
					   each entrySide asString ]);
		  yourself
]

{ #category : 'inspecting' }
Grid >> inspectionBoard: aBuilder [
	"Show me as the board the player sees, drawn by the same element the game uses. A picture of
	the board is the quickest way to tell a model fault from a drawing fault."

	<inspectorPresentationOrder: 1 title: 'Board'>
	^ aBuilder newMorph
		  morph: (LaserGameBoardElement on: self) asPreviewMorph;
		  yourself
]

{ #category : 'inspecting' }
Grid >> inspectionCells: aBuilder [
	"Show one row per cell of me, in the order the board lays them out, with what the cell is and
	whether it is lit. Read it to catch a cell whose state disagrees with the beam: a target that
	says it is on while nothing reaches it shows up here at once."

	<inspectorPresentationOrder: 3 title: 'Cells'>
	| everyCell |
	everyCell := OrderedCollection new.
	1 to: self numberOfRows do: [ :row |
		1 to: self numberOfColumns do: [ :column |
			everyCell add: (self at: column @ row) ] ].
	^ aBuilder newTable
		  items: everyCell;
		  addColumn: (SpStringTableColumn title: 'Cell' evaluated: [ :each |
					   each printString ]);
		  addColumn: (SpStringTableColumn title: 'Lit' evaluated: [ :each |
					   each isOn
						   ifTrue: [ 'yes' ]
						   ifFalse: [ '' ] ]);
		  yourself
]

{ #category : 'inspecting' }
Grid >> inspectionMoves: aBuilder [
	"Show my undo stack, youngest move first: what was played, where the cell it was played on
	stands now, and the selector undo will send to take that move back. Read this tab when undo
	does something unexpected, because the move and its reversal sit side by side here."

	<inspectorPresentationOrder: 4 title: 'Moves'>
	^ aBuilder newTable
		  items: self movesStack reversed;
		  addColumn: (SpStringTableColumn title: 'Move' evaluated: [ :each | each key asString ]);
		  addColumn: (SpStringTableColumn title: 'Cell now at' evaluated: [ :each |
					   each value printString ]);
		  addColumn: (SpStringTableColumn title: 'Undo sends' evaluated: [ :each |
					   (ReverseLaserGameAction reverseActionSymbolFor: each key) asString ]);
		  yourself
]

{ #category : 'inspecting' }
Grid >> inspectionMovesContext: aContext [
	"Hide the Moves tab until something has been played, because an empty stack has nothing to
	say."

	aContext active: self movesStack isNotEmpty
]

{ #category : 'inspecting' }
Grid >> inspectionPushes: aBuilder [
	"Show one row per mirror on the board and ask the four push rules of each: a yes is a push the
	rules allow from where that mirror stands now. The arrows the player sees are drawn from these
	same four questions."

	<inspectorPresentationOrder: 5 title: 'Pushes'>
	| mirrors |
	mirrors := OrderedCollection new.
	1 to: self numberOfRows do: [ :row |
		1 to: self numberOfColumns do: [ :column |
			| location |
			location := column @ row.
			(self at: location) class = MirrorCell ifTrue: [ mirrors add: location ] ] ].
	^ aBuilder newTable
		  items: mirrors;
		  addColumn: (SpStringTableColumn title: 'Mirror' evaluated: [ :each | each printString ]);
		  addColumn: (SpStringTableColumn title: 'North' evaluated: [ :each |
					   self pushAnswerFor: GridDirectionNorth fromLocation: each ]);
		  addColumn: (SpStringTableColumn title: 'East' evaluated: [ :each |
					   self pushAnswerFor: GridDirectionEast fromLocation: each ]);
		  addColumn: (SpStringTableColumn title: 'South' evaluated: [ :each |
					   self pushAnswerFor: GridDirectionSouth fromLocation: each ]);
		  addColumn: (SpStringTableColumn title: 'West' evaluated: [ :each |
					   self pushAnswerFor: GridDirectionWest fromLocation: each ]);
		  yourself
]

{ #category : 'accessing' }
Grid >> laserBeamPath [
	"Answer the value of laserBeamPath"

	^ laserBeamPath
]

{ #category : 'accessing' }
Grid >> laserBeamPath: anObject [
	"Set the value of laserBeamPath"

	laserBeamPath := anObject
]

{ #category : 'accessing' }
Grid >> laserIsActive [
	"Answer the value of laserIsActive"

	^ laserIsActive
]

{ #category : 'accessing' }
Grid >> laserIsActive: anObject [
	"Set the value of laserIsActive"

	laserIsActive := anObject
]

{ #category : 'accessing' }
Grid >> movesStack [
	"Answer the stack of moves made on me, oldest first, built on first use. Each entry is an
	association of the symbol of a move and the location the move has to be undone from."

	movesStack isNil ifTrue: [self movesStack: OrderedCollection new].
	^movesStack
]

{ #category : 'accessing' }
Grid >> movesStack: aCollection [
	"Set the stack of moves made on me."

	movesStack := aCollection
]

{ #category : 'accessing' }
Grid >> numberOfActiveMirrors [
	"Answer how many of my mirror cells the beam lights. A mirror is lit once the beam has crossed
	it, so this is zero until the laser fires."

	^(self cells select: [:each | (each class = MirrorCell) and: [each isOn]]) size
]

{ #category : 'accessing' }
Grid >> numberOfColumns [
	numberOfColumns isNil ifTrue: [self numberOfColumns: 1].
	^ numberOfColumns
]

{ #category : 'accessing' }
Grid >> numberOfColumns: anObject [
	"Set the value of numberOfColumns"

	numberOfColumns := anObject
]

{ #category : 'accessing' }
Grid >> numberOfMirrors [
	"Answer how many mirror cells stand on my board, lit or not."

	^(self cells select: [:each | each class = MirrorCell]) size
]

{ #category : 'accessing' }
Grid >> numberOfRows [
	numberOfRows isNil ifTrue: [self numberOfRows: 1].
	^ numberOfRows
]

{ #category : 'accessing' }
Grid >> numberOfRows: anObject [
	"Set the value of numberOfRows"

	numberOfRows := anObject
]

{ #category : 'inspecting' }
Grid >> pushAnswerFor: aGridDirection fromLocation: aPoint [
	"Answer 'yes' when the rules allow the mirror at aPoint to be pushed in aGridDirection, and an
	empty string when they do not. The Pushes tab reads the rules through me."

	^ (self canPushCell: aGridDirection fromLocation: aPoint)
		  ifTrue: [ 'yes' ]
		  ifFalse: [ '' ]
]

{ #category : 'action' }
Grid >> pushCell: aGridDirection fromLocation: aPoint [
	"Push the cell at aPoint one step in aGridDirection and answer the cell that ended up where
	it started. Only a mirror cell moves, the target never does, and the move happens only when
	the neighbour in that direction is a blank cell, which includes there being a neighbour at
	all. Nothing is really pushed — the mirror and the blank trade places. The beam is taken off
	the board first and put back afterwards if the laser is on, as in rotateCellClockwiseAt:, so
	the cells lit before the push go dark and the new path lights up."

	| cell vector swapLoc swapCell |
	cell := self at: aPoint.
	cell class = MirrorCell ifFalse: [ ^ cell ].
	vector := aGridDirection vector.
	swapLoc := aPoint + vector.
	swapCell := self at: swapLoc.
	swapCell isNil ifTrue: [ ^ cell ].
	swapCell class = BlankCell ifFalse: [ ^ cell ].
	self clearCellsInPath.
	self swapCell: cell with: swapCell.
	self laserIsActive ifTrue: [ self activateCellsInPath ].
	^ swapCell
]

{ #category : 'action' }
Grid >> pushCellAction: aDirectionSymbol fromLocation: aPoint [
	"Push the cell at aPoint towards aDirectionSymbol and record the move so that it can be
	undone and counted. The four direction methods become one by looking the direction up from
	its symbol; the move is written only when the cell really moved, which is what the
	comparison of the two locations asks."

	| direction cell swappedCell |
	cell := self at: aPoint.
	direction := GridDirection directionFor: aDirectionSymbol.
	swappedCell := self pushCell: direction fromLocation: aPoint.
	swappedCell gridLocation = cell gridLocation ifFalse: [
		self stackAction: aDirectionSymbol forCell: cell ].
	^ swappedCell
]

{ #category : 'action' }
Grid >> pushCellEastFromLocation: aPoint [
	"Push the cell at aPoint one column to the right."

	^ self pushCellAction: #east fromLocation: aPoint
]

{ #category : 'action' }
Grid >> pushCellNorthFromLocation: aPoint [
	"Push the cell at aPoint one row up. One method per direction, each with nothing to say but
	its direction."

	^ self pushCellAction: #north fromLocation: aPoint
]

{ #category : 'action' }
Grid >> pushCellSouthFromLocation: aPoint [
	"Push the cell at aPoint one row down."

	^ self pushCellAction: #south fromLocation: aPoint
]

{ #category : 'action' }
Grid >> pushCellWestFromLocation: aPoint [
	"Push the cell at aPoint one column to the left."

	^ self pushCellAction: #west fromLocation: aPoint
]

{ #category : 'action' }
Grid >> reset [
	"Take every move back, in the reverse of the order they were made in, so that the board is
	as it was dealt. #undo answers whether it undid anything, so the loop has its work in its
	condition and ends when the stack of moves is empty."

	[self undo] whileTrue: []
]

{ #category : 'actions' }
Grid >> rotateCellClockwiseAt: aPoint [
	"Turn the cell at aPoint clockwise. The beam is taken off the board first and put back
	afterwards if the laser is on, so the cells it lit before the turn go dark and the cells on the
	new path light up. The turn is recorded, so that it can be undone and counted."

	| cell |
	cell := self at: aPoint.
	self clearCellsInPath.
	(self at: aPoint) rotateClockwise.
	self laserIsActive ifTrue: [ self activateCellsInPath ].
	self stackAction: #clockwise forCell: cell
]

{ #category : 'actions' }
Grid >> rotateCellCounterClockwiseAt: aPoint [
	"Turn the cell at aPoint counter clockwise. See `rotateCellClockwiseAt:`; only the action
	recorded differs."

	| cell |
	cell := self at: aPoint.
	self clearCellsInPath.
	(self at: aPoint) rotateCounterClockwise.
	self laserIsActive ifTrue: [ self activateCellsInPath ].
	self stackAction: #counterClockwise forCell: cell
]

{ #category : 'action' }
Grid >> stackAction: aSymbol forCell: aCell [
	"Record that aSymbol was done to aCell, so that the move can be taken back and counted. An
	entry holds the symbol of the move and where the cell is now: a pushed cell has already
	moved, and the push that undoes it starts from where it landed."

	self movesStack add: aSymbol->(aCell gridLocation)
]

{ #category : 'accessing' }
Grid >> startingCell [
	"Answer the cell the laser enters me at: column one of my last row. The beam enters it from
	the south, so it arrives through the bottom edge of my bottom left corner."

	| pt |
	pt := 1@(self numberOfRows).
	^self at: pt
]

{ #category : 'action' }
Grid >> stopLaser [
	self laserIsActive: false.
	self clearCellsInPath.
	
]

{ #category : 'action' }
Grid >> swapCell: aCell with: anotherCell [
	"Trade the places of two cells. A pushed mirror is never moved, it changes places with the
	blank cell beside it. at:put: writes the new location into the cell, so both cells know
	where they are afterwards, and the copies are taken before the first write because that
	write already changes one of the two locations."

	| oldLocation newLocation |
	oldLocation := aCell gridLocation copy.
	newLocation := anotherCell gridLocation copy.
	self at: newLocation put: aCell.
	self at: oldLocation put: anotherCell
]

{ #category : 'action' }
Grid >> undo [
	"Take the youngest move off my stack, play the move that reverses it, and answer true. Answer
	false and do nothing when there is no move left to take back. Playing the reverse goes through
	the methods that record moves, so it records one of its own, and the second #removeLast takes
	that entry off again."

	| actionAssociation symbol location reverseAction arguments |
	self movesStack isEmpty ifTrue: [^false].
	actionAssociation := self movesStack removeLast.
	symbol := actionAssociation key.
	location := actionAssociation value.
	reverseAction := ReverseLaserGameAction reverseActionSymbolFor: symbol.
	arguments := Array with: location.
	self perform: reverseAction withArguments: arguments.
	self movesStack removeLast.
	^true
]
