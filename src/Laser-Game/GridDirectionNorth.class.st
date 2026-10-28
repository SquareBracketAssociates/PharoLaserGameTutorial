Class {
	#name : 'GridDirectionNorth',
	#superclass : 'GridDirection',
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
GridDirectionNorth class >> adjacentInversionSymbol [
	^#south
]

{ #category : 'as yet unclassified' }
GridDirectionNorth class >> directionSymbol [
	^#north
]

{ #category : 'as yet unclassified' }
GridDirectionNorth class >> vector [
	^0@(-1)
]
