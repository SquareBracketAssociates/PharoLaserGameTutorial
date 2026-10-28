"
I am the push region on the south side of the inside region: the triangle between the two diagonals that touches the bottom edge. A click in me pushes the cell north, away from the edge the pointer is nearest, and my hint is a north arrow.

`containsPoint:` reads the truth table of page 088: a point of mine is under neither line. Screen coordinates grow downwards, so ""under"" means a smaller y, which is why the triangle at the bottom of the cell is the one that pushes north. I am also the region a point exactly on both lines falls in, since both tests ask `<`: page 091 settles that boundary by finding the unit test wrong and the code right. `CellClickRegionInside` holds the two lines and the tests against them, so the four of us differ in that one expression only.

"
Class {
	#name : 'CellClickRegionPushNorth',
	#superclass : 'CellClickRegionInside',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'interaction' }
CellClickRegionPushNorth class >> canPushCell: aCell withinGrid: aGrid [
	^aGrid canPushCellNorthFromLocation: aCell gridLocation
]

{ #category : 'classifying' }
CellClickRegionPushNorth class >> containsPoint: aPoint [
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^(underHeadingDown not) and: [underHeadingUp not]

]

{ #category : 'hints' }
CellClickRegionPushNorth class >> hintElementOfExtent: anExtent [
	"Answer the north arrow at anExtent. It is a polygon, so it is drawn at the size it is given."

	^ LaserGameShapes northArrowElementOfExtent: anExtent
]

{ #category : 'interaction' }
CellClickRegionPushNorth class >> mouseUpForCell: aCell withinGrid: aGrid [
	^aGrid pushCellNorthFromLocation: aCell gridLocation
]
