"
I am the visual representation of one cell of a grid.

Each cell gets its own element. That is what makes hit testing, redrawing and hint overlays local to one cell: a click is delivered to the element under the pointer, a changed cell replaces one element, and a hint arrow is a child that is added and removed.

I hold the location of my cell inside the grid, and the grid itself, so I can always ask the model for the cell I represent. My subclasses declare which cell model they render with the class-side method modelClass, and `CellRenderer class >> rendererFor:` uses that to pick the right subclass for a cell. One subclass per concrete Cell subclass, no case statement.

Instance variables:
	cellLocation	<Point>	position of my cell inside the grid, 1@1 being the top left cell
	grid		<Grid>	the model I read my cell from
"
Class {
	#name : 'CellRenderer',
	#superclass : 'Object',
	#instVars : [
		'cellLocation',
		'grid'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'constants' }
CellRenderer class >> borderWidth [
	"Answer the width, in pixels, of the border drawn inside the edges of every cell."

	^ 1
]

{ #category : 'constants' }
CellRenderer class >> cellExtent [
	"Answer the size, in pixels, of one cell. Every other size in the package is derived from
	this one, so a cell of another size needs no other change anywhere."

	^50@50
]

{ #category : 'constants' }
CellRenderer class >> crossHairExtent [
	"Answer the size the cross hair under the pointer is drawn at. The shape makes its arms a
	third of the box it is given, so a box of one cell keeps the arms in proportion with the
	cell."

	^ self cellExtent
]

{ #category : 'accessing' }
CellRenderer class >> hintArrowExtent [
	"Answer the size a hint arrow is drawn at: a couple of pixels smaller than a cell, so that
	the arrow keeps clear of the cell border."

	^ self cellExtent - 2
]

{ #category : 'accessing' }
CellRenderer class >> hintArrowOffset [
	"Answer where a hint arrow sits within its cell: centred, which is half of what the cell has
	over the arrow."

	^ (self cellExtent - self hintArrowExtent) // 2
]

{ #category : 'constants' }
CellRenderer class >> ignoreRegionOffset [
	"Answer the width, in pixels, of the margin along the edges of a cell where a click does
	nothing. Four pixels is right at any cell size: the margin is there to keep a click aimed at
	the neighbouring cell from turning this one."

	^4
]

{ #category : 'constants' }
CellRenderer class >> insideRegionExtent [
	"Answer the size of the square in the middle of a cell where a click asks for a push: the
	cell less twenty pixels, so the ring around it keeps its width while the cell grows."

	^self cellExtent - 20
]

{ #category : 'accessing' }
CellRenderer class >> modelClass [
	"Answer the Cell subclass I render. Each concrete renderer answers exactly one."

	^ self subclassResponsibility
]

{ #category : 'constants' }
CellRenderer class >> outsideRegionExtent [
	"Answer the size of the square where a click asks for a rotation: the cell less the ignore
	margin on each side. The margin is what is written down, not the region."

	^self cellExtent - (2 * self ignoreRegionOffset)
]

{ #category : 'instance creation' }
CellRenderer class >> rendererFor: aCell [
	"Answer the renderer class that renders aCell."

	^ self subclasses
		  detect: [ :each | each modelClass = aCell class ]
		  ifNone: [ self error: 'No renderer for ' , aCell class name ]
]

{ #category : 'instance creation' }
CellRenderer class >> rendererFor: aCell grid: aGrid [
	"Answer a renderer for aCell, which stands at its own location within aGrid."

	| renderer |
	renderer := (self rendererFor: aCell) new.
	renderer
		cellLocation: aCell gridLocation;
		grid: aGrid.
	^ renderer
]

{ #category : 'accessing' }
CellRenderer >> cell [
	"Answer the cell I render, read from the grid every time. I hold a location and not a cell, so
	a cell that is replaced in the grid does not leave me showing the old one."

	^ self grid at: self cellLocation
]

{ #category : 'accessing' }
CellRenderer >> cellLocation [
	"Answer the value of cellLocation"

	^ cellLocation
]

{ #category : 'accessing' }
CellRenderer >> cellLocation: anObject [
	"Set the value of cellLocation"

	cellLocation := anObject
]

{ #category : 'accessing' }
CellRenderer >> grid [
	"Answer the value of grid"

	^ grid
]

{ #category : 'accessing' }
CellRenderer >> grid: anObject [
	"Set the value of grid"

	grid := anObject
]

{ #category : 'interaction' }
CellRenderer >> hintColorAt: aPoint [
	"Answer the colour a hint arrow is painted in at aPoint, in the coordinates of my cell. My
	cell reacts to nothing, so the question does not arise here and a neutral grey is answered;
	the mirror renderer asks the click region whether the move is allowed."

	^ LaserGameShapes arrowColor
]

{ #category : 'interaction' }
CellRenderer >> hintRegionAt: aPoint [
	"Answer the click region whose hint applies at aPoint, in the coordinates of my cell, or nil
	when my cell offers no hint at all. Every renderer is asked, and all but the mirror answer
	nothing: a click acts on mirrors only."

	^ nil
]

{ #category : 'interaction' }
CellRenderer >> mouseUpAt: aPoint [
	"Act on a click at aPoint, in the coordinates of my cell, and answer the cell it acted on, or
	nil when nothing happened. Nothing happens here: only a mirror answers a click, so the
	superclass does nothing and the mirror renderer deals with the request."

	^ nil
]

{ #category : 'rendering' }
CellRenderer >> newElement [
	"Answer a new element rendering my cell. The element is square, keeps me as its renderer,
	carries the cell background and border, and holds whatever my subclass draws as children: the
	beam first, then the contents of the cell over it, so that the light does not hide what it
	hits."

	| element |
	element := LaserGameCellElement new.
	element renderer: self.
	element extent: self class cellExtent.
	element geometry: BlRectangleGeometry new.
	self renderBackgroundOn: element.
	self renderBorderOn: element.
	self renderLaserOn: element.
	self renderContentsOn: element.
	^ element
]

{ #category : 'rendering' }
CellRenderer >> renderBackgroundOn: anElement [
	"Paint the cell background. Every cell shares the game board background color."

	anElement background: LaserGameColors gameBoardBackgroundColor
]

{ #category : 'rendering' }
CellRenderer >> renderBeamOn: anElement [
	"Draw the beam my lit cell shows, as one child of anElement. The sides of my cell that carry
	light say the whole of what is drawn, so every kind of cell is drawn here: a blank cell the
	beam crosses, the target it ends in, the mirror it turns at, and any of them crossed twice."

	anElement addChild: (LaserGameShapes
			 laserBeamElementOfExtent: self class cellExtent
			 fromSides: self cell litSides)
]

{ #category : 'rendering' }
CellRenderer >> renderBorderOn: anElement [
	"Draw the cell border. Bloc draws a border inside the bounds of the element, so the
	border costs no space and the cells of a grid stay exactly cellExtent apart."

	anElement border: (BlBorder
			 paint: LaserGameColors cellBorderColor
			 width: self class borderWidth)
]

{ #category : 'rendering' }
CellRenderer >> renderContentsOn: anElement [
	"Draw what is inside the cell, as children of anElement. A cell with nothing inside
	draws nothing, so this is empty here and overridden by the subclasses that have
	contents."
]

{ #category : 'rendering' }
CellRenderer >> renderLaserOn: anElement [
	"Draw the beam where it crosses my cell, as children of anElement. Nothing is drawn while the
	laser is off or while no light reaches my cell, which is why both questions are asked here
	rather than in each kind of cell. What a lit cell draws is #renderBeamOn:, which is the same
	for every kind of cell."

	self grid laserIsActive ifFalse: [ ^ self ].
	self cell isOff ifTrue: [ ^ self ].
	self renderBeamOn: anElement
]
