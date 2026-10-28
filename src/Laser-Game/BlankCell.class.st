"
I am a `Cell` the beam crosses in a straight line. A beam entering from the west leaves by the east, one entering from the south leaves by the north, and the same in reverse.

I add no state to `Cell`. All I do is fill `exitSides` in `initializeExitSides`, which is what makes a cell blank. Every empty square of the board holds one of me.
"
Class {
	#name : 'BlankCell',
	#superclass : 'Cell',
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'initialization' }
BlankCell >> initialize [
	super initialize.
	self initializeExitSides.
	
]

{ #category : 'initialization' }
BlankCell >> initializeExitSides [
	self exitSides: Dictionary new.
	self exitSides at: #north put: #south.
	self exitSides at: #east put: #west.
	self exitSides at: #south put: #north.
	self exitSides at: #west put: #east.
	
]
