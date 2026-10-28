"
I am a small LED display: a row of seven segment digits showing a number.

I replace the `LedMorph` of page 141, which the original takes from the Squeak image and does not write. Nothing of that kind is in Pharo, and no class here may depend on a `Form` anyway, so I draw the digits myself: one element per digit, seven rectangles inside each, and showing another number recolours those rectangles. No element is added or removed after I am built.

```
LaserGameLedElement digits: 3
```

The segments carry the usual names: `#a` is the top bar, `#b` and `#c` the right hand pair going down, `#d` the bottom bar, `#e` and `#f` the left hand pair going up, and `#g` the middle bar. `LaserGameLedElement class >> segmentsForDigit:` says which of them each of the ten digits lights, and `segmentBoundsOf:` where each one sits in a digit of the current size.

A number shorter than my digit count is shown right aligned, with the digits in front of it blank rather than zero; a number longer than my digit count keeps its last digits. `highlighted:` is what page 142 sends while the laser fires: it brightens the lit segments.

Instance variables:
- `digitCount`: how many digits I show. Setting it builds the digit elements.
- `value`: the number shown.
- `highlighted`: whether the lit segments are bright.
- `digitElements`: my digit elements, leftmost first.

"
Class {
	#name : 'LaserGameLedElement',
	#superclass : 'BlElement',
	#instVars : [
		'digitCount',
		'value',
		'highlighted',
		'digitElements'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'constants' }
LaserGameLedElement class >> digitExtent [
	"Answer the size, in pixels, of one digit: ten wide and sixteen high. Three bars of the
	segment thickness, at the top, the middle and the bottom, with an arm between each pair, need
	an even height to divide."

	^ 10 @ 16
]

