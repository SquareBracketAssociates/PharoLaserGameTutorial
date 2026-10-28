"
I am the `Cell` the beam is aimed at. Every side of me leaves by nothing, so a beam that enters lights the side it arrived by and stops there. Reaching me is how the game is won.

Like `BlankCell` I add no state to `Cell`; `initializeExitSides` fills `exitSides` with nil for all four sides. `Grid` puts exactly one of me on the board.
"
Class {
	#name : 'TargetCell',
	#superclass : 'Cell',
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'initialization' }
TargetCell >> initialize [
	super initialize.
	self initializeExitSides.
	
]

{ #category : 'initialization' }
TargetCell >> initializeExitSides [
	self exitSides: Dictionary new.
	self exitSides at: #north put: nil.
	self exitSides at: #east put: nil.
	self exitSides at: #south put: nil.
	self exitSides at: #west put: nil.
	
]
