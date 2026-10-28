"
I test one step of the laser beam: a cell, the side the beam enters it from, and the element that comes next.

Pages 108 and 109 of the 2007 tutorial step through `LaserPathElement >> nextElementIn:` in a debugger, hunting the bug of page 110, and improve what a path element prints along the way. I check the two things that debugging session looked at: what a path element says about itself, and that it follows a mirror after the mirror is turned.
"
Class {
	#name : 'LaserPathElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'tests' }
LaserPathElementTestCase >> testPrintStringNamesTheCellAndTheSideTheBeamEntersFrom [
	"A path element prints which cell the step is about and the side the beam enters it by, which
	is what makes a list of path elements readable."

	| element |
	element := LaserPathElement
		           cell: (MirrorCell leanRight gridLocation: 4 @ 1; yourself)
		           entrySide: #south.
	self
		assert: element printString
		equals:
		'a LaserPathElement(a MirrorCell(4@1 leans right, off) from south)'
]

{ #category : 'tests' }
LaserPathElementTestCase >> testTheNextElementFollowsTheMirrorAfterItIsRotated [
	"Ask the step of the beam directly: the mirror at 4@1 of the demo grid sends a beam that enters
	from the south out to the east, and once it is turned, out to the west. A rotation that left
	the exit sides unchanged would send the beam out the way it went out before, and this is the
	method where that shows."

	| grid mirror element |
	grid := GridExample demoGrid.
	mirror := grid at: 4 @ 1.
	element := LaserPathElement cell: mirror entrySide: #south.
	self assert: mirror isRight.
	self
		assert: (element nextElementIn: grid) cell
		equals: (grid at: 5 @ 1).
	mirror rotate.
	self
		assert: (element nextElementIn: grid) cell
		equals: (grid at: 3 @ 1)
]

{ #category : 'tests' }
LaserPathElementTestCase >> testTheStepTabSaysWhereTheBeamGoesNext [
	"The Step tab answers, for one step of the beam, the three questions nextElementIn: asks: the
	side the beam leaves by, the location it lands on, and whether it stops here. A target cell
	stops it, which is the row that explains the first of the two nil guards."

	| grid step builder table value target |
	grid := GridExample demoGrid.
	step := LaserPathElement cell: grid startingCell entrySide: #south.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := step inspectionStep: builder.
	self
		assert: (table items collect: [ :each | each key ]) asArray
		equals: #( 'Cell' 'Enters from' 'Leaves by' 'Next location' 'Stops here' ).
	value := [ :fact |
	          (table items detect: [ :each | each key = fact ]) value ].
	self assert: (value value: 'Enters from') equals: 'south'.
	self
		assert: (value value: 'Leaves by')
		equals: (step cell exitSideFor: #south) asString.
	self assert: (value value: 'Stops here') equals: 'no'.
	target := LaserPathElement cell: (grid at: 5 @ 1) entrySide: #west.
	table := target inspectionStep: builder.
	value := [ :fact |
	          (table items detect: [ :each | each key = fact ]) value ].
	self assert: (value value: 'Leaves by') equals: 'nowhere'.
	self assert: (value value: 'Next location') equals: 'nowhere'.
	self assert: (value value: 'Stops here') equals: 'yes'
]
