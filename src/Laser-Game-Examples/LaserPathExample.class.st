"
I offer single steps of the beam to look at.

Each of my examples answers a `LaserPathElement`, so the inspector opens on the Step tab, which names the cell the beam is in, the side it entered from and the step that follows.
Walking the Step tab from my first example is walking the path the way the game computes it.
"
Class {
	#name : 'LaserPathExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
LaserPathExample class >> firstStepOfTheBeam [
	"Where the light starts on the demo board: the mirror in front of the laser, entered from the side the laser shines on.
	LaserPathExample firstStepOfTheBeam"

	<sampleInstance>
	| grid |
	grid := GridExample demoGrid.
	grid fireLaser.
	^ grid laserBeamPath first
]

{ #category : 'examples' }
LaserPathExample class >> lastStepOfTheBeam [
	"Where the light stops on the demo board, which is the target: the step whose Step tab has no next one.
	LaserPathExample lastStepOfTheBeam"

	<sampleInstance>
	| grid |
	grid := GridExample demoGrid.
	grid fireLaser.
	^ grid laserBeamPath last
]
