"
I am the repository of the shapes the game draws on top of its cells: the four push arrows, the two rotate arrows, the cross hair and the laser beam.

I hold each shape as a vertex array, written at the size it was drawn at, around 260 pixels wide, and I answer elements: `pointsOf:scaledToExtent:` stretches an array onto the rectangle a caller asks for, and `arrowElementFromPoints:ofExtent:` wraps the result in a `BlElement` with a `BlPolygonGeometry`. A shape therefore has no size of its own, and the same array serves a hint of twelve pixels and a drawing of two hundred.

A polygon geometry does not follow the extent of the element that holds it: its vertices are element-local and absolute. Scaling the points is the step that makes a shape fit, and it is why every element I answer covers exactly the rectangle it was asked for. A transformation would scale the drawing without changing the extent, which is right for a finished tree and wrong for a child a layout has to measure.

I am a class-side repository: no instance of me is ever created. The colours I paint with, `arrowColor` and `crossHairColor`, are defaults; a caller that knows whether a move is allowed sets its own on the element it gets.

"
Class {
	#name : 'LaserGameShapes',
	#superclass : 'Object',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> arcPointsFromAngle: startDegrees toAngle: stopDegrees radius: aRadius [
	"Answer the points of an arc of aRadius about my rotate arrow centre, running from
	startDegrees to stopDegrees. Angles are measured anticlockwise from east, and the sine is
	subtracted because y grows downwards."

	| center step |
	center := self rotateArrowCenter.
	step := stopDegrees - startDegrees / self rotateArrowArcSteps.
	^ (0 to: self rotateArrowArcSteps) collect: [ :each |
		  | angle |
		  angle := (startDegrees + (each * step)) degreesToRadians.
		  (center x + (aRadius * angle cos))
		  @ (center y - (aRadius * angle sin)) ]
]

