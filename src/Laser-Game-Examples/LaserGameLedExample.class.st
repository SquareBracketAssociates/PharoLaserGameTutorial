"
I offer seven segment displays to look at.

Each of my examples answers a `LaserGameLedElement`, so the inspector opens on the Segments tab, which lists the ten digits, says which of the seven segments each one lights, and marks the ones lit by the number the display is showing right now.
"
Class {
	#name : 'LaserGameLedExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
LaserGameLedExample class >> ledShowingEverySegmentLit [
	"A three digit display showing 888, where every segment of every digit is on.
	The last column of the Segments tab then says yes to all seven.
	LaserGameLedExample ledShowingEverySegmentLit"

	<sampleInstance>
	| led |
	led := LaserGameLedElement digits: 3.
	led value: 888.
	^ led
]

{ #category : 'examples' }
LaserGameLedExample class >> ledShowingOneHundredAndEight [
	"A three digit display showing 108, which lights one digit of each kind: a lean one, a round one and the full eight.
	LaserGameLedExample ledShowingOneHundredAndEight"

	<sampleInstance>
	| led |
	led := LaserGameLedElement digits: 3.
	led value: 108.
	^ led
]
