Class {
	#name : 'CellRendererTestCase',
	#superclass : 'LaserGameTestCase',
	#instVars : [
		'grid'
	],
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'support' }
CellRendererTestCase >> requestedExtentOf: anElement [
	"Answer the extent anElement was built with, read from its resizers. An element measures
	itself only in a layout pass, so its extent is zero until it is laid out."

	^ anElement constraints horizontal resizer size
	  @ anElement constraints vertical resizer size
]

{ #category : 'running' }
CellRendererTestCase >> setUp [
	"Most of my tests render a cell of the board of the book, so I make it once here."

	super setUp.
	grid := GridExample demoGrid
]

{ #category : 'tests' }
CellRendererTestCase >> testABlankCellCrossedTwiceShowsBothBeams [
	"A blank cell can be crossed twice as well, which lights all four of its sides. Nothing extra
	is asked for: both bands are drawn the whole way across and both cores go over them."

	| cell element beam extent |
	grid := Grid new.
	cell := BlankCell new.
	grid at: 1 @ 1 put: cell.
	cell laserEntersFrom: #west.
	cell laserEntersFrom: #north.
	grid laserIsActive: true.
	extent := CellRenderer cellExtent.
	element := (CellRenderer rendererFor: cell grid: grid) newElement.
	beam := element children first.
	self assert: beam children size equals: 4.
	beam children do: [ :bar |
		self
			assert: ((self requestedExtentOf: bar) x max: (self requestedExtentOf: bar) y)
			equals: extent x ].
	self
		assert: beam children last background paint color
		equals: LaserGameColors laserBeamCenterColor
]

{ #category : 'tests' }
CellRendererTestCase >> testABlankCellDrawsNoBeamUnlessTheLaserReachesIt [
	"A cell draws a beam only while the laser is firing and only where the beam runs. Both
	questions are asked in #renderLaserOn:, before anything is drawn."

	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid) newElement
				children.
	grid fireLaser.
	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid) newElement
				children.
	grid stopLaser.
	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid) newElement
				children
]

