"
I am the innermost click region of a cell: a square of `CellRenderer class >> insideRegionExtent` centred in the cell. A click here asks for the cell to be pushed.

My own subclasses are the four push regions, one per direction. They divide me along my two diagonals, which is what `yForHeadingUpLineWith:` and `yForHeadingDownLineWith:` describe, and `pushRegionForPoint:` answers the one a point falls in.

I sort first (`sortIndex` 1), so a point I contain is mine even though the outside and ignore rectangles contain it too.

"
Class {
	#name : 'CellClickRegionInside',
	#superclass : 'CellClickRegion',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'interaction' }
CellClickRegionInside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid [

	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^ pushRegion canPushCell: aCell withinGrid: aGrid
]

{ #category : 'classifying' }
CellClickRegionInside class >> containsPoint: aPoint [
	"Answer whether aPoint falls in me. Each of my four push subclasses answers one line of the
	truth table of the two diagonals I hold, so none of them has a conditional in it."

	^ self subclassResponsibility
]

{ #category : 'hints' }
CellClickRegionInside class >> hintRegionForPoint: aPoint [
	"Answer the push region aPoint falls in. A click here pushes a cell, and which way it pushes
	is what the hint has to show, so the inside region is the one region that refines its answer."

	^ self pushRegionForPoint: aPoint
]

{ #category : 'interaction' }
CellClickRegionInside class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^pushRegion mouseUpForCell: aCell withinGrid: aGrid
]

{ #category : 'classifying' }
CellClickRegionInside class >> pointIsUnderHeadingDownLine: aPoint [

	| realX realY lineY |
	realX := aPoint x.
	realY := aPoint y.
	lineY := self yForHeadingDownLineWith: realX.
	^ realY < lineY
]

{ #category : 'classifying' }
CellClickRegionInside class >> pointIsUnderHeadingUpLine: aPoint [
	| realX realY lineY |
	realX := aPoint x.
	realY := aPoint y.
	lineY := self yForHeadingUpLineWith: realX.
	^realY < lineY
]

{ #category : 'classifying' }
CellClickRegionInside class >> pushRegionForPoint: aPoint [
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
]

{ #category : 'accessing' }
CellClickRegionInside class >> regionRectangle [
	"CellClickRegionInside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer insideRegionExtent.
	^outer insetBy: (delta // 2)
]

{ #category : 'accessing' }
CellClickRegionInside class >> sortIndex [
	^1
]

{ #category : 'classifying' }
CellClickRegionInside class >> yForHeadingDownLineWith: x [
	"Answer the y of the diagonal running from the top right corner of the cell to the bottom left
	one, at abscissa x. It is written against the cell rather than against the push region, so the
	diagonal passes through the corners at any cell size."

	^CellRenderer cellExtent x - x
]

{ #category : 'classifying' }
CellClickRegionInside class >> yForHeadingUpLineWith: x [
	"Answer the y of the diagonal running from the top left corner of the cell to the bottom
	right one, at abscissa x. This one needs no cell size: the diagonal of a square is y = x."

	^x
]
