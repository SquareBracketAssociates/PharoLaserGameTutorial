"
I am a `Cell` with a mirror on one of its diagonals. `leansLeft` says which one. When I lean left the mirror runs from my top left corner to my bottom right one, and a beam entering from the north leaves by the east. When I lean right it runs from my top right corner to my bottom left one, and the same beam leaves by the west.

`leanLeft` and `leanRight` set the lean and all four exit sides together, which is why `rotate` uses them instead of flipping `leansLeft` on its own. A lean changed without its exit sides is a bug that is hard to see: the mirror is drawn on the new diagonal while the beam still leaves by the old side.

`rotateClockwise` and `rotateCounterClockwise` are both `rotate`. A diagonal has only two positions, so either direction lands on the other one.
"
Class {
	#name : 'MirrorCell',
	#superclass : 'Cell',
	#instVars : [
		'leansLeft'
	],
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'instance creation' }
MirrorCell class >> leanLeft [
	"Answer a mirror on the diagonal from my top left corner to my bottom right one."

	^ self new leanLeft
]

{ #category : 'instance creation' }
MirrorCell class >> leanRight [
	"Answer a mirror on the diagonal from my top right corner to my bottom left one."

	^ self new leanRight
]

{ #category : 'initialization' }
MirrorCell >> initialize [
	super initialize.
	self initializeExitSides.
	self leanLeft
]

{ #category : 'initialization' }
MirrorCell >> initializeExitSides [
	self exitSides: Dictionary new.
	
]

{ #category : 'inspecting' }
MirrorCell >> inspectionLean: aBuilder [
	"Show my four sides against the way I lean: where a beam entering each side leaves me, and
	whether that is the side a fresh mirror leaning my way would send it out by. A mirror whose
	lean was changed without its exit sides reads 'no' on every row, which is the fault rotate
	exists to prevent."

	<inspectorPresentationOrder: 3 title: 'Lean'>
	^ aBuilder newTable
		  items: #( #north #east #south #west );
		  addColumn: (SpStringTableColumn title: 'Enters from' evaluated: [ :each | each asString ]);
		  addColumn: (SpStringTableColumn title: 'Leaves by' evaluated: [ :each |
					   (self exitSideFor: each) asString ]);
		  addColumn: (SpStringTableColumn title: 'Matches lean' evaluated: [ :each |
					   | reference |
					   reference := self isLeft
						                ifTrue: [ self class leanLeft ]
						                ifFalse: [ self class leanRight ].
					   (self exitSideFor: each) = (reference exitSideFor: each)
						   ifTrue: [ 'yes' ]
						   ifFalse: [ 'no' ] ]);
		  yourself
]

{ #category : 'testing' }
MirrorCell >> isLeft [
	^self leansLeft
]

{ #category : 'testing' }
MirrorCell >> isRight [
	^self isLeft not
]

{ #category : 'initialization' }
MirrorCell >> leanLeft [
	self leansLeft: true.
	self exitSides at: #north put: #east.
	self exitSides at: #east put: #north.
	self exitSides at: #south put: #west.
	self exitSides at: #west put: #south.
	
]

{ #category : 'initialization' }
MirrorCell >> leanRight [
	self leansLeft: false.
	self exitSides at: #north put: #west.
	self exitSides at: #east put: #south.
	self exitSides at: #south put: #east.
	self exitSides at: #west put: #north.
	
]

{ #category : 'accessing' }
MirrorCell >> leansLeft [
	"Answer the value of leansLeft"

	^ leansLeft
]

{ #category : 'accessing' }
MirrorCell >> leansLeft: anObject [
	"Set the value of leansLeft"

	leansLeft := anObject
]

{ #category : 'printing' }
MirrorCell >> printDetailsOn: aStream [
	"Add the way I lean, which is the one fact that tells two mirrors at the same place apart."

	super printDetailsOn: aStream.
	aStream nextPutAll:
		(self isLeft ifTrue: [ ' leans left' ] ifFalse: [ ' leans right' ])
]

{ #category : 'actions' }
MirrorCell >> rotate [
	"Turn me a quarter of a turn, which puts my mirror on the other diagonal. Go through leanLeft
	and leanRight rather than flipping leansLeft, because the lean and the four exit sides have to
	change together: a lean changed on its own leaves the beam going out the way it went out
	before."

	self isLeft
		ifTrue: [ self leanRight ]
		ifFalse: [ self leanLeft ]
]

{ #category : 'actions' }
MirrorCell >> rotateClockwise [
	"Turn me clockwise. A quarter of a turn either way leaves my mirror on the same diagonal, so
	both directions do the same thing to me. The two stay apart all the same, so that a caller can
	say which way it means, and one method does the work."

	self rotate
]

{ #category : 'actions' }
MirrorCell >> rotateCounterClockwise [
	"Turn me counter clockwise, which does the same to me as turning me clockwise. See
	`rotateClockwise`."

	self rotate
]
