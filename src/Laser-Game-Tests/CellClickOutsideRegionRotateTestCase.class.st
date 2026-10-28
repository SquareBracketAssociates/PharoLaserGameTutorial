"
I test which way a click in the outside region of a mirror cell turns it.

Pages 101 to 104 of the 2007 tutorial divide that region with one horizontal line at half the height of the cell: the upper half turns the mirror clockwise, the lower half counter clockwise, and a point on the line counts as belonging to the upper half. Page 105 then gives the region a hint of its own, so a point of it answers the rotate region it falls in rather than the outside region itself.

The original checked fifteen hand-picked points of a 30 pixel cell. I keep that table, since it is the page's own, and add tests that derive their points from `CellClickRegionOutside regionRectangle`, so they hold at any cell size.
"
Class {
	#name : 'CellClickOutsideRegionRotateTestCase',
	#superclass : 'LaserGameTestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'support' }
CellClickOutsideRegionRotateTestCase >> assertRotateRegionTable [
	"Check the table: a point of the outside region, and the rotation a click there asks for. The
	rows name the corners, the edge centres and a few points near them of both the inside and the
	outside rectangle, so the table says the same thing at any cell size."

	| pt regionClass testTable cls rotateRegion inRect outRect |
	inRect := CellClickRegionInside regionRectangle.
	outRect := CellClickRegionOutside regionRectangle.
	pt := outRect topLeft + (1 @ 1).
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionOutside.
	testTable := {
		             (inRect topLeft -> CellClickRegionRotateClockwise).
		             (inRect topRight -> CellClickRegionRotateClockwise).
		             (inRect leftCenter -> CellClickRegionRotateClockwise).
		             (inRect rightCenter -> CellClickRegionRotateClockwise).
		             (inRect bottomLeft
		              -> CellClickRegionRotateCounterClockwise).
		             (inRect bottomRight
		              -> CellClickRegionRotateCounterClockwise).
		             (outRect topLeft -> CellClickRegionRotateClockwise).
		             (outRect topRight -> CellClickRegionRotateClockwise).
		             (outRect leftCenter -> CellClickRegionRotateClockwise).
		             (outRect rightCenter -> CellClickRegionRotateClockwise).
		             (outRect bottomCenter
		              -> CellClickRegionRotateCounterClockwise).
		             (outRect bottomRight
		              -> CellClickRegionRotateCounterClockwise).
		             (outRect topLeft x + 2 @ inRect topLeft y
		              -> CellClickRegionRotateClockwise).
		             (inRect rightCenter + (2 @ -2)
		              -> CellClickRegionRotateClockwise).
		             (inRect bottomLeft + (2 @ 2)
		              -> CellClickRegionRotateCounterClockwise) }.
	testTable do: [ :assoc |
		pt := assoc key.
		cls := assoc value.
		rotateRegion := regionClass rotateRegionForPoint: pt.
		self assert: rotateRegion equals: cls ]
]

{ #category : 'tests' }
CellClickOutsideRegionRotateTestCase >> testAPointOnTheDividingLineTurnsTheMirrorClockwise [
	"The dividing line sits at half the height of the cell, and a point on it counts as belonging
	to the upper half. The line is the cell's, not the region's, so it is written here as the
	cell says it."

	| onTheLine |
	onTheLine := CellClickRegionOutside regionRectangle left
	             @ (CellRenderer cellExtent y // 2).
	self assert: (CellClickRegionRotateClockwise containsPoint: onTheLine).
	self deny:
		(CellClickRegionRotateCounterClockwise containsPoint: onTheLine).
	self
		assert: (CellClickRegionOutside rotateRegionForPoint: onTheLine)
		equals: CellClickRegionRotateClockwise.
	self
		assert:
		(CellClickRegionOutside rotateRegionForPoint: onTheLine + (0 @ 1))
		equals: CellClickRegionRotateCounterClockwise
]

{ #category : 'tests' }
CellClickOutsideRegionRotateTestCase >> testClicksInRotateRegions [
	"Run the table at the cell size of the package."

	self assertRotateRegionTable
]

{ #category : 'tests' }
CellClickOutsideRegionRotateTestCase >> testEveryPointOfTheOutsideRegionIsInExactlyOneRotateRegion [
	"The dividing line cuts the outside region into an upper and a lower half that cover it and do
	not overlap, so every point of it turns the mirror one way and not the other. This walks the
	whole region rather than sampling points of one cell size."

	| rect |
	rect := CellClickRegionOutside regionRectangle.
	rect left to: rect right do: [ :x |
		rect top to: rect bottom do: [ :y |
			| point matching |
			point := x @ y.
			matching := CellClickRegionOutside subclasses select: [ :each |
				            each containsPoint: point ].
			self assert: matching size equals: 1 ] ]
]

{ #category : 'tests' }
CellClickOutsideRegionRotateTestCase >> testTheOutsideRegionRefinesTheHintToARotateRegion [
	"The outside region has a hint of its own, and answers it the way the inside region does: not
	itself, but the region of the point, which here is the direction the mirror turns."

	| rect |
	rect := CellClickRegionOutside regionRectangle.
	self
		assert: (CellClickRegionOutside hintRegionForPoint: rect topLeft)
		equals: CellClickRegionRotateClockwise.
	self
		assert: (CellClickRegionOutside hintRegionForPoint: rect bottomLeft)
		equals: CellClickRegionRotateCounterClockwise
]

{ #category : 'tests' }
CellClickOutsideRegionRotateTestCase >> testTheRotateRegionTableHoldsAtEveryCellSize [
	"Run the rotate table at three cell sizes. The line that divides the outside region sits at
	half the height of the cell, and every row names a corner or an edge centre of a rectangle a
	region answers, so no row goes stale when the cell grows."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [ self assertRotateRegionTable ] ]
]
