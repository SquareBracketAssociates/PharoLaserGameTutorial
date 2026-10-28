"
I render a TargetCell: a background, a border, a circle and its crosshairs, and I show whether my cell model is lit by the laser.

I am selected for a cell by `CellRenderer class >> rendererFor:`, which matches my modelClass against the class of the cell.
"
Class {
	#name : 'TargetCellRenderer',
	#superclass : 'CellRenderer',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'accessing' }
TargetCellRenderer class >> centerInset [
	"Answer how far, in pixels, the filled center of the target stays inside the ring around it."

	^ 4
]

{ #category : 'accessing' }
TargetCellRenderer class >> modelClass [
	^ TargetCell
]

{ #category : 'accessing' }
TargetCellRenderer class >> outlineWidth [
	"Answer the thickness, in pixels, of the target outline: the crosshairs and the ring. Both are
	two pixel strokes."

	^ 2
]

{ #category : 'drawing' }
TargetCellRenderer >> addOutlineLineFrom: aPoint to: anotherPoint on: anElement [
	"Add one line of the target outline to anElement. Both points are cell local, and the stroke is
	centered on the line, as the mirror's is."

	| line |
	line := BlElement new.
	line extent: self class cellExtent.
	line geometry: (BlLineGeometry from: aPoint to: anotherPoint).
	line outskirts: BlOutskirts centered.
	line border: (BlBorder
			 paint: LaserGameColors targetCenterColor
			 width: self class outlineWidth).
	anElement addChild: line
]

{ #category : 'drawing' }
TargetCellRenderer >> centerColor [
	"Answer the fill of the target center: one color while the laser reaches my cell, another
	while it does not."

	^ self cell isOn
		  ifTrue: [ LaserGameColors targetCenterColorActive ]
		  ifFalse: [ LaserGameColors targetCenterColorIdle ]
]

{ #category : 'drawing' }
TargetCellRenderer >> crossHairInset [
	"Answer how far, in pixels, each end of the crosshairs stays inside the edge of the cell."

	^ 6 @ 6
]

{ #category : 'drawing' }
TargetCellRenderer >> innerRadius [
	"Answer the radius of the filled center of the target, which stays inside the ring."

	^ self radius - self class centerInset
]

{ #category : 'drawing' }
TargetCellRenderer >> newCircleOfRadius: aRadius [
	"Answer a circular element of aRadius, placed around the middle of the cell. A circle geometry
	inscribes its circle in the bounds of its element, so the element is a square of the diameter
	and sits one radius up and to the left of the middle."

	| middle circle |
	middle := self class cellExtent - 1 // 2.
	circle := BlElement new.
	circle geometry: BlCircleGeometry new.
	circle extent: (aRadius * 2) asPoint.
	circle position: middle - aRadius.
	^ circle
]

{ #category : 'accessing' }
TargetCellRenderer >> radius [
	"Answer the radius of the ring drawn in a target cell. It is worked out from the cell size, so
	that the ring grows with the cell, and clamped at ten so that it stops growing once the cell
	is large enough."

	^(self class cellExtent x // 2 - 8) min: 10
]

{ #category : 'drawing' }
TargetCellRenderer >> renderCenterOn: anElement [
	"The filled disc inside the ring. Its color is the whole of what the target says about the
	state of the game."

	| center |
	center := self newCircleOfRadius: self innerRadius.
	center background: self centerColor.
	anElement addChild: center
]

{ #category : 'rendering' }
TargetCellRenderer >> renderContentsOn: anElement [
	"A target is a crosshair, a ring around the middle of the cell, and a disc inside the ring
	showing whether the laser reaches my cell."

	self renderCrossHairsOn: anElement.
	self renderRingOn: anElement.
	self renderCenterOn: anElement
]

{ #category : 'drawing' }
TargetCellRenderer >> renderCrossHairsOn: anElement [
	"Two lines crossing in the middle of the cell, each inset from the two edges it points at."

	| inset delta middle |
	inset := self crossHairInset.
	delta := self class cellExtent - 1.
	middle := delta // 2.
	self
		addOutlineLineFrom: inset x @ middle y
		to: delta x - inset x @ middle y
		on: anElement.
	self
		addOutlineLineFrom: middle x @ inset y
		to: middle x @ (delta y - inset y)
		on: anElement
]

{ #category : 'drawing' }
TargetCellRenderer >> renderRingOn: anElement [
	"The ring of the target: an outline, with nothing painted inside it, so the crosshairs stay
	visible through it."

	| ring |
	ring := self newCircleOfRadius: self radius.
	ring outskirts: BlOutskirts centered.
	ring border: (BlBorder
			 paint: LaserGameColors targetCenterColor
			 width: self class outlineWidth).
	anElement addChild: ring
]
