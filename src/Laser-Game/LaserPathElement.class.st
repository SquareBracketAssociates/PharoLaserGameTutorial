"
I am one step of the laser beam: a `Cell` and the side the beam enters it from. `Grid >> calculatePath` starts one of me at the laser and follows `nextElementIn:` until a cell swallows the beam or the beam leaves the board, keeping the chain as the grid's `laserBeamPath`.

`nextElementIn: aGrid` asks my cell which side the beam leaves by, steps one cell that way, and answers the element for the cell it lands on, or `nil` when there is none. `activateCell` and `clearCell` turn the light of my cell on and off for the side the beam enters from.
"
Class {
	#name : 'LaserPathElement',
	#superclass : 'Object',
	#instVars : [
		'cell',
		'entrySide'
	],
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'instance creation' }
LaserPathElement class >> cell: aCell entrySide: aSymbol [
	| model |
	model := self basicNew.
	model
		cell: aCell;
		entrySide: aSymbol.
	model initialize.
	^model
]

{ #category : 'action' }
LaserPathElement >> activateCell [
	self cell laserEntersFrom: self entrySide
]

{ #category : 'accessing' }
LaserPathElement >> cell [
	"Answer the value of cell"

	^ cell
]

{ #category : 'accessing' }
LaserPathElement >> cell: anObject [
	"Set the value of cell"

	cell := anObject
]

{ #category : 'action' }
LaserPathElement >> clearCell [
	self cell clearCell
]

{ #category : 'accessing' }
LaserPathElement >> entrySide [
	"Answer the value of entrySide"

	^ entrySide
]

{ #category : 'accessing' }
LaserPathElement >> entrySide: anObject [
	"Set the value of entrySide"

	entrySide := anObject
]

{ #category : 'inspecting' }
LaserPathElement >> inspectionStep: aBuilder [
	"Answer the questions nextElementIn: asks about me: the side the beam leaves my cell by, the
	location it lands on, and whether it stops here. 'nowhere' means my cell swallows the light,
	which is the first of the two ways a beam path ends."

	<inspectorPresentationOrder: 1 title: 'Step'>
	| exitSide facts |
	exitSide := self cell exitSideFor: self entrySide.
	facts := OrderedCollection new.
	facts add: 'Cell' -> self cell printString.
	facts add: 'Enters from' -> self entrySide asString.
	facts add: 'Leaves by' -> (exitSide
			 ifNil: [ 'nowhere' ]
			 ifNotNil: [ :side | side asString ]).
	facts add: 'Next location' -> (exitSide
			 ifNil: [ 'nowhere' ]
			 ifNotNil: [ :side |
				 (self cell gridLocation + (GridDirection directionFor: side) vector) printString ]).
	facts add: 'Stops here' -> (exitSide
			 ifNil: [ 'yes' ]
			 ifNotNil: [ 'no' ]).
	^ aBuilder newTable
		  items: facts;
		  addColumn: (SpStringTableColumn title: 'Fact' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  yourself
]

{ #category : 'accessing' }
LaserPathElement >> nextElementIn: aGrid [
	| loc dirSym direction vector newLoc nextCell |
	loc := self cell gridLocation.
	dirSym := self cell exitSideFor: self entrySide.
	dirSym isNil ifTrue: [^nil].
	direction := GridDirection directionFor: dirSym.
	vector := direction vector.
	newLoc := loc + vector.
	nextCell := aGrid at: newLoc.
	^nextCell isNil
		ifTrue: [nil]
		ifFalse: [self class cell: nextCell entrySide: direction adjacentInversionSymbol]
]

{ #category : 'printing' }
LaserPathElement >> printOn: aStream [
	"Name the cell this step of the beam is about and the side the beam enters it from. One line,
	since that is what a list, an inspector header and a code pane have room for."

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: self cell;
		nextPutAll: ' from ';
		nextPutAll: self entrySide asString;
		nextPut: $)
]
