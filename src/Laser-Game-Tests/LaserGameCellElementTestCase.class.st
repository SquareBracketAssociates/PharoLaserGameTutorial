"
I test LaserGameCellElement: that a cell element knows the cell it shows and the renderer that built it, and that it classifies a point of its own into a click region without any board-wide arithmetic.

"
Class {
	#name : 'LaserGameCellElementTestCase',
	#superclass : 'TestCase',
	#instVars : [
		'board',
		'grid'
	],
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'running' }
LaserGameCellElementTestCase >> setUp [
	"Every test of mine works on the board of the book, so I build it and its element once here."

	super setUp.
	grid := GridExample demoGrid.
	board := LaserGameBoardElement on: grid
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testACellElementClassifiesAPointOfItsOwn [
	"A point is classified in the coordinates of the cell element itself: the top left corner is in
	the ignore margin, the first pixel of the outside rectangle is in the outside region, and the
	centre is in the inside region."

	| element |
	element := (LaserGameBoardElement on: GridExample demoGrid) cellElementAt: 1 @ 1.
	self
		assert: (element clickRegionAt: 0 @ 0)
		equals: CellClickRegionIgnore.
	self
		assert: (element clickRegionAt: CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionOutside.
	self
		assert: (element clickRegionAt: CellClickRegionInside regionRectangle center)
		equals: CellClickRegionInside
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testACellElementKnowsTheCellItShows [
	"A cell element carries its own cell, so nothing has to work back from a position on the
	board to a grid location."

	| element |
	element := board cellElementAt: 2 @ 3.
	self assert: element cell identicalTo: (board grid at: 2 @ 3).
	self assert: element gridLocation equals: 2 @ 3
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testACrossHairMarksThePointWhereAHintIsShown [
	"The pointer itself gets in the way of the hint it asks for, so a cross hair is drawn in the
	cell, centred on the point a click would use. An element is measured in a layout pass, so
	what it was asked for is read from its constraints."

	| element point extent |
	element := board cellElementAt: 4 @ 1.
	point := CellClickRegionInside regionRectangle center.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: point;
			 yourself).
	extent := CellRenderer crossHairExtent.
	self assert: element crossHairElement isNotNil.
	self
		assert:
		element crossHairElement constraints horizontal resizer size
		@ element crossHairElement constraints vertical resizer size
		equals: extent.
	self
		assert: element crossHairElement constraints position + (extent // 2)
		equals: point
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testAMirrorCellShowsOneArrowAtATime [
	"Old arrows must not clutter the board. The cell has one hint child, and moving to another
	push region replaces it. A hint brings two children: the arrow and the cross hair under
	the pointer."

	| element rect childCount |
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	rect := CellClickRegionInside regionRectangle.
	{ (rect leftCenter + (1 @ 0) -> LaserGameShapes eastArrowPoints).
	(rect topCenter + (0 @ 1) -> LaserGameShapes southArrowPoints).
	(rect rightCenter - (1 @ 0) -> LaserGameShapes westArrowPoints) } do: [ :each |
		element dispatchEvent: (BlMouseMoveEvent new
				 position: each key;
				 yourself).
		self assert: element children size equals: childCount + 2.
		self
			assert: element hintElement geometry vertices
			equals: (LaserGameShapes
					 pointsOf: each value
					 scaledToExtent: CellRenderer hintArrowExtent) ]
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testAPushArrowIsColouredByWhetherThePushIsAllowed [
	"The arrow says which way a click would move the cell; its colour says whether it could. The
	mirror at 4@1 can be pushed south, where 4@2 is blank, and cannot be pushed east, where the
	target stands. Same cell, same pointer, two colours."

	| element |
	element := board cellElementAt: 4 @ 1.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle topCenter + (0 @ 1);
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushSouth.
	self
		assert: element hintElement background paint color
		equals: LaserGameColors allowActionArrowColor.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle leftCenter + (1 @ 0);
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushEast.
	self
		assert: element hintElement background paint color
		equals: LaserGameColors denyActionArrowColor
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testARotateArrowIsAlwaysColouredAsAllowed [
	"A mirror can always be turned, in either direction, whatever stands around it: the outside
	region answers true in one line. So both rotate arrows are drawn in the colour of a move
	that is allowed, even on a mirror that is boxed in."

	| element |
	element := board cellElementAt: 3 @ 3.
	{ (CellClickRegionOutside regionRectangle topLeft
	  -> CellClickRegionRotateClockwise).
	(CellClickRegionOutside regionRectangle bottomLeft - (0 @ 1)
	 -> CellClickRegionRotateCounterClockwise) } do: [ :each |
		element dispatchEvent: (BlMouseMoveEvent new
				 position: each key;
				 yourself).
		self assert: element hintRegion equals: each value.
		self
			assert: element hintElement background paint color
			equals: LaserGameColors allowActionArrowColor ]
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testClickingACellElementRecordsItsCell [
	"A click reaches the cell element under the pointer, and the board records the cell that was
	clicked. BlClickEvent is what checks that the press and the release fell in the same cell."

	| element |
	element := board cellElementAt: 3 @ 5.
	element dispatchEvent: (BlClickEvent new
			 position: 25 @ 25;
			 yourself).
	self assert: board clickedCell identicalTo: (board grid at: 3 @ 5)
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testClickingACellThatIsNotAMirrorDoesNothing [
	"Only a mirror acts on a click. A blank cell and the target answer nothing wherever they are
	clicked, which is the renderer superclass doing nothing."

	#( 1 5 ) do: [ :column |
		| element |
		element := board cellElementAt: column @ 1.
		element dispatchEvent: (BlClickEvent new
				 position: CellClickRegionInside regionRectangle center;
				 yourself).
		element dispatchEvent: (BlClickEvent new
				 position: CellClickRegionOutside regionRectangle topLeft;
				 yourself).
		self assert: board clickedCell identicalTo: element cell ].
	self assert: board grid movesStack isEmpty
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testClickingTheIgnoreRegionOfAMirrorDoesNothing [
	"The margin around the outside region shows no hint and does nothing when it is clicked.
	The superclass of the regions answers that no action is possible, which is where the ignore
	region gets its answer from."

	| element mirror |
	element := board cellElementAt: 4 @ 1.
	mirror := element cell.
	element dispatchEvent: (BlClickEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: mirror isRight.
	self assert: board grid movesStack isEmpty.
	self assert: board clickedCell identicalTo: mirror
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testClickingTheInsideRegionOfAMirrorPushesIt [
	"The inside region pushes. A push region is named after the side the cell is pushed from, so
	the lower triangle pushes north; the mirror at 1@2 has a blank cell above it, and after the
	click each of the two cell elements draws what now stands in it."

	| element |
	element := board cellElementAt: 1 @ 2.
	self assert: element cell class equals: MirrorCell.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionInside regionRectangle bottomCenter - (0 @ 1);
			 yourself).
	self assert: (board grid at: 1 @ 1) class equals: MirrorCell.
	self assert: (board grid at: 1 @ 2) class equals: BlankCell.
	self
		assert: (board cellElementAt: 1 @ 1) renderer class
		equals: MirrorCellRenderer.
	self
		assert: (board cellElementAt: 1 @ 2) renderer class
		equals: BlankCellRenderer
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testClickingTheLowerOutsideRegionOfAMirrorTurnsItCounterClockwise [
	"The lower half of the outside region turns the mirror the other way. The mirror ends up on
	the same diagonal either way, so the direction is read from the move the grid records. The
	last row of the outside rectangle belongs to the ignore margin, as `Rectangle >>
	containsPoint:` leaves its bottom edge out, so the point is taken one pixel above it."

	| element mirror |
	element := board cellElementAt: 4 @ 1.
	mirror := element cell.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle bottomLeft - (0 @ 1);
			 yourself).
	self assert: mirror isLeft.
	self assert: board grid movesStack last key equals: #counterClockwise
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testClickingTheUpperOutsideRegionOfAMirrorTurnsItClockwise [
	"A click in the outside region turns the mirror, and the upper half turns it clockwise. The
	click carries a point in the coordinates of the cell, which is the whole of what the region
	needs."

	| element mirror |
	element := board cellElementAt: 4 @ 1.
	mirror := element cell.
	self assert: mirror isRight.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self assert: mirror isLeft.
	self assert: board grid movesStack last key equals: #clockwise
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testEachCellElementCarriesTheRendererOfItsCell [
	"The element is built by a renderer, and it keeps it: that is what redraws the cell later."

	board children do: [ :each |
		self assert: each renderer class modelClass equals: each cell class ]
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testEnteringACellElementMakesItTheHoveredCell [
	"The pointer entering a cell element is enough for the board to know which cell it is over."

	| element |
	element := board cellElementAt: 2 @ 3.
	element dispatchEvent: BlMouseEnterEvent new.
	self assert: board hoveredCellElement identicalTo: element.
	self assert: board hoveredCell identicalTo: (board grid at: 2 @ 3)
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testEveryCellElementAgreesWithItsCellAfterAPush [
	"Fire the laser, then push the mirror at 4@5 west to 3@5. Nothing feeds the target at 5@1 any
	more, so it must not be left drawn lit. This is the same walk as after a turn, made through a
	real click on a push arrow: the beam is off the board and back on it before anything is
	drawn, and every cell element shows the cell that stands in it."

	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	self assert: (grid at: 5 @ 1) isOn.
	(board cellElementAt: 4 @ 5) dispatchEvent: (BlClickEvent new
			 position: CellClickRegionInside regionRectangle rightCenter - (1 @ 0);
			 yourself).
	self assert: (grid at: 3 @ 5) class equals: MirrorCell.
	self deny: (grid at: 5 @ 1) isOn.
	1 to: grid numberOfRows do: [ :row |
		1 to: grid numberOfColumns do: [ :column |
			| location element cell |
			location := column @ row.
			cell := grid at: location.
			element := board cellElementAt: location.
			self assert: element renderer class modelClass equals: cell class.
			cell class = TargetCell ifTrue: [
				self
					assert: element children fourth background paint color
					equals: (cell isOn
							 ifTrue: [ LaserGameColors targetCenterColorActive ]
							 ifFalse: [ LaserGameColors targetCenterColorIdle ]) ] ] ]
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testEveryCellElementAgreesWithItsCellAfterATurn [
	"After a mirror is turned while the laser is on, is what the board shows still what the grid
	holds? Every cell is asked: the renderer is the one of the cell standing there, and the
	target is drawn lit exactly when its cell is on."

	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	(board cellElementAt: 4 @ 1) dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	1 to: grid numberOfRows do: [ :row |
		1 to: grid numberOfColumns do: [ :column |
			| location element cell |
			location := column @ row.
			cell := grid at: location.
			element := board cellElementAt: location.
			self assert: element renderer class modelClass equals: cell class.
			cell class = TargetCell ifTrue: [
				self
					assert: element children fourth background paint color
					equals: (cell isOn
							 ifTrue: [ LaserGameColors targetCenterColorActive ]
							 ifFalse: [ LaserGameColors targetCenterColorIdle ]) ] ] ]
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testEveryChildOfTheBoardIsACellElement [
	"The board holds one cell element per cell of its grid."

	grid := board grid.
	self
		assert: board children size
		equals: grid numberOfColumns * grid numberOfRows.
	board children do: [ :each |
		self assert: each class equals: LaserGameCellElement ]
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testHoveringAnotherCellClearsTheHintOfTheOneLeftBehind [
	"The pointer moves fast, mouse moves are sampled, and cells are skipped, so a cell can be
	left without ever being told. The board hovers one cell at a time, so the cell it hovered
	before loses its hint when another one takes its place, whatever events were missed."

	| first second |
	first := board cellElementAt: 4 @ 1.
	second := board cellElementAt: 1 @ 2.
	first dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: (first children includes: first hintElement).
	second dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: first hintRegion isNil.
	self assert: first hintElement isNil.
	self assert: (second children includes: second hintElement)
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testLeavingACellClearsItsHintRegion [
	"The pointer leaving a cell takes its hint with it, so no cell keeps a hint the pointer is
	no longer in."

	| element |
	element := board cellElementAt: 4 @ 1.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	element dispatchEvent: BlMouseLeaveEvent new.
	self assert: element hintRegion isNil
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testLeavingACellElementThatIsNotHoveredKeepsTheHover [
	"Moving from one cell to the next can deliver the enter of the new cell before the leave of
	the old one, so a leave only clears the hover when it comes from the cell that holds it."

	| left entered |
	left := board cellElementAt: 1 @ 1.
	entered := board cellElementAt: 2 @ 1.
	left dispatchEvent: BlMouseEnterEvent new.
	entered dispatchEvent: BlMouseEnterEvent new.
	left dispatchEvent: BlMouseLeaveEvent new.
	self assert: board hoveredCellElement identicalTo: entered
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testLeavingTheHoveredCellElementClearsTheHover [
	"The pointer leaving the cell it hovers leaves the board hovering nothing."

	| element |
	element := board cellElementAt: 2 @ 3.
	element dispatchEvent: BlMouseEnterEvent new.
	element dispatchEvent: BlMouseLeaveEvent new.
	self assert: board hoveredCellElement isNil.
	self assert: board hoveredCell isNil
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testMovingInTheOutsideRegionOfAMirrorCellShowsARotateArrow [
	"Hovering the outside region shows the curved arrows. The cell adds one as a child exactly as
	it adds a push arrow, and the upper half of the region shows the clockwise one. The last row
	of the region belongs to the ignore margin, as `Rectangle >> containsPoint:` leaves its
	bottom edge out, so the lower point is taken one pixel above it."

	| element rect |
	element := board cellElementAt: 4 @ 1.
	rect := CellClickRegionOutside regionRectangle.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: rect topLeft;
			 yourself).
	self assert: (element children includes: element hintElement).
	self
		assert: element hintElement geometry vertices
		equals: (LaserGameShapes
				 pointsOf: LaserGameShapes clockwiseArrowPoints
				 scaledToExtent: CellRenderer hintArrowExtent).
	element dispatchEvent: (BlMouseMoveEvent new
			 position: rect bottomLeft - (0 @ 1);
			 yourself).
	self
		assert: element hintElement geometry vertices
		equals: (LaserGameShapes
				 pointsOf: LaserGameShapes counterClockwiseArrowPoints
				 scaledToExtent: CellRenderer hintArrowExtent)
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testMovingInsideAMirrorCellRecordsItsHintRegion [
	"A mouse move carries a point, and the cell keeps the region that point falls in. In the
	middle of the cell that is a push region, since the push regions divide the inside region
	between them."

	| element |
	element := board cellElementAt: 4 @ 1.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushNorth.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionIgnore
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testMovingInsideAMirrorCellShowsTheArrowOfItsPushRegion [
	"The cell adds the arrow of the hint as a child, a few pixels smaller than the cell and
	centred in it, and its vertices are the ones of the direction the pointer asks for."

	| element |
	element := board cellElementAt: 4 @ 1.
	self assert: element hintElement isNil.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: (element children includes: element hintElement).
	self
		assert: element hintElement geometry vertices
		equals: (LaserGameShapes
				 pointsOf: LaserGameShapes northArrowPoints
				 scaledToExtent: CellRenderer hintArrowExtent).
	self
		assert: element hintElement constraints position
		equals: CellRenderer hintArrowOffset
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testMovingOverACellElementMakesItTheHoveredCell [
	"A mouse move over a cell answers which cell the pointer is over. Bloc sends it to the cell
	itself, so the board learns it from the cell."

	| element |
	element := board cellElementAt: 4 @ 2.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 10 @ 10;
			 yourself).
	self assert: board hoveredCellElement identicalTo: element
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testMovingOverACellThatIsNotAMirrorRecordsNoHint [
	"Blank and target cells answer no hint region, so moving over them records nothing and draws
	nothing."

	#( 1 5 ) do: [ :column |
		| element childCount |
		element := board cellElementAt: column @ 1.
		childCount := element children size.
		element dispatchEvent: (BlMouseMoveEvent new
				 position: CellClickRegionInside regionRectangle center;
				 yourself).
		self assert: element hintRegion isNil.
		self assert: element hintElement isNil.
		self assert: element children size equals: childCount ]
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testTheArrowGoesWhenAPushEmptiesTheCellUnderThePointer [
	"A push moves a mirror out of the cell the pointer is in. The renderer is chosen again when a
	cell is drawn again, so the picture of the cell is right — but the hint drawn over it would
	be the one of the cell that moved away. The pointer has not moved, and a blank cell offers no
	push, so the arrow goes and the emptied cell looks like any other blank cell."

	| element blank |
	element := board cellElementAt: 1 @ 2.
	blank := board cellElementAt: 2 @ 2.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle bottomCenter - (0 @ 1);
			 yourself).
	self assert: (element children includes: element hintElement).
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionInside regionRectangle bottomCenter - (0 @ 1);
			 yourself).
	self assert: element cell class equals: BlankCell.
	self assert: element hintRegion isNil.
	self assert: element hintElement isNil.
	self assert: element children size equals: blank children size.
	self assert: (board cellElementAt: 1 @ 1) hintElement isNil
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testTheArrowGoesWhenThePointerLeavesOrReachesARegionWithoutOne [
	"A hint lasts as long as the pointer is in a region that has one. Leaving the cell takes the
	arrow with it, and so does moving out to the margin, where the ignore region has no picture."

	| element childCount |
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: element hintElement isNil.
	self assert: element children size equals: childCount.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	element dispatchEvent: BlMouseLeaveEvent new.
	self assert: element hintElement isNil.
	self assert: element children size equals: childCount
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testTheArrowStaysWhenTheCellUnderThePointerStillOffersIt [
	"The other half of the same rule: a turn leaves the mirror where it is, so the hint under the
	pointer is still the right one and the arrow survives the redraw. The hint is read from the
	cell that stands there after the action, not kept and not dropped. The cross hair comes back
	with the arrow, which is the second of the two children counted here."

	| element childCount |
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionRotateClockwise.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self assert: element cell class equals: MirrorCell.
	self assert: element hintRegion equals: CellClickRegionRotateClockwise.
	self assert: (element children includes: element hintElement).
	self assert: (element children includes: element crossHairElement).
	self assert: element children size equals: childCount + 2
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testTheCrossHairFollowsThePointerWithinOneRegion [
	"The arrow is built once per region, since it does not change while the pointer stays in one,
	but the cross hair marks a point and moves with every event. The step down is a quarter of the
	inside region rather than four pixels, so the second point is in the same push region as the
	first at any cell size."

	| element first second extent step |
	element := board cellElementAt: 4 @ 1.
	extent := CellRenderer crossHairExtent.
	step := CellClickRegionInside regionRectangle height // 4 max: 1.
	first := CellClickRegionInside regionRectangle center.
	second := first + (0 @ step).
	element dispatchEvent: (BlMouseMoveEvent new
			 position: first;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushNorth.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: second;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushNorth.
	self
		assert: element crossHairElement constraints position + (extent // 2)
		equals: second
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testTheCrossHairIsShownExactlyWhenAHintIs [
	"The cross hair appears with the hint and goes in the two places the hint goes: a point that
	offers no action, and the pointer leaving. A cell that offers nothing, like the blank one at
	2@2, never shows either."

	| mirror blank |
	mirror := board cellElementAt: 4 @ 1.
	blank := board cellElementAt: 2 @ 2.
	mirror dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: mirror crossHairElement isNotNil.
	mirror dispatchEvent: (BlMouseMoveEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: mirror hintRegion equals: CellClickRegionIgnore.
	self assert: mirror hintElement isNil.
	self assert: mirror crossHairElement isNil.
	mirror dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: mirror crossHairElement isNotNil.
	mirror dispatchEvent: BlMouseLeaveEvent new.
	self assert: mirror crossHairElement isNil.
	blank dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: blank crossHairElement isNil
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testTheHintArrowSitsCentredInTheCellAtEveryCellSize [
	"An arrow is a polygon scaled onto the rectangle it is given, and it has to end up centred in
	the cell whatever the cell measures. A mirror cell is hovered at three cell sizes, and the
	arrow it shows is measured where it really sits: the space it leaves on the left is the space
	it leaves on the right, and the space above is the space below."

	#( 30 40 80 ) do: [ :size |
		LaserGameTestCase withCellExtent: size @ size do: [
			| element arrow position margin |
			element := (LaserGameBoardElement on: GridExample demoGrid)
				           cellElementAt: 4 @ 1.
			element dispatchEvent: (BlMouseMoveEvent new
					 position: CellClickRegionInside regionRectangle center;
					 yourself).
			arrow := element hintElement.
			self deny: arrow isNil.
			position := arrow constraints position.
			margin := CellRenderer cellExtent
			          - CellRenderer hintArrowExtent - position.
			self assert: margin equals: position.
			self assert: position x equals: position y ] ]
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testTheSameLocalPointMeansTheSameRegionInEveryCell [
	"Every cell classifies points in its own coordinates, so the cell in the far corner answers
	exactly what the cell at the origin answers."

	| first last |
	first := board cellElementAt: 1 @ 1.
	last := board
		        cellElementAt: board grid numberOfColumns @ board grid numberOfRows.
	{ 0 @ 0.
	CellClickRegionOutside regionRectangle topLeft.
	CellClickRegionInside regionRectangle center } do: [ :point |
		self
			assert: (last clickRegionAt: point)
			equals: (first clickRegionAt: point) ]
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testTurningAMirrorOnTheBeamRedrawsTheWholeBoard [
	"One click changes more than one cell: the mirror at 4@1 sends the beam into the target at
	5@1, and turning it sends the beam west instead. Every cell is drawn again after an action,
	so the target goes dark without anything working out which cells the beam left. The disc is the
	last child of the target, since a lit target draws the beam under its picture."

	| target |
	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	target := board cellElementAt: 5 @ 1.
	self
		assert: target children last background paint color
		equals: LaserGameColors targetCenterColorActive.
	(board cellElementAt: 4 @ 1) dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self
		assert: (board cellElementAt: 5 @ 1) children last background paint color
		equals: LaserGameColors targetCenterColorIdle
]