{ #category : 'accessing' }
LaserGameShapes class >> arrowColor [
	"Answer the colour an arrow is painted in when nobody says otherwise. A caller that knows
	whether the move it hints at is allowed sets its own colour instead."

	^ Color gray
]

{ #category : 'building' }
LaserGameShapes class >> arrowElementFromPoints: anArrayOfPoints ofExtent: anExtent [
	"Answer an element of anExtent whose geometry is the outline anArrayOfPoints describes. The
	outline is a polygon, so Alexandrie fills it at whatever size it is given: the shape is a list
	of vertices and a colour, not a picture of pixels."

	^ BlElement new
		  geometry: (BlPolygonGeometry vertices:
					   (self pointsOf: anArrayOfPoints scaledToExtent: anExtent));
		  extent: anExtent;
		  background: self arrowColor;
		  yourself
]

{ #category : 'shapes' }
LaserGameShapes class >> clockwiseArrowElementOfExtent: anExtent [
	"Answer an element drawing the clockwise rotate arrow at anExtent."

	^ self
		  arrowElementFromPoints: self clockwiseArrowPoints
		  ofExtent: anExtent
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> clockwiseArrowPoints [
	"Answer the outline of the arrow that turns a mirror clockwise: the other one flipped
	horizontally."

	^ self counterClockwiseArrowPoints collect: [ :each |
		  each x negated @ each y ]
]

{ #category : 'shapes' }
LaserGameShapes class >> counterClockwiseArrowElementOfExtent: anExtent [
	"Answer an element drawing the anticlockwise rotate arrow at anExtent."

	^ self
		  arrowElementFromPoints: self counterClockwiseArrowPoints
		  ofExtent: anExtent
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> counterClockwiseArrowPoints [
	"Answer the outline of the arrow that turns a mirror anticlockwise: the head, then the outer
	arc from the head round to the cut, the cut itself, and the inner arc back. The result is one
	closed outline, so it draws as a single polygon."

	| head |
	head := self rotateArrowHeadPoints.
	^ { head first. head second. head third }
	  , (self
			   arcPointsFromAngle: 180
			   toAngle: self rotateArrowCutAngle
			   radius: self rotateArrowOuterRadius)
	  , (self
			   arcPointsFromAngle: self rotateArrowCutAngle
			   toAngle: 180
			   radius: self rotateArrowInnerRadius)
	  , { head sixth. head seventh }
]

{ #category : 'building' }
LaserGameShapes class >> crossHairBarOfExtent: aBarExtent within: anExtent [
	"Answer one bar of a cross hair, centred in a shape of anExtent."

	^ BlElement new
		  extent: aBarExtent;
		  position: (anExtent - aBarExtent) / 2;
		  background: self crossHairColor;
		  yourself
]

{ #category : 'accessing' }
LaserGameShapes class >> crossHairColor [
	"Answer the colour of a cross hair."

	^ Color black
]

{ #category : 'shapes' }
LaserGameShapes class >> crossHairElementOfExtent: anExtent [
	"Answer a cross hair of anExtent: two bars crossing at the centre. The arms are a third of the
	shape and the bars a fifth of that, so the figure holds its proportions at any size. A cell
	puts one under the pointer while the pointer is over a hint of a mirror."

	| span thickness |
	span := (anExtent x min: anExtent y) // 3.
	thickness := (span // 5) max: 1.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: (self crossHairBarOfExtent: span @ thickness within: anExtent);
		  addChild: (self crossHairBarOfExtent: thickness @ span within: anExtent);
		  yourself
]

{ #category : 'building' }
LaserGameShapes class >> eastArrowElementOfExtent: anExtent [
	"Answer an arrow of anExtent that points east."

	^ self arrowElementFromPoints: self eastArrowPoints ofExtent: anExtent
]

{ #category : 'vertices' }
LaserGameShapes class >> eastArrowPoints [
	"Answer the outline of an arrow that points east, as seven vertices of a closed polygon."

	^ { 0 @ 80. 150 @ 80. 150 @ 0. 260 @ 100. 150 @ 200. 150 @ 120. 0 @ 120 }
]

{ #category : 'building' }
LaserGameShapes class >> horizontalLaserBeamBarOfExtent: anExtent sides: aCollection thickness: aThickness color: aColor [
	"Answer the bar of a beam that runs across a cell of anExtent, as thick as aThickness and
	painted in aColor. It runs the whole way when both the west and the east side of the cell are
	lit, and half the way, from the lit side to the middle, when only one of them is."

	| length left |
	length := ((aCollection includes: #west) and: [
		           aCollection includes: #east ])
		          ifTrue: [ anExtent x ]
		          ifFalse: [ anExtent x // 2 ].
	left := (aCollection includes: #west)
		        ifTrue: [ 0 ]
		        ifFalse: [ anExtent x - length ].
	^ self
		  laserBeamBarOfExtent: length @ aThickness
		  at: left @ ((anExtent y - aThickness) / 2)
		  color: aColor
]

{ #category : 'inspecting' }
LaserGameShapes class >> inspectionGalleryElement [
	"Answer one element holding every shape I can make, drawn once at each of
	#inspectionShapeExtents: one row per size, the shapes of #inspectionShapeSelectors left to
	right. Each shape is asked for the square it is given, so a row that holds its proportions is
	the proof that one vertex array serves every size."

	| gap canvas top width |
	gap := 10.
	canvas := BlElement new
		          background: Color white;
		          yourself.
	top := gap.
	width := gap.
	self inspectionShapeExtents do: [ :size |
			| left |
			left := gap.
			self inspectionShapeSelectors do: [ :selector |
					canvas addChild: ((self perform: selector with: size @ size)
							 position: left @ top;
							 yourself).
					left := left + size + gap ].
			width := width max: left.
			top := top + size + gap ].
	canvas extent: width @ top.
	^ canvas
]

{ #category : 'inspecting' }
LaserGameShapes class >> inspectionShapeExtents [
	"Answer the sizes the Shapes tab draws every shape at. Three sizes are enough to show that a
	vertex array holds its proportions: the size of a hint, the size of a cell, and larger."

	^ #( 30 50 80 )
]

{ #category : 'inspecting' }
LaserGameShapes class >> inspectionShapeSelectors [
	"Answer the selectors the Shapes tab asks for one shape each, in the order it draws them: the
	four arrows a hint shows, the two rotate arrows, and the cross hair."

	^ #( #northArrowElementOfExtent: #eastArrowElementOfExtent:
	     #southArrowElementOfExtent: #westArrowElementOfExtent:
	     #clockwiseArrowElementOfExtent: #counterClockwiseArrowElementOfExtent:
	     #crossHairElementOfExtent: )
]

{ #category : 'inspecting' }
LaserGameShapes class >> inspectionShapes: aBuilder [
	"Show every shape I can make, each one drawn at three sizes. I hold vertex arrays written at
	around 260 pixels and a scaling step, and nothing says whether that step is right until the
	same arrow is seen small and large side by side."

	<inspectorPresentationOrder: 1 title: 'Shapes'>
	^ aBuilder newMorph
		  morph: self inspectionGalleryElement asPreviewMorph;
		  yourself
]

{ #category : 'building' }
LaserGameShapes class >> laserBeamBarOfExtent: aBarExtent at: aPoint color: aColor [
	"Answer one bar of a beam, of aBarExtent and painted in aColor, at aPoint of the cell."

	^ BlElement new
		  extent: aBarExtent;
		  position: aPoint;
		  background: aColor;
		  yourself
]

{ #category : 'beam geometry' }
LaserGameShapes class >> laserBeamCenterThicknessFor: anExtent [
	"Answer how thick the bright core of the beam is in a cell of anExtent: half the pale band it
	sits on, and never less than one pixel."

	^ ((anExtent x min: anExtent y) // 6) max: 1
]

{ #category : 'building' }
LaserGameShapes class >> laserBeamElementOfExtent: anExtent fromSides: aCollection [
	"Answer an element of anExtent drawing the beam of a cell lit on the sides aCollection names.
	One bar is drawn for each of the two axes light runs along: the whole way across when both
	sides of that axis are lit, and from the lit side to the middle otherwise. Two opposite sides
	are a cell the beam goes straight through, two sides at a right angle are the turn at a mirror,
	one side is the half beam a cell that swallows the light shows, and four sides are a beam that
	crosses its own path. The pale bands are drawn first and the bright cores over them, so a
	crossing shows both cores."

	| element across down |
	across := aCollection select: [ :each | #( #west #east ) includes: each ].
	down := aCollection select: [ :each | #( #north #south ) includes: each ].
	element := BlElement new
		           extent: anExtent;
		           background: Color transparent;
		           yourself.
	{
		(self laserBeamSplatterThicknessFor: anExtent)
		-> LaserGameColors laserBeamSplatterColor.
		(self laserBeamCenterThicknessFor: anExtent)
		-> LaserGameColors laserBeamCenterColor } do: [ :each |
		across ifNotEmpty: [
			element addChild: (self
					 horizontalLaserBeamBarOfExtent: anExtent
					 sides: across
					 thickness: each key
					 color: each value) ].
		down ifNotEmpty: [
			element addChild: (self
					 verticalLaserBeamBarOfExtent: anExtent
					 sides: down
					 thickness: each key
					 color: each value) ] ].
	^ element
]

{ #category : 'beam geometry' }
LaserGameShapes class >> laserBeamSplatterThicknessFor: anExtent [
	"Answer how thick the pale part of the beam is in a cell of anExtent: a third of the cell, and
	never less than one pixel. The thickness follows the cell size, so the beam keeps its
	proportions at any size."

	^ ((anExtent x min: anExtent y) // 3) max: 1
]

{ #category : 'building' }
LaserGameShapes class >> northArrowElementOfExtent: anExtent [
	"Answer an arrow of anExtent that points north."

	^ self arrowElementFromPoints: self northArrowPoints ofExtent: anExtent
]

{ #category : 'vertices' }
LaserGameShapes class >> northArrowPoints [
	"Answer the outline of an arrow that points north, as seven vertices of a closed polygon. The
	numbers are written at the size the arrow was drawn at, a little over 260 pixels; every caller
	scales them to the size it needs."

	^ { 100 @ 0. 200 @ 110. 120 @ 110. 120 @ 260. 80 @ 260. 80 @ 110. 0 @ 110 }
]

{ #category : 'scaling' }
LaserGameShapes class >> pointsOf: anArrayOfPoints scaledToExtent: anExtent [
	"Answer anArrayOfPoints moved to the origin and stretched to fill anExtent exactly. The vertex
	arrays are written at the size the arrows were drawn at, around 260 pixels, and every user asks
	for the size it needs. A polygon geometry does not follow the extent of its element, so this is
	the step that makes one vertex array serve a 12 pixel hint and a 200 pixel drawing."

	| bounds scale |
	bounds := Rectangle encompassing: anArrayOfPoints.
	scale := anExtent x / bounds width @ (anExtent y / bounds height).
	^ anArrayOfPoints collect: [ :each |
		  ((each - bounds origin) * scale) asFloatPoint ]
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowArcSteps [
	"Answer how many segments an arc of the curved arrow is drawn with. A polygon has as many
	corners as it is given, and two dozen are enough for the largest cell the game uses."

	^ 24
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowCenter [
	"Answer the centre both arcs of the curved arrow turn about."

	^ 282 @ 240
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowCutAngle [
	"Answer where the ring of the curved arrow stops, in degrees measured anticlockwise from east:
	the angle of the line from the centre of the arcs to the top right corner of the 450 pixel
	square the arrow is drawn in. The ring is open there, which is where the head sits."

	| corner |
	corner := 450 @ 0 - self rotateArrowCenter.
	^ (corner y negated arcTan: corner x) radiansToDegrees
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowHeadPoints [
	"Answer the arrow head of the curved arrow: the south arrow with almost no stem, since the ring
	is the stem, moved to where the ring ends. The two points in the middle, at the top of the
	stem, are where the ring begins, so the outline replaces them with the ends of the two arcs."

	^ { 100 @ 260. 40 @ 150. 80 @ 150. 80 @ 141. 120 @ 141. 120 @ 150. 160 @ 150 }
		  collect: [ :each | each + (2 @ 100) ]
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowInnerRadius [
	"Answer the radius of the inner arc of the curved arrow."

	^ 160
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowOuterRadius [
	"Answer the radius of the outer arc of the curved arrow."

	^ 200
]

{ #category : 'building' }
LaserGameShapes class >> southArrowElementOfExtent: anExtent [
	"Answer an arrow of anExtent that points south."

	^ self arrowElementFromPoints: self southArrowPoints ofExtent: anExtent
]

{ #category : 'vertices' }
LaserGameShapes class >> southArrowPoints [
	"Answer the outline of an arrow that points south, as seven vertices of a closed polygon."

	^ { 100 @ 260. 0 @ 150. 80 @ 150. 80 @ 0. 120 @ 0. 120 @ 150. 200 @ 150 }
]

{ #category : 'building' }
LaserGameShapes class >> verticalLaserBeamBarOfExtent: anExtent sides: aCollection thickness: aThickness color: aColor [
	"Answer the bar of a beam that runs up and down a cell of anExtent, as thick as aThickness and
	painted in aColor. It runs the whole way when both the north and the south side of the cell are
	lit, and half the way, from the lit side to the middle, when only one of them is."

	| length top |
	length := ((aCollection includes: #north) and: [
		           aCollection includes: #south ])
		          ifTrue: [ anExtent y ]
		          ifFalse: [ anExtent y // 2 ].
	top := (aCollection includes: #north)
		       ifTrue: [ 0 ]
		       ifFalse: [ anExtent y - length ].
	^ self
		  laserBeamBarOfExtent: aThickness @ length
		  at: (anExtent x - aThickness) / 2 @ top
		  color: aColor
]

{ #category : 'building' }
LaserGameShapes class >> westArrowElementOfExtent: anExtent [
	"Answer an arrow of anExtent that points west."

	^ self arrowElementFromPoints: self westArrowPoints ofExtent: anExtent
]

{ #category : 'vertices' }
LaserGameShapes class >> westArrowPoints [
	"Answer the outline of an arrow that points west, as seven vertices of a closed polygon."

	^ { 260 @ 80. 110 @ 80. 110 @ 0. 0 @ 100. 110 @ 200. 110 @ 120. 260 @ 120 }
]
