"
I am the upper half of the outside region of a mirror cell. A click in me turns the mirror clockwise, and my hint is the clockwise curved arrow of Section 3.7.

Page 101 of the original divides the outside region with one horizontal line at half the height of the cell and decides the direction by which side of it the pointer is on. `containsPoint:` is that line, and a point exactly on it is mine: page 103 counts the line as part of the upper half.

The line is written in terms of `CellRenderer class >> cellExtent`, not of the region, so it holds at any cell size. My sister `CellClickRegionRotateCounterClockwise` asks the opposite question, and the two of us cover the region without overlapping.
"
Class {
	#name : 'CellClickRegionRotateClockwise',
	#superclass : 'CellClickRegionOutside',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'classifying' }
CellClickRegionRotateClockwise class >> containsPoint: aPoint [
	"Answer whether aPoint is in the upper half of the cell. The line is half the height of the
	cell rather than a number of pixels, so it follows the cell size. A point exactly on the line
	is mine."

	^aPoint y <= (CellRenderer cellExtent y // 2)
]

{ #category : 'hints' }
CellClickRegionRotateClockwise class >> hintElementOfExtent: anExtent [
	"Answer an element drawing the clockwise curved arrow at anExtent, at whatever size it is
	given."

	^ LaserGameShapes clockwiseArrowElementOfExtent: anExtent
]

{ #category : 'interaction' }
CellClickRegionRotateClockwise class >> mouseUpForCell: aCell withinGrid: aGrid [
	aGrid rotateCellClockwiseAt: aCell gridLocation.
	^aCell
]