{ #category : 'tests' }
CellRendererTestCase >> testBlankCellElement [
	"A blank cell is a square of the board background with a border and nothing inside.
	The element is checked before any layout pass, so the size is read from the layout
	constraints rather than from the extent, which stays zero until the element is laid out."

	| oneCellGrid element |
	oneCellGrid := Grid new.
	element := (CellRenderer rendererFor: (oneCellGrid at: 1 @ 1) grid: oneCellGrid)
		           newElement.
	self
		assert: element constraints horizontal resizer size
		equals: CellRenderer cellExtent x.
	self
		assert: element constraints vertical resizer size
		equals: CellRenderer cellExtent y.
	self assert: element geometry class equals: BlRectangleGeometry.
	self
		assert: element background paint color
		equals: LaserGameColors gameBoardBackgroundColor.
	self assert: element border width equals: CellRenderer borderWidth.
	self
		assert: element border paint color
		equals: LaserGameColors cellBorderColor.
	"A blank cell draws nothing inside its border."
	self assertEmpty: element children
]

{ #category : 'tests' }
CellRendererTestCase >> testEveryCellClassHasExactlyOneRenderer [

	Cell allSubclasses do: [ :cellClass |
		| renderers |
		renderers := CellRenderer allSubclasses select: [ :each |
			             each modelClass = cellClass ].
		self
			assert: renderers size = 1
			description: cellClass name , ' must have exactly one renderer, found '
				, renderers size printString ]
]

{ #category : 'tests' }
CellRendererTestCase >> testEverySizeInACellFollowsTheCellSize [
	"Every size in a cell is derived from the cell size, and this is what that claim means. At
	any cell size the two nested regions stay centred in the cell, every point of the cell
	falls in a region, the four push regions divide the inside square between them without
	overlapping, the ring of a target still fits in the cell, and a board is still the grid
	times the cell."

	#( 30 40 80 ) do: [ :side |
		self withCellExtent: side @ side do: [
			| cell inside outside middle renderer |
			cell := 0 @ 0 extent: side @ side.
			inside := CellClickRegionInside regionRectangle.
			outside := CellClickRegionOutside regionRectangle.
			self assert: inside extent equals: CellRenderer insideRegionExtent.
			self assert: outside extent equals: CellRenderer outsideRegionExtent.
			self assert: inside center equals: cell center.
			self assert: outside center equals: cell center.

			middle := side // 2.
			self assert: (CellClickRegionRotateClockwise containsPoint: 0 @ middle).
			self deny: (CellClickRegionRotateClockwise containsPoint: 0 @ (middle + 1)).
			self assert:
				(CellClickRegionRotateCounterClockwise containsPoint: 0 @ (middle + 1)).

			0 to: side - 1 do: [ :x |
				0 to: side - 1 do: [ :y |
					self assert: (CellClickRegion clickRegionForPoint: x @ y) notNil ] ].
			inside left to: inside right do: [ :x |
				inside top to: inside bottom do: [ :y |
					self
						assert: (CellClickRegionInside subclasses count: [ :each |
								 each containsPoint: x @ y ])
						equals: 1 ] ].

			renderer := CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid.
			self assert: renderer radius > 0.
			self assert: renderer innerRadius > 0.
			self assert: renderer radius * 2 <= side.

			self
				assert: (LaserGameBoardElement extentForGrid: grid)
				equals: side * grid numberOfColumns @ (side * grid numberOfRows) ] ]
]

{ #category : 'tests' }
CellRendererTestCase >> testOnlyAMirrorAnswersAHintRegion [
	"Every renderer is asked for a hint region, and all but the mirror answer nothing: that is the
	whole of the design, and it lives in the hierarchy rather than in a conditional. The mirror
	answers the push region of the point, since the middle of a cell is where a push is asked for."

	| point |
	point := CellClickRegionInside regionRectangle center.
	self
		assert: ((CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 4 @ 1) grid: grid)
				 hintRegionAt: point)
		equals: CellClickRegionPushNorth
]

{ #category : 'tests' }
CellRendererTestCase >> testRendererForUnsupportedModelIsAnError [

	self should: [ CellRenderer rendererFor: 42 ] raise: Error
]

{ #category : 'tests' }
CellRendererTestCase >> testRendererSelection [

	| renderer cell |
	cell := BlankCell new.
	renderer := CellRenderer rendererFor: cell.
	self assert: renderer equals: BlankCellRenderer.


	cell := MirrorCell new.
	renderer := CellRenderer rendererFor: cell.
	self assert: renderer equals: MirrorCellRenderer.

	cell := TargetCell new.
	renderer := CellRenderer rendererFor: cell.
	self assert: renderer equals: TargetCellRenderer
]

{ #category : 'tests' }
CellRendererTestCase >> testTheBeamCrossesABlankCellFromSideToSide [
	"The beam goes straight through a blank cell, so it is one line. The demo grid sends the beam
	along the bottom row from west to east, and the blank cell at 2@5 is one the beam crosses that
	way."

	| element beam |
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid)
		           newElement.
	self assert: element children size equals: 1.
	beam := element children first.
	self
		assert: (self requestedExtentOf: beam)
		equals: CellRenderer cellExtent.
	self
		assert: (self requestedExtentOf: beam children first)
		equals: CellRenderer cellExtent x
			@ (LaserGameShapes laserBeamSplatterThicknessFor: CellRenderer cellExtent).
	self
		assert: beam children second background paint color
		equals: LaserGameColors laserBeamCenterColor
]

{ #category : 'tests' }
CellRendererTestCase >> testTheBeamCrossesABlankCellFromTopToBottom [
	"One question chooses between the two drawings: is the south segment lit. The demo grid turns
	the beam north at 4@5, so the blank cell at 4@4 is crossed from top to bottom."

	| element beam |
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 4) grid: grid)
		           newElement.
	self assert: element children size equals: 1.
	beam := element children first.
	self
		assert: (self requestedExtentOf: beam)
		equals: CellRenderer cellExtent.
	self
		assert: (self requestedExtentOf: beam children first)
		equals: (LaserGameShapes laserBeamSplatterThicknessFor: CellRenderer cellExtent)
			@ CellRenderer cellExtent y.
	self
		assert: beam children second background paint color
		equals: LaserGameColors laserBeamCenterColor
]

{ #category : 'tests' }
CellRendererTestCase >> testTheHintArrowIsCentredInItsCellAtEveryCellSize [
	"A hint arrow is a polygon scaled onto the rectangle it is given, so its ink is its extent and
	centring it is arithmetic on two constants. Both halves are checked here, at three cell sizes:
	the offset leaves the same margin on every side of the cell, and every arrow fills the
	rectangle it is asked for."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [
			| offset |
			offset := CellRenderer hintArrowOffset.
			self
				assert: (offset * 2) + CellRenderer hintArrowExtent
				equals: CellRenderer cellExtent.
			self assert: offset x equals: offset y.
			#( #northArrowElementOfExtent: #southArrowElementOfExtent:
			   #eastArrowElementOfExtent: #westArrowElementOfExtent:
			   #clockwiseArrowElementOfExtent:
			   #counterClockwiseArrowElementOfExtent: ) do: [ :selector |
				| element |
				element := LaserGameShapes
					           perform: selector
					           with: CellRenderer hintArrowExtent.
				self
					assert: (Rectangle encompassing: element geometry vertices)
					equals: (0 @ 0 corner: CellRenderer hintArrowExtent) ] ] ]
]
