"
I am the model of one square of the laser game board. I know where I sit (`gridLocation`, a `column @ row` point), which side a beam leaves by when it enters from a given side (`exitSides`, a dictionary keyed by `#north`, `#east`, `#south` and `#west`), and which of those sides carry light right now (`activeSegments`).

I am abstract: a subclass fills `exitSides` in `initializeExitSides`. `BlankCell` lets a beam straight through, `MirrorCell` turns it a quarter turn, `TargetCell` swallows it and lights up.

`rotateClockwise` and `rotateCounterClockwise` do nothing here, so a click on a cell that cannot turn is harmless. `MirrorCell` overrides both.

`printOn:` prints where I am and whether I am on; a subclass adds its own detail by overriding `printDetailsOn:`. Inspect me and the Sides tab lists my four sides with the side a beam leaves by and whether that side is lit.
"
Class {
	#name : 'Cell',
	#superclass : 'Object',
	#instVars : [
		'activeSegments',
		'exitSides',
		'gridLocation'
	],
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'accessing' }
Cell >> activeSegments [
	"Answer the value of activeSegments"

	^ activeSegments
]

{ #category : 'accessing' }
Cell >> activeSegments: aDictionary [
	"Set the value of activeSegments"

	activeSegments := aDictionary
]

{ #category : 'initialization' }
Cell >> clearCell [
	self initializeActiveSegments
]

{ #category : 'accessing' }
Cell >> exitSideFor: aSymbol [
	^self exitSides at: aSymbol
]

{ #category : 'accessing' }
Cell >> exitSides [
	"Answer the value of exitSides"

	^ exitSides
]

{ #category : 'accessing' }
Cell >> exitSides: aDictionary [
	"Set the value of exitSides"

	exitSides := aDictionary
]

{ #category : 'accessing' }
Cell >> gridLocation [
	"Answer the value of gridLocation"

	^ gridLocation
]

{ #category : 'accessing' }
Cell >> gridLocation: anObject [
	"Set the value of gridLocation"

	gridLocation := anObject
]

{ #category : 'initialization' }
Cell >> initialize [
	super initialize.
	self initializeActiveSegments.

]

{ #category : 'initialization' }
Cell >> initializeActiveSegments [
	self activeSegments: Dictionary new.
	self activeSegments at: #north put: false.
	self activeSegments at: #east put: false.
	self activeSegments at: #south put: false.
	self activeSegments at: #west put: false.
	
]

{ #category : 'initialization' }
Cell >> initializeExitSides [
	"Fill exitSides with the side a beam leaves by for each side it can enter from. Every
	subclass answers this differently, which is what makes a cell blank, a mirror or a target,
	so I am abstract here."

	^ self subclassResponsibility
]

{ #category : 'inspecting' }
Cell >> inspectionPicture: aBuilder [
	"Show me as the board draws me, through the renderer the game itself uses, so that a model
	fault and a drawing fault can be told apart without opening the game. The renderer reads a
	copy of me standing in a grid of its own, because a view must not change what it shows."

	<inspectorPresentationOrder: 2 title: 'Picture'>
	| location grid renderer |
	location := self gridLocation ifNil: [ 1 @ 1 ].
	grid := Grid newOfSize: location.
	grid at: location put: self copy.
	grid laserIsActive: true.
	renderer := CellRenderer rendererFor: (grid at: location) grid: grid.
	^ aBuilder newMorph
		  morph: renderer newElement asPreviewMorph;
		  yourself
]

{ #category : 'inspecting' }
Cell >> inspectionSides: aBuilder [
	"Show one row per side of me: where a beam entering there leaves, and whether that side is lit.
	This is the table to read when a beam leaves a cell by the wrong side, because the usual cause
	is an exit side that was left unchanged."

	<inspectorPresentationOrder: 1 title: 'Sides'>
	^ aBuilder newTable
		  items: #( #north #east #south #west );
		  addColumn: (SpStringTableColumn title: 'Enters from' evaluated: [ :each |
					   each asString ]);
		  addColumn: (SpStringTableColumn title: 'Leaves by' evaluated: [ :each |
					   (self exitSideFor: each)
						   ifNil: [ 'nowhere' ]
						   ifNotNil: [ :side | side asString ] ]);
		  addColumn: (SpStringTableColumn title: 'Lit' evaluated: [ :each |
					   (self isSegmentOnFor: each)
						   ifTrue: [ 'yes' ]
						   ifFalse: [ '' ] ]);
		  yourself
]

{ #category : 'testing' }
Cell >> isOff [
	^self isOn not
]

{ #category : 'testing' }
Cell >> isOn [
	^self activeSegments values anySatisfy: [:each | each = true]
]

{ #category : 'testing' }
Cell >> isSegmentOnFor: aSymbol [
	^self activeSegments at: aSymbol
]

{ #category : 'accessing' }
Cell >> laserEntersFrom: aSymbol [
	| exit |
	self activeSegments at: aSymbol put: true.
	exit := self exitSideFor: aSymbol.
	self activeSegments at: exit put: true.
]

{ #category : 'accessing' }
Cell >> litSides [
	"Answer the sides of me that carry light, in a fixed order. A cell the beam crosses is lit on
	the side it arrives by and on the side it leaves by, a cell that swallows the light is lit on
	one side, and a cell the beam crosses twice is lit on all four. Nothing else is needed to draw
	the beam, which is why the renderers ask this and nothing else."

	^ #( #north #east #south #west ) select: [ :each |
		  self isSegmentOnFor: each ]
]

{ #category : 'printing' }
Cell >> printDetailsOn: aStream [
	"Print what distinguishes me from another cell of my kind at the same place. There is nothing
	but my location, so a mirror adds the way it leans. `Point >> printOn:` puts brackets round
	itself, which would read badly inside my own, so the two coordinates are printed by hand."

	aStream
		print: self gridLocation x;
		nextPut: $@;
		print: self gridLocation y
]

{ #category : 'printing' }
Cell >> printOn: aStream [
	"Say where I am and whether the laser lights me, on one line, since an object is printed in
	many places where only one line fits: a list, an inspector header, a code pane. A subclass
	adds its own detail by overriding printDetailsOn:. For the state of my four sides, inspect me
	and read the Sides tab."

	super printOn: aStream.
	aStream nextPut: $(.
	self printDetailsOn: aStream.
	aStream
		nextPutAll: ', ';
		nextPutAll: (self isOn ifTrue: [ 'on' ] ifFalse: [ 'off' ]);
		nextPut: $)
]

{ #category : 'actions' }
Cell >> rotateClockwise [
	"Turn me clockwise, which for a cell in general is nothing at all. Both rotate messages live
	here so that a click can send one without asking what kind of cell it hit; only a mirror has
	anything to turn."
]

{ #category : 'actions' }
Cell >> rotateCounterClockwise [
	"Turn me counter clockwise, which for a cell in general is nothing at all. See
	`rotateClockwise`."
]
