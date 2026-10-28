Class {
	#name : 'TargetCellTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'tests' }
TargetCellTestCase >> testCellExitSides [

	| cell inputSides |
	cell := TargetCell new.
	inputSides := #( #north #east #south #west ).
	inputSides do: [ :inputSide |
		| exit |
		exit := cell exitSideFor: inputSide.
		self assert: exit isNil ]
]

{ #category : 'tests' }
TargetCellTestCase >> testCellLaserActivity [

	| cell |
	cell := TargetCell new.
	cell laserEntersFrom: #north.
	self assert: cell isOn.
	self assert: (cell isSegmentOnFor: #north).
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
]

{ #category : 'tests' }
TargetCellTestCase >> testCellOnState [

	| cell |
	cell := TargetCell new.
	self assert: cell isOff.
	self shouldnt: [ cell isOn ]
]

{ #category : 'tests' }
TargetCellTestCase >> testCellSegmentState [
|cell|
cell := TargetCell new.
self shouldnt: [ cell isSegmentOnFor: #north ].
self shouldnt: [ cell isSegmentOnFor: #east ].
self shouldnt: [ cell isSegmentOnFor: #south ].
self shouldnt: [ cell isSegmentOnFor: #west ].
]

{ #category : 'tests' }
TargetCellTestCase >> testCellSegmentsState [
	| cell |
	cell := TargetCell new.
	self shouldnt: [cell isSegmentOnFor: #north].
	self shouldnt: [cell isSegmentOnFor: #east].
	self shouldnt: [cell isSegmentOnFor: #south].
	self shouldnt: [cell isSegmentOnFor: #west].
]

{ #category : 'tests' }
TargetCellTestCase >> testThePictureTabShowsMeAsTheBoardDrawsMe [
	"The Picture tab draws me with my own renderer, ring and all. A target lit by the beam is
	drawn lit, since the picture is made from my own state."

	| cell builder |
	cell := TargetCell new.
	cell gridLocation: 5 @ 1.
	cell laserEntersFrom: #west.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	self
		assert: (cell inspectionPicture: builder) class
		equals: SpMorphPresenter.
	self assert: cell gridLocation equals: 5 @ 1.
	self assert: cell isOn
]
