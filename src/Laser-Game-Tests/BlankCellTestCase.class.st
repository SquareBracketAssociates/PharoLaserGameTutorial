Class {
	#name : 'BlankCellTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'tests' }
BlankCellTestCase >> testCellExitSides [

	| cell exit |
	cell := BlankCell new.
	exit := cell exitSideFor: #north.
	self assert: exit equals: #south.

	exit := cell exitSideFor: #east.
	self assert: exit equals: #west.

	exit := cell exitSideFor: #south.
	self assert: exit equals: #north.

	exit := cell exitSideFor: #west.
	self assert: exit equals: #east
]

{ #category : 'tests' }
BlankCellTestCase >> testCellLaserActivity [

	| cell |
	cell := BlankCell new.
	cell laserEntersFrom: #north.
	self assert: cell isOn.
	self assert: (cell isSegmentOnFor: #north).
	self assert: (cell isSegmentOnFor: #south).
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
]

{ #category : 'tests' }
BlankCellTestCase >> testCellOnState [

	| cell |
	cell := BlankCell new.
	self assert: cell isOff.
	self shouldnt: [ cell isOn ]
]

{ #category : 'tests' }
BlankCellTestCase >> testCellSegmentState [

	| cell |
	cell := BlankCell new.
	self shouldnt: [ cell isSegmentOnFor: #north ].
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
]

{ #category : 'tests' }
BlankCellTestCase >> testCellSegmentsState [
	| cell |
	cell := BlankCell new.
	self shouldnt: [cell isSegmentOnFor: #north].
	self shouldnt: [cell isSegmentOnFor: #east].
	self shouldnt: [cell isSegmentOnFor: #south].
	self shouldnt: [cell isSegmentOnFor: #west].
]

{ #category : 'tests' }
BlankCellTestCase >> testPrintStringSaysWhereTheCellIsAndWhetherItIsOn [
	"A cell that is not a mirror has no lean to report, so it prints its location and its state."

	| cell |
	cell := BlankCell new.
	cell gridLocation: 2 @ 3.
	self assert: cell printString equals: 'a BlankCell(2@3, off)'.
	cell laserEntersFrom: #north.
	self assert: cell printString equals: 'a BlankCell(2@3, on)'
]

{ #category : 'tests' }
BlankCellTestCase >> testRotatingACellThatIsNotAMirrorDoesNothing [
	"The two rotate messages live on Cell, where they do nothing, so a click in the outside region
	of any cell can send them without asking what kind of cell it is. Only a mirror has anything
	to turn."

	| cell |
	cell := BlankCell new.
	cell gridLocation: 2 @ 3.
	cell laserEntersFrom: #north.
	cell rotateClockwise.
	cell rotateCounterClockwise.
	self assert: cell gridLocation equals: 2 @ 3.
	self assert: cell isOn.
	self assert: (cell exitSideFor: #north) equals: #south
]

{ #category : 'tests' }
BlankCellTestCase >> testThePictureTabShowsMeAsTheBoardDrawsMe [
	"The Picture tab draws me with the renderer the game uses, so what the inspector shows and
	what the player sees cannot disagree. Showing me must not change me, which the location
	asserted afterwards is here to hold."

	| cell builder |
	cell := BlankCell new.
	cell gridLocation: 2 @ 3.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	self
		assert: (cell inspectionPicture: builder) class
		equals: SpMorphPresenter.
	self assert: cell gridLocation equals: 2 @ 3.
	self assert: cell isOff
]
