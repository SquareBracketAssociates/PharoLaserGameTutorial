Class {
	#name : 'LaserGameShapesTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'support' }
LaserGameShapesTestCase >> requestedExtentOf: anElement [
	"Answer the extent anElement was built with, read from its resizers. An element measures
	itself only in a layout pass, so its extent is zero until it is laid out."

	^ anElement constraints horizontal resizer size
	  @ anElement constraints vertical resizer size
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testABeamIsAPaleBandWithABrightCentreOnIt [
	"A beam is an element holding two bars: a pale wide one first, a bright narrow one on top of
	it, both running the whole length of the cell and both centred across it."

	| extent element splatter centre |
	extent := 50 @ 50.
	element := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #west #east ).
	self assert: (self requestedExtentOf: element) equals: extent.
	self assert: element children size equals: 2.
	splatter := element children first.
	centre := element children second.
	self
		assert: splatter background paint color
		equals: LaserGameColors laserBeamSplatterColor.
	self
		assert: centre background paint color
		equals: LaserGameColors laserBeamCenterColor.
	self assert: (self requestedExtentOf: splatter) x equals: extent x.
	self assert: (self requestedExtentOf: centre) x equals: extent x.
	self
		assert: (self requestedExtentOf: centre) y
		< (self requestedExtentOf: splatter) y.
	element children do: [ :each |
		self
			assert: each constraints position + ((self requestedExtentOf: each) / 2)
			equals: extent / 2 ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testABeamThatArrivesFromTwoSidesTurnsInTheMiddle [
	"A mirror sends the beam on by another side, so two half beams meet in the middle of the cell:
	one from the side the light arrives by, one to the side it leaves by."

	| extent beam half |
	extent := 40 @ 40.
	half := extent x // 2.
	beam := LaserGameShapes
		        laserBeamElementOfExtent: extent
		        fromSides: #( #west #north ).
	self assert: beam children size equals: 4.
	self assert: (self requestedExtentOf: beam children first) x equals: half.
	self assert: beam children first constraints position x equals: 0.
	self assert: (self requestedExtentOf: beam children second) y equals: half.
	self assert: beam children second constraints position y equals: 0.
	(beam children asArray first: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamSplatterColor ].
	(beam children asArray last: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamCenterColor ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testABeamThatCrossesItsOwnPathDrawsBothCoresOverBothBands [
	"A cell all four sides of which are lit is crossed twice. Both bands run the whole way across,
	and both bright cores are drawn after them, so neither core is buried under the other band."

	| extent beam |
	extent := 40 @ 40.
	beam := LaserGameShapes
		        laserBeamElementOfExtent: extent
		        fromSides: #( #north #east #south #west ).
	self assert: beam children size equals: 4.
	beam children do: [ :bar |
		self
			assert: ((self requestedExtentOf: bar) x max: (self requestedExtentOf: bar) y)
			equals: extent x ].
	(beam children asArray first: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamSplatterColor ].
	(beam children asArray last: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamCenterColor ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testACrossHairIsTwoBarsCrossingAtTheCentre [
	"A cross hair is an element holding two bars, one wide and one tall, both centred in it."

	| extent element horizontal vertical |
	extent := 60 @ 60.
	element := LaserGameShapes crossHairElementOfExtent: extent.
	self assert: (self requestedExtentOf: element) equals: extent.
	self assert: element children size equals: 2.
	horizontal := element children detect: [ :each |
		              (self requestedExtentOf: each) x
		              > (self requestedExtentOf: each) y ].
	vertical := element children detect: [ :each |
		            (self requestedExtentOf: each) y
		            > (self requestedExtentOf: each) x ].
	element children do: [ :each |
		self
			assert:
				each constraints position + ((self requestedExtentOf: each) / 2)
			equals: extent / 2 ].
	self
		assert: (self requestedExtentOf: horizontal) x
		equals: (self requestedExtentOf: vertical) y
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testAHalfBeamCrossesHalfTheCellFromTheSideItComesFrom [
	"A cell that swallows the light shows the beam only as far as its middle: the west half when
	the west segment is lit, the east half otherwise."

	| extent half |
	extent := 40 @ 40.
	half := extent x // 2.
	{ #west -> 0. #east -> half } do: [ :each |
		| beam |
		beam := LaserGameShapes
			        laserBeamElementOfExtent: extent
			        fromSides: { each key }.
		self assert: (self requestedExtentOf: beam) equals: extent.
		self assert: beam children size equals: 2.
		beam children do: [ :bar |
			self assert: (self requestedExtentOf: bar) x equals: half.
			self assert: bar constraints position x equals: each value.
			self
				assert: bar constraints position y + ((self requestedExtentOf: bar) y / 2)
				equals: extent y / 2 ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testAHalfBeamGoingUpOrDownKeepsTheHalfTheLightComesFrom [
	"The same half beam turned a quarter: the bottom half when the south segment is lit, the top
	half otherwise."

	| extent half |
	extent := 40 @ 40.
	half := extent y // 2.
	{ #north -> 0. #south -> half } do: [ :each |
		| beam |
		beam := LaserGameShapes
			        laserBeamElementOfExtent: extent
			        fromSides: { each key }.
		self assert: (self requestedExtentOf: beam) equals: extent.
		self assert: beam children size equals: 2.
		beam children do: [ :bar |
			self assert: (self requestedExtentOf: bar) y equals: half.
			self assert: bar constraints position y equals: each value.
			self
				assert: bar constraints position x + ((self requestedExtentOf: bar) x / 2)
				equals: extent x / 2 ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testAHalfBeamIsAsThickAsAWholeOne [
	"Half a beam is half as long and no thinner, so a beam that stops in the middle of a cell
	meets a beam that crosses one without a step in it."

	| extent whole |
	extent := 40 @ 40.
	whole := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #west #east ).
	#( #west #east ) do: [ :side |
		| half |
		half := LaserGameShapes
			        laserBeamElementOfExtent: extent
			        fromSides: { side }.
		half children asArray with: whole children asArray do: [ :bar :wholeBar |
			self
				assert: (self requestedExtentOf: bar) y
				equals: (self requestedExtentOf: wholeBar) y.
			self
				assert: bar background paint color
				equals: wholeBar background paint color ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testAVerticalBeamIsTheHorizontalOneTurned [
	"A beam runs across a cell or down it, and the two are the same two bars with their sides
	exchanged, so the two beams meet at the same thickness where a path turns."

	| extent horizontal vertical |
	extent := 50 @ 50.
	horizontal := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #west #east ).
	vertical := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #north #south ).
	self assert: (self requestedExtentOf: vertical) equals: extent.
	self assert: vertical children size equals: 2.
	vertical children asArray
		with: horizontal children asArray
		do: [ :down :across |
			self
				assert: (self requestedExtentOf: down)
				equals: (self requestedExtentOf: across) transposed.
			self
				assert: down background paint color
				equals: across background paint color.
			self
				assert: down constraints position + ((self requestedExtentOf: down) / 2)
				equals: extent / 2 ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testAnArrowElementIsAPolygonOfTheSizeAsked [
	"An arrow is an element with a polygon geometry, not a bitmap: its vertices are the scaled
	points, and it asks for the extent the caller named. The size is read from the resizer, since
	an element measures itself only in a layout pass."

	| extent element |
	extent := 40 @ 40.
	element := LaserGameShapes eastArrowElementOfExtent: extent.
	self assert: element geometry class equals: BlPolygonGeometry.
	self assert: (self requestedExtentOf: element) equals: extent.
	self
		assert: element geometry vertices asArray
		equals:
			(LaserGameShapes
				 pointsOf: LaserGameShapes eastArrowPoints
				 scaledToExtent: extent) asArray
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testEachArrowHasOneTipAndItIsCentredOnTheOtherAxis [
	"An arrow points where its name says: exactly one vertex reaches the far edge, and it sits in
	the middle of the other axis."

	| bounds |
	{ LaserGameShapes northArrowPoints -> [ :point :box | point y = box top and: [ point x = box center x ] ].
	LaserGameShapes southArrowPoints -> [ :point :box | point y = box bottom and: [ point x = box center x ] ].
	LaserGameShapes eastArrowPoints -> [ :point :box | point x = box right and: [ point y = box center y ] ].
	LaserGameShapes westArrowPoints -> [ :point :box | point x = box left and: [ point y = box center y ] ] }
		do: [ :each |
			bounds := Rectangle encompassing: each key.
			self
				assert: (each key select: [ :point | each value value: point value: bounds ]) size
				equals: 1 ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testEachArrowIsSevenVerticesWideEnoughToBeAnArrow [
	"Each of the four vertex arrays is seven points, an outline drawn as a closed polygon."

	{ LaserGameShapes northArrowPoints.
	LaserGameShapes eastArrowPoints.
	LaserGameShapes southArrowPoints.
	LaserGameShapes westArrowPoints } do: [ :points |
		self assert: points size equals: 7.
		points do: [ :each | self assert: each isPoint ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testEveryArrowElementUsesTheVerticesOfItsDirection [
	"Each of the four accessors builds from its own vertex array."

	| extent |
	extent := 30 @ 30.
	{ (LaserGameShapes northArrowElementOfExtent: extent) -> LaserGameShapes northArrowPoints.
	(LaserGameShapes eastArrowElementOfExtent: extent) -> LaserGameShapes eastArrowPoints.
	(LaserGameShapes southArrowElementOfExtent: extent) -> LaserGameShapes southArrowPoints.
	(LaserGameShapes westArrowElementOfExtent: extent) -> LaserGameShapes westArrowPoints }
		do: [ :each |
			self
				assert: each key geometry vertices asArray
				equals: (LaserGameShapes pointsOf: each value scaledToExtent: extent) asArray ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testEveryArrowFillsTheRectangleItIsGiven [
	"An arrow is a polygon whose points are scaled onto the rectangle asked for, so the ink is the
	rectangle and there is no margin anywhere around it to trim. Six arrows are asked at three
	sizes and every one of them is checked."

	#( 24 30 48 ) do: [ :size |
		#( #northArrowElementOfExtent: #southArrowElementOfExtent:
		   #eastArrowElementOfExtent: #westArrowElementOfExtent:
		   #clockwiseArrowElementOfExtent:
		   #counterClockwiseArrowElementOfExtent: ) do: [ :selector |
			| element |
			element := LaserGameShapes perform: selector with: size @ size.
			self
				assert: (Rectangle encompassing: element geometry vertices)
				equals: (0 @ 0 corner: size @ size) ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testPointsScaleToFillTheRequestedExtent [
	"Scaling maps the vertex array onto the rectangle the caller asks for, so the same array
	serves a 12 pixel hint and a 200 pixel drawing."

	{ 12 @ 12. 48 @ 48. 200 @ 120 } do: [ :extent |
		| scaled |
		scaled := LaserGameShapes
			          pointsOf: LaserGameShapes northArrowPoints
			          scaledToExtent: extent.
		self assert: scaled size equals: 7.
		self
			assert: (Rectangle encompassing: scaled)
			equals: (0 @ 0 corner: extent) ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testShapesAreBuiltAtWhateverSizeIsAsked [
	"Vertices scale, so no shape has a size of its own: every shape is built at the size the
	caller asks for, and a small one is as clean as a large one."

	{ 12 @ 12. 50 @ 50. 200 @ 200 } do: [ :extent |
		{ LaserGameShapes northArrowElementOfExtent: extent.
		LaserGameShapes crossHairElementOfExtent: extent } do: [ :element |
			self assert: (self requestedExtentOf: element) equals: extent ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testTheBeamGetsThickerWithTheCell [
	"Both thicknesses are computed from the extent, so the beam keeps its proportions: twice the
	cell, twice the beam. A beam of a cell too small to halve is still one pixel thick."

	| small large |
	small := LaserGameShapes laserBeamElementOfExtent: 30 @ 30 fromSides: #( #west #east ).
	large := LaserGameShapes laserBeamElementOfExtent: 60 @ 60 fromSides: #( #west #east ).
	self
		assert: (self requestedExtentOf: large children first) y
		equals: (self requestedExtentOf: small children first) y * 2.
	self
		assert: (self requestedExtentOf: large children second) y
		equals: (self requestedExtentOf: small children second) y * 2.
	self
		assert: (self requestedExtentOf: small children first) y
		equals: (LaserGameShapes laserBeamSplatterThicknessFor: 30 @ 30).
	self
		assert: (self requestedExtentOf: small children second) y
		equals: (LaserGameShapes laserBeamCenterThicknessFor: 30 @ 30).
	self
		assert: (LaserGameShapes laserBeamCenterThicknessFor: 2 @ 2)
		equals: 1
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testTheClockwiseArrowIsTheCounterClockwiseOneMirrored [
	"The clockwise arrow is the other one flipped horizontally, which is one line of code."

	| left right |
	left := LaserGameShapes counterClockwiseArrowPoints.
	right := LaserGameShapes clockwiseArrowPoints.
	self assert: right size equals: left size.
	left with: right do: [ :each :mirrored |
		self assert: mirrored x equals: each x negated.
		self assert: mirrored y equals: each y ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testTheRingOfTheRotateArrowIsAsWideAsTheStemOfItsHead [
	"The ring between the two radii is exactly as wide as the stem of the arrow head, and the stem
	sits at the left end of the ring. That is what keeps the outline of the shape closed."

	| head ring |
	head := LaserGameShapes rotateArrowHeadPoints.
	ring := LaserGameShapes rotateArrowOuterRadius
	        - LaserGameShapes rotateArrowInnerRadius.
	self assert: ring equals: (head sixth x - head third x).
	self
		assert: LaserGameShapes rotateArrowCenter x
		        - LaserGameShapes rotateArrowOuterRadius
		equals: head third x.
	self
		assert: LaserGameShapes rotateArrowCenter x
		        - LaserGameShapes rotateArrowInnerRadius
		equals: head sixth x
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testTheRotateArrowElementsArePolygonsOfTheSizeAsked [
	"Like the four straight arrows, a rotate arrow is a polygon scaled into the extent asked for."

	{ (#counterClockwiseArrowElementOfExtent:
	 -> LaserGameShapes counterClockwiseArrowPoints).
	(#clockwiseArrowElementOfExtent: -> LaserGameShapes clockwiseArrowPoints) }
		do: [ :each |
			#( 30 48 120 ) do: [ :size |
				| element extent |
				extent := size @ size.
				element := LaserGameShapes perform: each key with: extent.
				self assert: (self requestedExtentOf: element) equals: extent.
				self
					assert: element geometry vertices
					equals:
					(LaserGameShapes pointsOf: each value scaledToExtent: extent) ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testTheRotateArrowIsARingBetweenTwoCirclesWithAHeadOnIt [
	"The curved arrow is two arcs about one centre, cut off by a line, with a straight arrow head
	on the end. Every point of the outline is therefore either a point of that head or a point of
	one of the two circles."

	| center head |
	center := LaserGameShapes rotateArrowCenter.
	head := LaserGameShapes rotateArrowHeadPoints.
	LaserGameShapes counterClockwiseArrowPoints do: [ :each |
		| radius |
		radius := (each - center) r.
		self assert: ((head includes: each) or: [
				 (radius closeTo: LaserGameShapes rotateArrowInnerRadius) or: [
					 radius closeTo: LaserGameShapes rotateArrowOuterRadius ] ]) ]
]

{ #category : 'tests - inspecting' }
LaserGameShapesTestCase >> testTheShapesTabDrawsEveryShapeAtEverySize [
	"The Shapes tab is the claim of pointsOf:scaledToExtent: put on screen: one row per size, one
	shape per column, and every shape fills the square it was asked for. A vertex array written at
	260 pixels has to serve a 12 pixel hint and a 200 pixel drawing, and this is where a reader
	sees that it does."

	| gallery builder presenter |
	gallery := LaserGameShapes inspectionGalleryElement.
	self
		assert: gallery children size
		equals:
			LaserGameShapes inspectionShapeExtents size
			* LaserGameShapes inspectionShapeSelectors size.
	LaserGameShapes inspectionShapeExtents do: [ :size |
			self
				assert: (gallery children select: [ :each |
						 (self requestedExtentOf: each) = (size @ size) ]) size
				equals: LaserGameShapes inspectionShapeSelectors size ].
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	presenter := LaserGameShapes inspectionShapes: builder.
	self assert: presenter class equals: SpMorphPresenter
]
