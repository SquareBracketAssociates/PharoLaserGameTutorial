"
I am the lower half of the outside region of a mirror cell. A click in me turns the mirror counter clockwise, and my hint is the counter clockwise curved arrow of Section 3.7.

Page 101 of the original divides the outside region with one horizontal line at half the height of the cell and decides the direction by which side of it the pointer is on. `containsPoint:` asks for a point strictly below that line, since page 103 gives the line itself to the upper half, which is `CellClickRegionRotateClockwise`.

The line is written in terms of `CellRenderer class >> cellExtent`, not of the region, so it holds at any cell size.
"
Class {
	#name : 'CellClickRegionRotateCounterClockwise',
	#superclass : 'CellClickRegionOutside',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'classifying' }
CellClickRegionRotateCounterClockwise class >> containsPoint: aPoint [
	"Answer whether aPoint is in the lower half of the cell. My sister takes the line itself, so
	I ask for a strictly greater y, and the two of us cover the region without overlapping."

	^aPoint y > (CellRenderer cellExtent y // 2)
]

{ #category : 'hints' }
CellClickRegionRotateCounterClockwise class >> hintElementOfExtent: anExtent [
	"Answer an element drawing the anticlockwise curved arrow at anExtent, at whatever size it is
	given."

	^ LaserGameShapes counterClockwiseArrowElementOfExtent: anExtent
]

{ #category : 'interaction' }
CellClickRegionRotateCounterClockwise class >> mouseUpForCell: aCell withinGrid: aGrid [
	aGrid rotateCellCounterClockwiseAt: aCell gridLocation.
	^aCell
]
