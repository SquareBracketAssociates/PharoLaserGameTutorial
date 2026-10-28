"
I am the push region on the west side of the inside region: the triangle between the two diagonals that touches the left edge. A click in me pushes the cell east, away from the edge the pointer is nearest, and my hint is an east arrow.

`containsPoint:` reads the truth table of page 088: a point of mine is under the heading-down line and not under the heading-up line. `CellClickRegionInside` holds the two lines and the tests against them, so the four of us differ in that one expression only.

"
Class {
	#name : 'CellClickRegionPushEast',
	#superclass : 'CellClickRegionInside',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'interaction' }
CellClickRegionPushEast class >> canPushCell: aCell withinGrid: aGrid [
	^aGrid canPushCellEastFromLocation: aCell gridLocation
]

{ #category : 'classifying' }
CellClickRegionPushEast class >> containsPoint: aPoint [
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown and: [underHeadingUp not]
]

{ #category : 'hints' }
CellClickRegionPushEast class >> hintElementOfExtent: anExtent [
	"Answer the east arrow at anExtent."

	^ LaserGameShapes eastArrowElementOfExtent: anExtent
]

{ #category : 'interaction' }
CellClickRegionPushEast class >> mouseUpForCell: aCell withinGrid: aGrid [
	^aGrid pushCellEastFromLocation: aCell gridLocation
]
