Class {
	#name : 'MirrorCellRendererTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'running' }
MirrorCellRendererTestCase >> mirrorElementLeaning: aSymbol [
	"Answer the mirror child of the element rendered for a mirror cell leaning aSymbol."

	^ (self rendererLeaning: aSymbol) newElement children first
]

{ #category : 'running' }
MirrorCellRendererTestCase >> rendererLeaning: aSymbol [
	"Answer a mirror renderer for a mirror cell leaning aSymbol, #left or #right, sitting at 1@1
	of a fresh grid."

	| grid cell |
	grid := Grid new.
	cell := MirrorCell new.
	aSymbol = #left
		ifTrue: [ cell leanLeft ]
		ifFalse: [ cell leanRight ].
	grid at: 1 @ 1 put: cell.
	^ CellRenderer rendererFor: cell grid: grid
]

{ #category : 'support' }
MirrorCellRendererTestCase >> requestedExtentOf: anElement [
	"Answer the extent anElement was built with, read from its resizers. An element measures
	itself only in a layout pass, so its extent is zero until it is laid out."

	^ anElement constraints horizontal resizer size
	  @ anElement constraints vertical resizer size
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testAMirrorAnswersThePushRegionOfAPointInsideIt [
	"A mirror asks the region of a point what hint applies there, so a point in the inside region
	answers a push region rather than the inside region itself, and a point in the outside region
	answers a rotate region."

	| renderer rect |
	renderer := self rendererLeaning: #left.
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (renderer hintRegionAt: rect leftCenter + (1 @ 0))
		equals: CellClickRegionPushEast.
	self
		assert: (renderer hintRegionAt: rect topCenter + (0 @ 1))
		equals: CellClickRegionPushSouth.
	self
		assert: (renderer hintRegionAt: CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionRotateClockwise.
	self assert: (renderer hintRegionAt: 0 @ 0) equals: CellClickRegionIgnore
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testAMirrorCrossedTwiceShowsBothBeamsWhole [
	"A mirror can be lit on all four of its sides, where the beam crosses its own path. Both beams
	then run the whole way across, and the turn needs no case of its own."

	| grid cell element beam extent |
	grid := Grid new.
	cell := MirrorCell new.
	cell leanLeft.
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
			equals: extent x ]
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testLeanLeftMirrorRunsFromTopLeftToBottomRight [
	"A left leaning mirror goes down and to the right, inset from both corners it points at."

	| renderer mirror inset delta |
	renderer := self rendererLeaning: #left.
	mirror := renderer newElement children first.
	inset := renderer cornerInset.
	delta := MirrorCellRenderer cellExtent - 1.
	self assert: mirror geometry class equals: BlLineGeometry.
	self assert: mirror geometry from equals: inset.
	self assert: mirror geometry to equals: delta - inset
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testLeanRightMirrorRunsFromTopRightToBottomLeft [
	"A right leaning mirror goes down and to the left, inset from both corners it points at."

	| renderer mirror inset delta |
	renderer := self rendererLeaning: #right.
	mirror := renderer newElement children first.
	inset := renderer cornerInset.
	delta := MirrorCellRenderer cellExtent - 1.
	self assert: mirror geometry class equals: BlLineGeometry.
	self assert: mirror geometry from equals: delta x - inset x @ inset y.
	self assert: mirror geometry to equals: inset x @ (delta y - inset y)
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testMirrorCellHoldsOneMirror [
	"A mirror cell draws one diagonal, whichever way it leans."

	self assert: (self rendererLeaning: #left) newElement children size equals: 1.
	self assert: (self rendererLeaning: #right) newElement children size equals: 1
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testMirrorCoversTheWholeCell [
	"The child carrying the line is the size of the cell, so both ends of the diagonal are cell
	local coordinates."

	| mirror |
	mirror := self mirrorElementLeaning: #right.
	self
		assert: mirror constraints horizontal resizer size
		equals: MirrorCellRenderer cellExtent x.
	self
		assert: mirror constraints vertical resizer size
		equals: MirrorCellRenderer cellExtent y
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testMirrorIsAStrokeInTheMirrorColor [
	"The diagonal is painted by the border of the child, since a line has no inside to fill. The
	stroke is centered on the line, so the mirror is as thick on one side of it as on the other."

	| mirror |
	mirror := self mirrorElementLeaning: #left.
	self
		assert: mirror border paint color
		equals: LaserGameColors mirrorColor.
	self
		assert: mirror border width
		equals: MirrorCellRenderer mirrorWidth.
	self assert: mirror outskirts equals: BlOutskirts centered
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testRotatingTheCellTurnsTheMirrorOver [
	"Rendering follows the cell. Rotating a mirror cell and rendering it again draws the other
	diagonal, so the two ends swap corners along the x axis."

	| renderer before after |
	renderer := self rendererLeaning: #left.
	before := renderer newElement children first geometry.
	renderer cell rotate.
	after := renderer newElement children first geometry.
	self assert: after from y equals: before from y.
	self assert: after to y equals: before to y.
	self assert: after from x equals: before to x.
	self assert: after to x equals: before from x
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testTheBeamTurnsAtAMirror [
	"The demo grid turns the beam north at the mirror of 4@5, which is lit on its west side, where
	the light arrives, and on its north side, where it leaves. The cell shows two half beams, and
	nothing at all in the two quadrants the light never reaches."

	| grid element beam half extent |
	grid := GridExample demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 5) grid: grid)
		           newElement.
	extent := CellRenderer cellExtent.
	half := extent x // 2.
	beam := element children first.
	self assert: beam children size equals: 4.
	self assert: (self requestedExtentOf: beam children first) x equals: half.
	self assert: beam children first constraints position x equals: 0.
	self assert: (self requestedExtentOf: beam children second) y equals: half.
	self assert: beam children second constraints position y equals: 0
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testTheMirrorIsDrawnOverTheBeam [
	"The mirror is drawn after the beam, so the light does not hide the thing that turns it: the
	beam is the first child and the mirror is the last."

	| grid element |
	grid := GridExample demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 5) grid: grid)
		           newElement.
	self assert: element children size equals: 2.
	self assert: element children first children size equals: 4.
	self
		assert: element children last geometry class
		equals: BlLineGeometry
]
