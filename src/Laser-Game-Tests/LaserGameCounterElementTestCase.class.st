Class {
	#name : 'LaserGameCounterElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'tests' }
LaserGameCounterElementTestCase >> testACounterCentresWhatItHolds [
	"Every counter of the panel is given the same width, wider than any of the four captions, so
	what a counter holds has to be centred in it: left against the border, the display of one
	counter and the display of the next would line up but the captions would not, and every box
	would have a ragged margin on its right. Both children are aligned to the centre of the
	column, which is what a linear layout reads to place them across itself. Where they land is
	Bloc's arithmetic and is not repeated here: nothing is laid out, and no element is opened."

	| counter |
	counter := LaserGameCounterElement labelled: 'Moves' digits: 3.
	self assert: counter layout class equals: BlLinearLayout.
	self
		assert: counter led constraints linear horizontal alignment
		equals: BlElementAlignment horizontal center.
	self
		assert: counter label constraints linear horizontal alignment
		equals: BlElementAlignment horizontal center
]

{ #category : 'tests' }
LaserGameCounterElementTestCase >> testCounterIsATransparentRoundedFrame [
	"A counter is a transparent frame with rounded corners, a two pixel border and a five pixel
	inset, and it takes the size of what it holds."

	| counter |
	counter := LaserGameCounterElement labelled: 'Laser Path' digits: 3.
	self assert: counter background class equals: BlTransparentBackground.
	self assert: counter geometry class equals: BlRoundedRectangleGeometry.
	self assert: counter border width equals: LaserGameCounterElement borderWidth.
	self
		assert: counter border paint color
		equals: LaserGameColors counterBorderColor.
	self
		assert: counter padding
		equals: (BlInsets all: LaserGameCounterElement inset).
	self
		assert: counter constraints horizontal resizer class
		equals: BlLayoutFitContentResizer.
	self
		assert: counter constraints vertical resizer class
		equals: BlLayoutFitContentResizer
]

{ #category : 'tests' }
LaserGameCounterElementTestCase >> testCounterShowsADisplayWithItsCaptionUnderIt [
	"A counter is the display and then the caption, in that order, so the caption is drawn under
	the display."

	| counter |
	counter := LaserGameCounterElement labelled: 'Laser Path' digits: 3.
	self assert: counter children size equals: 2.
	self assert: counter children first identicalTo: counter led.
	self assert: counter children second identicalTo: counter label.
	self assert: counter led class equals: LaserGameLedElement.
	self assert: counter led digitCount equals: 3.
	self assert: counter label text asString equals: 'Laser Path'.
	self assert: counter layout class equals: BlLinearLayout
]

{ #category : 'tests' }
LaserGameCounterElementTestCase >> testTheCounterPassesWhatItIsToldToItsDisplay [
	"A counter holds its display, so the game sets a value on the counter and never looks for the
	display itself."

	| counter |
	counter := LaserGameCounterElement labelled: 'Laser Path' digits: 3.
	self assert: counter value equals: 0.
	self deny: counter highlighted.
	counter value: 17.
	counter highlighted: true.
	self assert: counter led value equals: 17.
	self assert: counter value equals: 17.
	self assert: counter led highlighted.
	self assert: counter highlighted
]