{ #category : 'constants' }
LaserGameLedElement class >> digitGap [
	"Answer the gap, in pixels, between two digits. It is drawn between the digits rather than
	inside them, so three digits come to thirty four pixels rather than thirty."

	^ 2
]

{ #category : 'instance creation' }
LaserGameLedElement class >> digits: anInteger [
	"Answer a display of anInteger digits, showing zero."

	| led |
	led := self new.
	led digitCount: anInteger.
	^ led
]

{ #category : 'geometry' }
LaserGameLedElement class >> extentForDigits: anInteger [
	"Answer the size, in pixels, of a display of anInteger digits: the digits side by side with a
	gap between each pair."

	^ (self digitExtent x + self digitGap * anInteger) - self digitGap
	  @ self digitExtent y
]

{ #category : 'geometry' }
LaserGameLedElement class >> segmentBoundsOf: aSymbol [
	"Answer the rectangle segment aSymbol occupies in a digit, in the digit's own coordinates. The
	three bars run across the top, the middle and the bottom, and the four arms fill the two gaps
	the bars leave, so every size follows the digit size and the segment thickness."

	| width height thickness arm |
	width := self digitExtent x.
	height := self digitExtent y.
	thickness := self segmentThickness.
	arm := height - (3 * thickness) // 2.
	aSymbol == #a ifTrue: [ ^ thickness @ 0 extent: width - (2 * thickness) @ thickness ].
	aSymbol == #b ifTrue: [ ^ width - thickness @ thickness extent: thickness @ arm ].
	aSymbol == #c ifTrue: [
		^ width - thickness @ (thickness + arm + thickness) extent: thickness @ arm ].
	aSymbol == #d ifTrue: [
		^ thickness @ (height - thickness) extent: width - (2 * thickness) @ thickness ].
	aSymbol == #e ifTrue: [ ^ 0 @ (thickness + arm + thickness) extent: thickness @ arm ].
	aSymbol == #f ifTrue: [ ^ 0 @ thickness extent: thickness @ arm ].
	aSymbol == #g ifTrue: [
		^ thickness @ (thickness + arm) extent: width - (2 * thickness) @ thickness ].
	^ self error: 'No segment is named ' , aSymbol printString
]

{ #category : 'constants' }
LaserGameLedElement class >> segmentNames [
	"Answer the names of the seven segments, in the order they are held in a digit element."

	^ #( #a #b #c #d #e #f #g )
]

{ #category : 'constants' }
LaserGameLedElement class >> segmentThickness [
	"Answer the thickness, in pixels, of one segment."

	^ 2
]

{ #category : 'constants' }
LaserGameLedElement class >> segmentsForDigit: anInteger [
	"Answer the names of the segments the digit anInteger lights."

	^ #( #( #a #b #c #d #e #f ) #( #b #c ) #( #a #b #g #e #d )
	     #( #a #b #g #c #d ) #( #f #g #b #c ) #( #a #f #g #c #d )
	     #( #a #f #g #e #c #d ) #( #a #b #c ) #( #a #b #c #d #e #f #g )
	     #( #a #b #c #d #f #g ) ) at: anInteger + 1
]

{ #category : 'accessing' }
LaserGameLedElement >> digitCount [
	"Answer how many digits I show."

	^ digitCount
]

{ #category : 'accessing' }
LaserGameLedElement >> digitCount: anInteger [
	"Show anInteger digits. Setting the count builds the digits."

	digitCount := anInteger.
	self rebuildDigits
]

{ #category : 'accessing' }
LaserGameLedElement >> digitElements [
	"Answer my digit elements, leftmost first."

	^ digitElements
]

{ #category : 'accessing' }
LaserGameLedElement >> highlighted [
	"Answer whether my lit segments are bright."

	^ highlighted
]

{ #category : 'accessing' }
LaserGameLedElement >> highlighted: aBoolean [
	"Light my segments brightly, or dimly. The counter is highlighted while the laser fires."

	highlighted := aBoolean.
	self updateDigits
]

{ #category : 'initialization' }
LaserGameLedElement >> initialize [
	"A display is a dark slab with a row of digits on it, one gap apart. The slab is the colour an
	unlit segment takes too, so that only the lit segments are seen. The gap is a margin on each
	digit but the first rather than the cell spacing of the layout, since a linear layout spaces
	the cells from its own edges as well and the last digit would then be clipped."

	super initialize.
	value := 0.
	digitCount := 0.
	highlighted := false.
	digitElements := #(  ).
	self background: LaserGameColors counterBodyColor.
	self layout: BlLinearLayout horizontal
]

{ #category : 'inspecting' }
LaserGameLedElement >> inspectionSegments: aBuilder [
	"Show which of the seven segments each of the ten digits lights, and which digits I am
	showing now. A seven segment digit is a table in the first place; segmentsForDigit: is that
	table written as a literal array, and this tab is the same table read the way it was meant to
	be read."

	<inspectorPresentationOrder: 2 title: 'Segments'>
	| table |
	table := aBuilder newTable
		         items: (0 to: 9);
		         addColumn:
			         (SpStringTableColumn title: 'Digit' evaluated: [ :each |
					          each printString ]);
		         yourself.
	self class segmentNames do: [ :name |
			table addColumn:
				(SpStringTableColumn title: name asString evaluated: [ :each |
						 ((self class segmentsForDigit: each) includes: name)
							 ifTrue: [ 'on' ]
							 ifFalse: [ '' ] ]) ].
	table addColumn:
		(SpStringTableColumn title: 'Shown now' evaluated: [ :each |
				 (self inspectionShowsDigit: each)
					 ifTrue: [ 'yes' ]
					 ifFalse: [ '' ] ]).
	^ table
]

{ #category : 'inspecting' }
LaserGameLedElement >> inspectionShowsDigit: anInteger [
	"Answer whether anInteger is one of the digits I am showing. My value is read as it is
	printed, since that is what the digits hold."

	^ (self value ifNil: [ 0 ]) printString includes:
		  (Character digitValue: anInteger)
]

{ #category : 'private' }
LaserGameLedElement >> newDigitElement [
	"Answer one digit: an element of the digit size holding one rectangle per segment, in the
	order the segment names are in. The rectangles stay; showing another number recolours them."

	| digit |
	digit := BlElement new.
	digit extent: self class digitExtent.
	digit background: BlTransparentBackground new.
	self class segmentNames do: [ :name |
		| area segment |
		area := self class segmentBoundsOf: name.
		segment := BlElement new.
		segment extent: area extent.
		segment position: area origin.
		digit addChild: segment ].
	^ digit
]

{ #category : 'drawing' }
LaserGameLedElement >> offColor [
	"Answer the color of a segment that is not lit."

	^ LaserGameColors counterDigitOffColor
]

{ #category : 'drawing' }
LaserGameLedElement >> onColor [
	"Answer the color of a lit segment: almost white while I am highlighted, the lavender of the
	LED otherwise."

	^ highlighted
		  ifTrue: [ LaserGameColors counterDigitHighlightColor ]
		  ifFalse: [ LaserGameColors counterDigitColor ]
]

{ #category : 'private' }
LaserGameLedElement >> rebuildDigits [
	"Replace my digits with digitCount fresh ones and take the size they need. Every digit but the
	first carries the gap in front of it as a margin."

	self removeChildren.
	digitElements := (1 to: digitCount) collect: [ :each | self newDigitElement ].
	digitElements allButFirst do: [ :each |
		each margin: (BlInsets left: self class digitGap) ].
	digitElements do: [ :each | self addChild: each ].
	self extent: (self class extentForDigits: digitCount).
	self updateDigits
]

{ #category : 'private' }
LaserGameLedElement >> updateDigits [
	"Color every segment of every digit for the number I show. The number is right aligned, the
	digits in front of it stay blank, and a number too long for me keeps its last digits."

	| text |
	text := value printString.
	text size > digitCount ifTrue: [ text := text last: digitCount ].
	digitElements withIndexDo: [ :digit :index |
		| position segments |
		position := index - (digitCount - text size).
		segments := position > 0
			            ifTrue: [
			            self class segmentsForDigit: (text at: position) digitValue ]
			            ifFalse: [ #(  ) ].
		digit children withIndexDo: [ :segment :segmentIndex |
			segment background:
				((segments includes: (self class segmentNames at: segmentIndex))
					 ifTrue: [ self onColor ]
					 ifFalse: [ self offColor ]) ] ]
]

{ #category : 'evaluating' }
LaserGameLedElement >> value [
	"Answer the number I show."

	^ value
]

{ #category : 'accessing' }
LaserGameLedElement >> value: anInteger [
	"Show anInteger."

	value := anInteger.
	self updateDigits
]
