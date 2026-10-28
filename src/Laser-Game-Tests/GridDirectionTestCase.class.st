Class {
	#name : 'GridDirectionTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'tests' }
GridDirectionTestCase >> testDirectionSelection [

	| direction |
	direction := GridDirection directionFor: #north.
	self assert: direction equals: GridDirectionNorth.
	self assert: direction vector equals: 0 @ -1.
	self assert: direction adjacentInversionSymbol equals: #south.

	direction := GridDirection directionFor: #east.
	self assert: direction equals: GridDirectionEast.
	self assert: direction vector equals: 1 @ 0.
	self assert: direction adjacentInversionSymbol equals: #west.

	direction := GridDirection directionFor: #south.
	self assert: direction equals: GridDirectionSouth.
	self assert: direction vector equals: 0 @ 1.
	self assert: direction adjacentInversionSymbol equals: #north.

	direction := GridDirection directionFor: #west.
	self assert: direction equals: GridDirectionWest.
	self assert: direction vector equals: -1 @ 0.
	self assert: direction adjacentInversionSymbol equals: #east
]

{ #category : 'tests - inspecting' }
GridDirectionTestCase >> testTheDirectionsTabListsTheFourDirectionsWithTheirVectors [
	"The Directions tab is the four directions in compass order, each with the vector it adds to a
	location and the side the beam enters the next cell from. The last column is the one worth
	having: adjacentInversionSymbol is a name that explains nothing until the table is read."

	| builder table row |
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := GridDirection inspectionDirections: builder.
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals:
		#( 'Direction' 'Symbol' 'Vector' 'Beam enters next cell from' ).
	self
		assert: (table items collect: [ :each | each directionSymbol ]) asArray
		equals: #( #north #east #south #west ).
	row := table columns collect: [ :each |
		       each evaluation value: GridDirectionNorth ].
	self
		assert: row asArray
		equals: #( 'GridDirectionNorth' 'north' '(0@ -1)' 'south' )
]
