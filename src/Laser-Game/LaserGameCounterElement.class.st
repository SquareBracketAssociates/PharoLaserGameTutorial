"
I am one counter of the control panel: a framed column holding an LED display with a caption under it.

I replace `wrapPanel:label:` of page 141, which wraps a morph in an `AlignmentMorph` column with a two pixel inset bevel, rounded corners, a five pixel inset and a transparent colour, and then adds a `StringMorph` label. The comment on that method says the label goes above the panel; it is added after it, so it is drawn below, and that is where mine sits.

```
LaserGameCounterElement labelled: 'Laser Path' digits: 3
```

I hold the display, so `value:` and `highlighted:` reach it without anyone searching my children. That search is what page 142 has to do: its `findLaserPathCounter` walks every morph of the game looking for the one named `'laserPath'`.

Instance variables:
- `led`: the `LaserGameLedElement` I show.
- `label`: the text element under it.

"
Class {
	#name : 'LaserGameCounterElement',
	#superclass : 'BlElement',
	#instVars : [
		'led',
		'label'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'constants' }
LaserGameCounterElement class >> borderWidth [
	"Answer the width, in pixels, of my frame."

	^ 2
]

{ #category : 'constants' }
LaserGameCounterElement class >> cornerRadius [
	"Answer the radius, in pixels, of my rounded corners."

	^ 6
]

{ #category : 'constants' }
LaserGameCounterElement class >> inset [
	"Answer the space, in pixels, between my frame and what I hold, and between the display and
	the label."

	^ 5
]

{ #category : 'constants' }
LaserGameCounterElement class >> labelFontSize [
	"Answer the size, in points, of my caption."

	^ 10
]

{ #category : 'instance creation' }
LaserGameCounterElement class >> labelled: aString digits: anInteger [
	"Answer a counter of anInteger digits captioned aString."

	| counter |
	counter := self new.
	counter digits: anInteger.
	counter labelText: aString.
	^ counter
]

{ #category : 'accessing' }
LaserGameCounterElement >> digits: anInteger [
	"Show anInteger digits. The display is narrower than I am, since my width is stated for all
	four counters of the panel and their captions, so it is centred rather than left against my
	border."

	led ifNotNil: [ :each | self removeChild: each ].
	led := LaserGameLedElement digits: anInteger.
	led constraintsDo: [ :aConstraints |
		aConstraints linear horizontal alignCenter ].
	self addChild: led
]

{ #category : 'accessing' }
LaserGameCounterElement >> highlighted [
	"Answer whether my display is bright."

	^ self led highlighted
]

{ #category : 'accessing' }
LaserGameCounterElement >> highlighted: aBoolean [
	"Light my display brightly, or dimly."

	self led highlighted: aBoolean
]

{ #category : 'initialization' }
LaserGameCounterElement >> initialize [
	"A counter is a transparent rounded frame around a column: the display, then the caption under
	it, one inset apart."

	super initialize.
	self background: BlTransparentBackground new.
	self geometry: (BlRoundedRectangleGeometry cornerRadius: self class cornerRadius).
	self border: (BlBorder
			 paint: LaserGameColors counterBorderColor
			 width: self class borderWidth).
	self padding: (BlInsets all: self class inset).
	self layout: (BlLinearLayout vertical cellSpacing: self class inset).
	self constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ]
]

{ #category : 'accessing' }
LaserGameCounterElement >> label [
	"Answer the element drawing my caption."

	^ label
]

{ #category : 'accessing' }
LaserGameCounterElement >> labelText: aString [
	"Caption me aString. The caption is added last, so it is drawn under the display, and it is
	centred like the display: every caption is a different length and my width is the same for
	all four counters of the panel."

	label ifNotNil: [ :each | self removeChild: each ].
	label := BlTextElement new text: (aString asRopedText
			         fontSize: self class labelFontSize;
			         foreground: LaserGameColors counterLabelColor;
			         yourself).
	label constraintsDo: [ :aConstraints |
		aConstraints linear horizontal alignCenter ].
	self addChild: label
]

{ #category : 'accessing' }
LaserGameCounterElement >> led [
	"Answer the display I show. I hold it, so nothing has to search my children for it."

	^ led
]

{ #category : 'evaluating' }
LaserGameCounterElement >> value [
	"Answer the number my display shows."

	^ self led value
]

{ #category : 'accessing' }
LaserGameCounterElement >> value: anInteger [
	"Show anInteger."

	self led value: anInteger
]
