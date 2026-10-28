"
I check the question of page 144: what it shows, that it leaves the game it covers alone, and that the answer reaches whoever asked.

The buttons are Toplo buttons, and a Toplo button needs a live space to turn a click into its action, so these tests answer the question the way a button does, by sending `answer:`.
"
Class {
	#name : 'LaserGameConfirmElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'tests' }
LaserGameConfirmElementTestCase >> testAQuestionIsIgnoredByTheLayoutItCovers [
	"A question is laid over a game that lays its children out in a row. It takes no place in that
	row: it covers the whole game instead."

	| question |
	question := LaserGameConfirmElement asking: 'Really?'.
	self assert: question constraints ignoredByLayout
]

{ #category : 'tests' }
LaserGameConfirmElementTestCase >> testAQuestionNobodyListensToIsHarmless [
	"A question that was never given a block still answers; it simply has nobody to tell."

	| question |
	question := LaserGameConfirmElement asking: 'Really?'.
	question answer: true.
	self assert: question message equals: 'Really?'
]

{ #category : 'tests' }
LaserGameConfirmElementTestCase >> testAQuestionShowsItsTextAndTwoAnswers [
	"A shade holding one box: the question, and Yes and No under it."

	| question |
	question := LaserGameConfirmElement asking: 'Are you sure?'.
	self assert: question message equals: 'Are you sure?'.
	self assert: question children asArray equals: { question box }.
	self
		assert: question box children first
		equals: question messageElement.
	self assert: question box children second children asArray equals: {
			question yesButton.
			question noButton }.
	self assert: question yesButton labelText asString equals: 'Yes'.
	self assert: question noButton labelText asString equals: 'No'
]

{ #category : 'tests' }
LaserGameConfirmElementTestCase >> testTheAnswerGoesToWhoeverAsked [
	"A Bloc element cannot stop and wait for an answer inside an event handler, so the answer is
	handed to a block instead."

	| question answers |
	answers := OrderedCollection new.
	question := LaserGameConfirmElement asking: 'Really?'.
	question whenAnsweredDo: [ :each | answers add: each ].
	question answer: true.
	question answer: false.
	self assert: answers asArray equals: #( true false )
]
