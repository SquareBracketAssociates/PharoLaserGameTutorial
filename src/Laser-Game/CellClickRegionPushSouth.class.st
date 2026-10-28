"
I am the push region on the north side of the inside region: the triangle between the two diagonals that touches the top edge. A click in me pushes the cell south, away from the edge the pointer is nearest, and my hint is a south arrow.

`containsPoint:` reads the truth table of page 088: a point of mine is under both lines. Screen coordinates grow downwards, so ""under"" means a smaller y, which is why the triangle at the top of the cell is the one that pushes south. `CellClickRegionInside` holds the two lines and the tests against them, so the four of us differ in that one expression only.

"
Class {
	#name : 'CellClickRegionPushSouth',
	#superclass : 'CellClickRegionInside',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'interaction' }
CellClickRegionPushSouth class >> canPushCell: aCell withinGrid: aGrid [
	^aGrid canPushCellSouthFromLocation: aCell gridLocation
]

{ #category : 'classifying' }
CellClickRegionPushSouth class >> containsPoint: aPoint [
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown and: [underHeadingUp]
]

{ #category : 'hints' }
CellClickRegionPushSouth class >> hintElementOfExtent: anExtent [
	"Answer the south arrow at anExtent."

	^ LaserGameShapes southArrowElementOfExtent: anExtent
]

{ #category : 'interaction' }
CellClickRegionPushSouth class >> mouseUpForCell: aCell withinGrid: aGrid [
	^aGrid pushCellSouthFromLocation: aCell gridLocation
]
