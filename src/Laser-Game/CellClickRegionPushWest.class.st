"
I am the push region on the east side of the inside region: the triangle between the two diagonals that touches the right edge. A click in me pushes the cell west, away from the edge the pointer is nearest, and my hint is a west arrow.

`containsPoint:` reads the truth table of page 088: a point of mine is under the heading-up line and not under the heading-down line. `CellClickRegionInside` holds the two lines and the tests against them, so the four of us differ in that one expression only.

"
Class {
	#name : 'CellClickRegionPushWest',
	#superclass : 'CellClickRegionInside',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'interaction' }
CellClickRegionPushWest class >> canPushCell: aCell withinGrid: aGrid [
	^aGrid canPushCellWestFromLocation: aCell gridLocation
]

{ #category : 'classifying' }
CellClickRegionPushWest class >> containsPoint: aPoint [
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown not and: [underHeadingUp]
]

{ #category : 'hints' }
CellClickRegionPushWest class >> hintElementOfExtent: anExtent [
	"Answer the west arrow at anExtent."

	^ LaserGameShapes westArrowElementOfExtent: anExtent
]

{ #category : 'interaction' }
CellClickRegionPushWest class >> mouseUpForCell: aCell withinGrid: aGrid [
	^aGrid pushCellWestFromLocation: aCell gridLocation
]
