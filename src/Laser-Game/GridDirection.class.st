"
I am one of the four directions a cell can be pushed in. I have no instances: each of my four subclasses answers, on its class side, everything there is to know about one direction. The direction symbol (#north, #east, #south, #west) names me, the vector is the step to add to a grid location to move one cell my way, and the inversion symbol names the opposite direction, which is the side a laser beam enters a cell from when it leaves the previous cell my way.

Ask me for a direction by its symbol with GridDirection directionFor: #north.
"
Class {
	#name : 'GridDirection',
	#superclass : 'Object',
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
GridDirection class >> directionFor: aSymbol [
	"Answer the subclass of mine whose direction symbol is aSymbol. The four directions know their
	own symbols, so there is no table here to keep in step with them."

	^self subclasses detect: [:cls | cls directionSymbol = aSymbol]
]

{ #category : 'inspecting' }
GridDirection class >> inspectionDirections: aBuilder [
	"Show the four directions in compass order, each with the vector it adds to a location and the
	side the beam enters the next cell from. The last column is what adjacentInversionSymbol
	means, which is a name that explains nothing until the table is read."

	<inspectorPresentationOrder: 1 title: 'Directions'>
	^ aBuilder newTable
		  items: (#( #north #east #south #west ) collect: [ :each |
					   self directionFor: each ]);
		  addColumn: (SpStringTableColumn title: 'Direction' evaluated: [ :each |
					   each name ]);
		  addColumn: (SpStringTableColumn title: 'Symbol' evaluated: [ :each |
					   each directionSymbol asString ]);
		  addColumn: (SpStringTableColumn title: 'Vector' evaluated: [ :each |
					   each vector printString ]);
		  addColumn:
			  (SpStringTableColumn title: 'Beam enters next cell from' evaluated: [ :each |
					   each adjacentInversionSymbol asString ]);
		  yourself
]

{ #category : 'inspecting' }
GridDirection class >> inspectionDirectionsContext: aContext [
	"Show the Directions table on the class that has the four directions under it. A direction has
	no subclasses to list, so the tab would be empty on one of them."

	aContext active: self subclasses notEmpty
]
