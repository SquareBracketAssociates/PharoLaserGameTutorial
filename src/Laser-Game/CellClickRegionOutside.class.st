"
I am the ring between the ignore margin and the inside region: a square of `CellRenderer class >> outsideRegionExtent` centred in the cell, minus the inside region, which sorts before me. A click here asks for the cell to be rotated.

My own subclasses are the two rotate regions, clockwise and counter-clockwise, and `rotateRegionForPoint:` answers the one a point falls in.

I sort second (`sortIndex` 2).

"
Class {
	#name : 'CellClickRegionOutside',
	#superclass : 'CellClickRegion',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'interaction' }
CellClickRegionOutside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	^true
]

{ #category : 'classifying' }
CellClickRegionOutside class >> containsPoint: aPoint [
	"Answer whether aPoint falls in me. My two subclasses split the region between them, so each
	of them answers it; I only say that the question belongs to them."

	^ self subclassResponsibility
]

{ #category : 'hints' }
CellClickRegionOutside class >> hintRegionForPoint: aPoint [
	"Answer the rotate region aPoint falls in. A click here turns a mirror, and which way it turns
	is what the hint has to show, so the outside region refines its answer just as the inside one
	does."

	^ self rotateRegionForPoint: aPoint
]

{ #category : 'interaction' }
CellClickRegionOutside class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	| rotateRegion |
	rotateRegion := self rotateRegionForPoint: aPoint.
	^rotateRegion mouseUpForCell: aCell withinGrid: aGrid
]

{ #category : 'accessing' }
CellClickRegionOutside class >> regionRectangle [
	"CellClickRegionOutside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer outsideRegionExtent.
	^outer insetBy: (delta // 2)
]

{ #category : 'classifying' }
CellClickRegionOutside class >> rotateRegionForPoint: aPoint [
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
]

{ #category : 'accessing' }
CellClickRegionOutside class >> sortIndex [
	^2
]
