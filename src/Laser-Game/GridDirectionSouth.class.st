Class {
	#name : 'GridDirectionSouth',
	#superclass : 'GridDirection',
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
GridDirectionSouth class >> adjacentInversionSymbol [
	^#north
]

{ #category : 'as yet unclassified' }
GridDirectionSouth class >> directionSymbol [
	^#south
]

{ #category : 'as yet unclassified' }
GridDirectionSouth class >> vector [
	^0@1
]
