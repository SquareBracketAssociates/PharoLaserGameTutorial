"
I am a question laid over the game: a shade across everything, and a box in the middle holding the question and two answers.

I am page 144's `(self confirm: 'Are you sure you want to quit?')`. That message opens a Morphic dialog and waits for it, so the answer comes back as the value of the expression. Nothing in this port draws in Morphic, and a Bloc element does not block for an answer, so I am asked instead of waited for: whoever puts me up registers a block with `whenAnsweredDo:`, and I evaluate it with `true` or `false` when a button is pressed.

```
LaserGameConfirmElement asking: 'Are you sure you want to quit?'
```

I take no part in the layout of what I cover, so the game I am added to keeps its row of two children.

Instance variables:
- `box`: the frame holding the question and the answers.
- `messageElement`: the text of the question.
- `yesButton`, `noButton`: the two answers.
- `answerAction`: the block evaluated with the answer, nil while nobody asked.
"
Class {
	#name : 'LaserGameConfirmElement',
	#superclass : 'BlElement',
	#instVars : [
		'box',
		'messageElement',
		'yesButton',
		'noButton',
		'answerAction'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'instance creation' }
LaserGameConfirmElement class >> asking: aString [
	"Answer a question reading aString."

	| element |
	element := self new.
	element message: aString.
	^ element
]

{ #category : 'constants' }
LaserGameConfirmElement class >> buttonGap [
	"Answer the gap, in pixels, between the two answers. The gap the panel puts between its
	buttons."

	^ LaserGameControlPanelElement buttonGap
]

{ #category : 'constants' }
LaserGameConfirmElement class >> cornerRadius [
	"Answer the radius, in pixels, of the corners of the box."

	^ 8
]

{ #category : 'constants' }
LaserGameConfirmElement class >> inset [
	"Answer the space, in pixels, between the frame of the box and what it holds, and between the
	question and the answers."

	^ 15
]

{ #category : 'constants' }
LaserGameConfirmElement class >> messageFontSize [
	"Answer the size, in points, of the text of the question."

	^ 12
]

{ #category : 'evaluating' }
LaserGameConfirmElement >> answer: aBoolean [
	"The player answered aBoolean. Whoever asked the question is told, and it is that object which
	takes me off the game: I do not know what my answer means."

	answerAction ifNotNil: [ :anAction | anAction value: aBoolean ]
]

{ #category : 'accessing' }
LaserGameConfirmElement >> box [
	"Answer the framed box holding the question and the answers."

	^ box
]

{ #category : 'initialization' }
LaserGameConfirmElement >> initialize [
	"A question is a shade over the game with a box in the middle of it. The shade is ignored by
	the layout of the game, so the game stays the row of two children it was."

	super initialize.
	self background: LaserGameColors confirmationShadeColor.
	self layout: BlFrameLayout new.
	self constraintsDo: [ :aConstraints | aConstraints ignoreByLayout ].
	yesButton := self newButton: 'Yes' answering: true.
	noButton := self newButton: 'No' answering: false.
	box := self newBox.
	self addChild: box
]

{ #category : 'accessing' }
LaserGameConfirmElement >> message [
	"Answer the text of the question."

	^ messageElement text asString
]

{ #category : 'accessing' }
LaserGameConfirmElement >> message: aString [
	"Ask aString."

	messageElement text: (aString asRopedText
			 fontSize: self class messageFontSize;
			 foreground: LaserGameColors confirmationTextColor;
			 yourself)
]

{ #category : 'accessing' }
LaserGameConfirmElement >> messageElement [
	"Answer the element drawing the question."

	^ messageElement
]

{ #category : 'initialization' }
LaserGameConfirmElement >> newAnswerRow [
	"Answer the row holding the two answers, Yes first."

	| row |
	row := BlElement new.
	row background: BlTransparentBackground new.
	row layout: (BlLinearLayout horizontal cellSpacing: self class buttonGap).
	row constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ].
	row addChild: yesButton.
	row addChild: noButton.
	^ row
]

{ #category : 'initialization' }
LaserGameConfirmElement >> newBox [
	"Answer the box in the middle of the shade: the question, and the two answers under it."

	| element |
	element := BlElement new.
	element background: LaserGameColors confirmationBackgroundColor.
	element geometry:
		(BlRoundedRectangleGeometry cornerRadius: self class cornerRadius).
	element padding: (BlInsets all: self class inset).
	element layout: (BlLinearLayout vertical cellSpacing: self class inset).
	element constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignCenter.
		aConstraints frame vertical alignCenter ].
	messageElement := BlTextElement new.
	element addChild: messageElement.
	element addChild: self newAnswerRow.
	^ element
]

{ #category : 'initialization' }
LaserGameConfirmElement >> newButton: aLabel answering: aBoolean [
	"Answer a button labelled aLabel that answers aBoolean when it is clicked. The buttons of the
	control panel are this size, so the answers look like the rest of the game."

	| button |
	button := ToButton labelText: aLabel.
	button extent: LaserGameControlPanelElement buttonWidth
		@ LaserGameControlPanelElement buttonHeight.
	button clickAction: [ self answer: aBoolean ].
	^ button
]

{ #category : 'accessing' }
LaserGameConfirmElement >> noButton [
	"Answer the button that answers no."

	^ noButton
]

{ #category : 'evaluating' }
LaserGameConfirmElement >> whenAnsweredDo: aBlock [
	"Evaluate aBlock with the answer when the player presses one of my buttons."

	answerAction := aBlock
]

{ #category : 'accessing' }
LaserGameConfirmElement >> yesButton [
	"Answer the button that answers yes."

	^ yesButton
]
