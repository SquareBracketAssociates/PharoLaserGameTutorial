Class {
	#name : 'ReverseRotateCounterClockwiseLaserGameAction',
	#superclass : 'ReverseLaserGameAction',
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'accessing' }
ReverseRotateCounterClockwiseLaserGameAction class >> actionSymbol [
	^#counterClockwise
]

{ #category : 'accessing' }
ReverseRotateCounterClockwiseLaserGameAction class >> reverseActionSymbol [
	^#rotateCellClockwiseAt:
]
