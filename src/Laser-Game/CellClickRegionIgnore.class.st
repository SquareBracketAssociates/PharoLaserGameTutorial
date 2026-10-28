"
I am the margin of a cell, `CellRenderer class >> ignoreRegionOffset` pixels wide, where a click does nothing. A player who clicks close to an edge of a cell is most likely aiming at the cell next to it, so the click is dropped rather than guessed at.

My rectangle is the whole cell, and I sort last (`sortIndex` 3), so I am answered only for a point that neither the inside nor the outside region claims.

"
Class {
	#name : 'CellClickRegionIgnore',
	#superclass : 'CellClickRegion',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'accessing' }
CellClickRegionIgnore class >> regionRectangle [
	^0@0 extent: CellRenderer cellExtent
]

{ #category : 'accessing' }
CellClickRegionIgnore class >> sortIndex [
	^3
]
