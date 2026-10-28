Class {
	#name : 'GridDirectionWest',
	#superclass : 'GridDirection',
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
GridDirectionWest class >> adjacentInversionSymbol [
	^#east
]

{ #category : 'as yet unclassified' }
GridDirectionWest class >> directionSymbol [
	^#west
]

{ #category : 'as yet unclassified' }
GridDirectionWest class >> vector [
	^-1@0
]
