"
I render a MirrorCell: a background, a border and the mirror itself, drawn as a thick diagonal leaning one way or the other according to the orientation of my cell model.

I am selected for a cell by `CellRenderer class >> rendererFor:`, which matches my modelClass against the class of the cell.
"
Class {
	#name : 'MirrorCellRenderer',
	#superclass : 'CellRenderer',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'constants' }
MirrorCellRenderer class >> mirrorWidth [
	"Answer the thickness, in pixels, of the mirror: a two pixel stroke."

	^ 2
]

{ #category : 'accessing' }
MirrorCellRenderer class >> modelClass [
	^ MirrorCell
]

{ #category : 'drawing' }
MirrorCellRenderer >> addMirrorFrom: aPoint to: anotherPoint on: anElement [
	"Add the mirror to anElement as a child carrying a line geometry. The child covers the whole
	cell, so both points are cell local, and the stroke is centered on the line so that the
	mirror is as thick on one side of it as on the other."

	| mirror |
	mirror := BlElement new.
	mirror extent: self class cellExtent.
	mirror geometry: (BlLineGeometry from: aPoint to: anotherPoint).
	mirror outskirts: BlOutskirts centered.
	mirror border: (BlBorder
			 paint: LaserGameColors mirrorColor
			 width: self class mirrorWidth).
	anElement addChild: mirror
]

{ #category : 'drawing' }
MirrorCellRenderer >> cornerInset [
	"Answer how far, in pixels, the ends of the mirror stay clear of the corners of the cell."

	^8@8
]

{ #category : 'interaction' }
MirrorCellRenderer >> hintColorAt: aPoint [
	"Answer the colour of the hint arrow at aPoint, in the coordinates of my cell. The arrow says
	whether the move it offers could actually be made. The region the point falls in knows — the
	outside region always allows a turn, and the inside region asks the push region whether the
	cell beside mine would let my cell through."

	^ ((CellClickRegion clickRegionForPoint: aPoint)
		   canActOnCellAtPoint: aPoint
		   cell: self cell
		   withinGrid: self grid)
		  ifTrue: [ LaserGameColors allowActionArrowColor ]
		  ifFalse: [ LaserGameColors denyActionArrowColor ]
]

{ #category : 'interaction' }
MirrorCellRenderer >> hintRegionAt: aPoint [
	"Answer the region whose hint applies at aPoint: a mirror reacts to a click, and which of its
	actions is meant depends on where in the cell the pointer is. The region that contains the
	point has the last word, so a point near the middle answers one of the four push regions.
	The point is already in the coordinates of my cell, since the click is delivered to the
	element of the cell it landed on."

	^ (CellClickRegion clickRegionForPoint: aPoint) hintRegionForPoint: aPoint
]

{ #category : 'interaction' }
MirrorCellRenderer >> mouseUpAt: aPoint [
	"Act on a click at aPoint, in the coordinates of my cell, and answer the cell it acted on, or
	nil when the region aPoint falls in can do nothing. The region decides both questions: the
	outside region turns my mirror one way or the other, the inside region pushes it when there
	is room, and the ignore margin does nothing. The cell and the grid are passed down to the
	region, because a region knows what a click means and nothing else does."

	| region |
	region := CellClickRegion clickRegionForPoint: aPoint.
	^ (region
		   canActOnCellAtPoint: aPoint
		   cell: self cell
		   withinGrid: self grid)
		  ifTrue: [
		  region
			  mouseUpWithinCellAtPoint: aPoint
			  cell: self cell
			  withinGrid: self grid ]
		  ifFalse: [ nil ]
]

{ #category : 'drawing' }
MirrorCellRenderer >> renderContentsLeanLeftOn: anElement [
	"Draw the mirror from the top left corner of the cell to the bottom right one, inset from
	both."

	| inset delta |
	inset := self cornerInset.
	delta := self class cellExtent - 1.
	self
		addMirrorFrom: inset
		to: delta - inset
		on: anElement
]

{ #category : 'drawing' }
MirrorCellRenderer >> renderContentsLeanRightOn: anElement [
	"Draw the mirror from the top right corner of the cell to the bottom left one, inset from
	both."

	| inset delta |
	inset := self cornerInset.
	delta := self class cellExtent - 1.
	self
		addMirrorFrom: delta x - inset x @ inset y
		to: inset x @ (delta y - inset y)
		on: anElement
]

{ #category : 'rendering' }
MirrorCellRenderer >> renderContentsOn: anElement [
	"A mirror is one diagonal, leaning the way my cell leans."

	self cell isLeft
		ifTrue: [ self renderContentsLeanLeftOn: anElement ]
		ifFalse: [ self renderContentsLeanRightOn: anElement ]
]
