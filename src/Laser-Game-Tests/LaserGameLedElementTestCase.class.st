Class {
	#name : 'LaserGameLedElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'helpers' }
LaserGameLedElementTestCase >> litSegmentsOf: aLed at: anIndex [
	"Answer the names of the segments the digit at anIndex of aLed lights, sorted, so that a test
	can compare them against a list of names without caring about the order."

	| digit |
	digit := aLed digitElements at: anIndex.
	^ ((1 to: digit children size)
		   select: [ :each |
		   (digit children at: each) background paint color = aLed onColor ]
		   thenCollect: [ :each | LaserGameLedElement segmentNames at: each ])
		  asSortedCollection asArray
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testANumberIsShownRightAlignedWithoutLeadingZeros [
	"A number shorter than the display sits at its right, and the digits in front of it light
	nothing at all. An LED that shows 007 for seven would read as another number."

	| led |
	led := LaserGameLedElement digits: 3.
	led value: 5.
	self assertEmpty: (self litSegmentsOf: led at: 1).
	self assertEmpty: (self litSegmentsOf: led at: 2).
	self assert: (self litSegmentsOf: led at: 3) equals: #( #a #c #d #f #g )
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testANumberTooLongForTheDisplayKeepsItsLastDigits [
	"Three digits cannot show a thousand. The last digits are the ones kept, as an odometer does,
	rather than the display going blank or raising."

	| led |
	led := LaserGameLedElement digits: 2.
	led value: 123.
	self assert: (self litSegmentsOf: led at: 1) equals: #( #a #b #d #e #g ).
	self assert: (self litSegmentsOf: led at: 2) equals: #( #a #b #c #d #g )
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testDisplayIsAsWideAsItsDigitsAndTheGapsBetweenThem [
	"A display takes one digit width per digit and one gap between each pair, and it holds one
	element per digit. The size is read from the layout constraints, since nothing is laid out."

	| led |
	led := LaserGameLedElement digits: 3.
	self assert: led digitElements size equals: 3.
	self
		assert: led constraints horizontal resizer size
		equals: (LaserGameLedElement digitExtent x + LaserGameLedElement digitGap * 3)
			- LaserGameLedElement digitGap.
	self
		assert: led constraints vertical resizer size
		equals: LaserGameLedElement digitExtent y
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testEachDigitLightsTheSegmentsOfItsNumber [
	"Eight lights all seven segments, one lights the pair on the right, and zero lights every
	segment but the bar in the middle. Those are the shapes the segment names describe."

	| led |
	led := LaserGameLedElement digits: 1.
	led value: 8.
	self
		assert: (self litSegmentsOf: led at: 1)
		equals: #( #a #b #c #d #e #f #g ).
	led value: 1.
	self assert: (self litSegmentsOf: led at: 1) equals: #( #b #c ).
	led value: 0.
	self assert: (self litSegmentsOf: led at: 1) equals: #( #a #b #c #d #e #f )
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testEveryDigitHoldsOneRectanglePerSegment [
	"A digit is built once, out of seven rectangles, and they stay: showing another number only
	recolours them. The seven sit inside the digit and do not overlap."

	| led digit first |
	led := LaserGameLedElement digits: 2.
	digit := led digitElements first.
	self assert: digit children size equals: LaserGameLedElement segmentNames size.
	first := digit children first.
	led value: 8.
	self assert: digit children size equals: 7.
	self assert: digit children first identicalTo: first.
	LaserGameLedElement segmentNames do: [ :name |
		| bounds |
		bounds := LaserGameLedElement segmentBoundsOf: name.
		self assert: bounds origin >= (0 @ 0).
		self assert: bounds corner <= LaserGameLedElement digitExtent ]
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testHighlightingBrightensTheLitSegments [
	"The counter is highlighted while the laser fires. Highlighting changes the colour of the
	segments that are lit and leaves the others alone: the counter of the beam is almost white
	while the laser fires, and the move counter beside it stays the lavender of a dim segment."

	| led digit lit unlit |
	led := LaserGameLedElement digits: 1.
	led value: 1.
	digit := led digitElements first.
	lit := digit children second.
	unlit := digit children first.
	self deny: led highlighted.
	self
		assert: lit background paint color
		equals: LaserGameColors counterDigitColor.
	led highlighted: true.
	self assert: led highlighted.
	self
		assert: lit background paint color
		equals: LaserGameColors counterDigitHighlightColor.
	self
		assert: unlit background paint color
		equals: LaserGameColors counterDigitOffColor
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testTheDigitsFitInsideTheDisplay [
	"Every digit has to be inside the display, which clips what sticks out of it. A linear layout
	adds its cell spacing around the cells as well as between them, so the gap between two digits
	is a margin on each digit but the first, and the row comes to exactly the width the display
	takes."

	| led spacing used |
	led := LaserGameLedElement digits: 3.
	spacing := led layout cellSpacing.
	used := (led digitElements size + 1 * spacing)
	        + (led digitElements inject: 0 into: [ :sum :each |
			         sum + each constraints horizontal resizer size + each margin left
			         + each margin right ]).
	self assert: used equals: (LaserGameLedElement extentForDigits: 3) x.
	self assert: led digitElements first margin left equals: 0.
	self
		assert: led digitElements second margin left
		equals: LaserGameLedElement digitGap
]

{ #category : 'tests - inspecting' }
LaserGameLedElementTestCase >> testTheSegmentsTabShowsWhichSegmentsEachDigitLights [
	"The Segments tab is segmentsForDigit: read as a table: the ten digits down the side, the
	seven segments across the top, and a mark where a digit lights a segment. The last column
	says which of the ten I am showing at the moment, so the table belongs to this display and
	not only to the class."

	| led builder table titles shown |
	led := LaserGameLedElement digits: 3.
	led value: 108.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := led inspectionSegments: builder.
	self assert: table items asArray equals: (0 to: 9) asArray.
	titles := (table columns collect: [ :each | each title ]) asArray.
	self
		assert: titles
		equals: #( 'Digit' 'a' 'b' 'c' 'd' 'e' 'f' 'g' 'Shown now' ).
	self
		assert:
			((table columns allButFirst allButLast collect: [ :each |
				  each evaluation value: 8 ]) reject: [ :each | each isEmpty ]) size
		equals: 7.
	self assert: (table columns second evaluation value: 1) equals: ''.
	shown := table columns last.
	self assert: (shown evaluation value: 1) equals: 'yes'.
	self assert: (shown evaluation value: 0) equals: 'yes'.
	self assert: (shown evaluation value: 8) equals: 'yes'.
	self assert: (shown evaluation value: 2) equals: ''
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testUnlitSegmentsVanishIntoTheBody [
	"A display is a dark slab, and a segment that is not lit is the colour of that slab, so only
	the lit ones are seen. The display has to carry the slab as its own background: on the ramp
	behind the window an unlit segment would otherwise read as a lit one."

	| led unlit |
	led := LaserGameLedElement digits: 1.
	led value: 1.
	unlit := led digitElements first children first.
	self
		assert: led background paint color
		equals: LaserGameColors counterBodyColor.
	self
		assert: unlit background paint color
		equals: LaserGameColors counterBodyColor.
	self
		assert: LaserGameColors counterDigitOffColor
		equals: LaserGameColors counterBodyColor
]
