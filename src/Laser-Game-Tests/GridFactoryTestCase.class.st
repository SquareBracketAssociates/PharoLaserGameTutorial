"
I check the random game generator of page 145: what a randomized grid holds, and that it is the same grid twice from the same seed.

Every test deals from a fixed seed and puts the generator back on the clock afterwards, so the tests are repeatable and the game still deals a different board every time it is played.
"
Class {
	#name : 'GridFactoryTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'helpers' }
GridFactoryTestCase >> cellsOf: aGrid [
	"Answer every cell of aGrid, in no particular order."

	| cells |
	cells := OrderedCollection new.
	1 to: aGrid numberOfColumns do: [ :x |
		1 to: aGrid numberOfRows do: [ :y | cells add: (aGrid at: x @ y) ] ].
	^ cells
]

{ #category : 'running' }
GridFactoryTestCase >> setUp [
	"Deal from a known seed, so a randomized board is the same board every run."

	super setUp.
	GridFactory randomNumberGenerator seed: 42
]

{ #category : 'running' }
GridFactoryTestCase >> tearDown [
	"Put the generator back on the clock, so a game deals a different board every time."

	GridFactory reSeed.
	super tearDown
]

{ #category : 'tests' }
GridFactoryTestCase >> testAGridOfAnyExtentIsDealtReadyToPlay [
	"A board of any size is built and dealt in one message: the grid is made, the target goes in
	the top right corner of that grid, and the mirrors follow the size of the board."

	| grid |
	grid := GridFactory randomizedGridOfExtent: 8 @ 10.
	self assert: grid numberOfColumns equals: 8.
	self assert: grid numberOfRows equals: 10.
	self assert: (grid at: 8 @ 1) class equals: TargetCell.
	self assert: grid numberOfMirrors equals: 32.
	self
		assert: ((self cellsOf: grid) count: [ :cell | cell isKindOf: TargetCell ])
		equals: 1
]

{ #category : 'tests' }
GridFactoryTestCase >> testARandomizedGridHoldsNothingButBlanksMirrorsAndTheTarget [
	"A dealt board holds nothing but blank cells, mirrors and the one target."

	| grid |
	grid := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: grid.
	(self cellsOf: grid) do: [ :cell |
		self assert:
			({ BlankCell. MirrorCell. TargetCell } includes: cell class) ]
]

{ #category : 'tests' }
GridFactoryTestCase >> testARandomizedGridPutsTheTargetInTheTopRightCorner [
	"The target goes in the top right corner of the grid, which on a five by five board is 5@1,
	and it is the only target on the board."

	| grid |
	grid := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: grid.
	self assert: (grid at: 5 @ 1) class equals: TargetCell.
	self
		assert: ((self cellsOf: grid) count: [ :cell | cell isKindOf: TargetCell ])
		equals: 1
]

{ #category : 'tests' }
GridFactoryTestCase >> testBothMirrorsAreDealt [
	"A dealt mirror leans either way, and over enough deals both come up."

	| leans |
	leans := ((1 to: 200) collect: [ :each |
		          GridFactory randomizedMirrorCell isLeft ]) asSet.
	self assert: (leans includes: true).
	self assert: (leans includes: false)
]

{ #category : 'tests - inspecting' }
GridFactoryTestCase >> testTheBoardsTabDrawsEveryBoardIDeal [
	"The Boards tab draws each board I can deal, side by side, with the element the game itself
	uses. I am the class that answers boards, so the readable view of me is the boards."

	| boards builder presenter |
	boards := GridFactory inspectionBoardsElement.
	self
		assert: boards children size
		equals: GridFactory inspectionBoardFacts size.
	boards children do: [ :each |
			self assert: each class equals: LaserGameBoardElement ].
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	presenter := GridFactory inspectionBoards: builder.
	self assert: presenter class equals: SpMorphPresenter
]

{ #category : 'tests - inspecting' }
GridFactoryTestCase >> testTheCountsTabSaysWhatIsOnEveryBoardIDeal [
	"The Counts tab is the same boards counted: how many cells each one holds and how they are
	shared out between mirrors, the target and blanks. The three counts have to add up to the
	cells, which is what says a board was dealt and not half dealt."

	| builder table empty cells mirrors targets blanks |
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := GridFactory inspectionCounts: builder.
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals:
			#( 'Board' 'Columns' 'Rows' 'Cells' 'Mirrors' 'Targets' 'Blanks' ).
	empty := table items detect: [ :each | each key = 'emptyStandardGrid' ].
	self assert: (table columns second evaluation value: empty) equals: '8'.
	self assert: (table columns fifth evaluation value: empty) equals: '0'.
	self assert: (table columns sixth evaluation value: empty) equals: '0'.
	cells := table columns fourth.
	mirrors := table columns fifth.
	targets := table columns sixth.
	blanks := table columns last.
	table items do: [ :each |
			self
				assert: (cells evaluation value: each) asNumber
				equals:
					(mirrors evaluation value: each) asNumber
					+ (targets evaluation value: each) asNumber
					+ (blanks evaluation value: each) asNumber ]
]

{ #category : 'tests' }
GridFactoryTestCase >> testTheDefaultGridIsTheStandardBoard [
	"The standard board is eight columns by ten rows, dealt. It is the board the game opens on."

	| grid |
	grid := GridFactory defaultGrid.
	self assert: grid numberOfColumns equals: 8.
	self assert: grid numberOfRows equals: 10.
	self assert: (grid at: 8 @ 1) class equals: TargetCell.
	self assert: grid numberOfMirrors equals: 32
]

{ #category : 'tests' }
GridFactoryTestCase >> testTheMirrorsStandOneToACellAndAwayFromTheTarget [
	"The mirrors are dealt onto locations that have not been used yet, and the target is marked
	used before the first of them, so every mirror dealt is still on the board afterwards and none
	of them stands on the target. A five by five board takes ten mirrors."

	| grid |
	grid := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: grid.
	self assert: grid numberOfMirrors equals: 10
]

{ #category : 'tests' }
GridFactoryTestCase >> testTheNumberOfMirrorsFollowsTheSizeOfTheBoard [
	"One mirror per two and a half cells: ten on a five by five board and thirty-two on the
	standard one."

	| grid |
	grid := Grid newOfSize: 8 @ 10.
	GridFactory randomizeGrid: grid.
	self assert: grid numberOfMirrors equals: 32
]

{ #category : 'tests' }
GridFactoryTestCase >> testTheSameSeedDealsTheSameBoard [
	"The generator is seeded, so the same seed deals the same board. That is what #reSeed is for:
	it makes the next game differ from this one."

	| first second |
	GridFactory randomNumberGenerator seed: 1234.
	first := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: first.
	GridFactory randomNumberGenerator seed: 1234.
	second := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: second.
	1 to: 5 do: [ :x |
		1 to: 5 do: [ :y |
			| here there |
			here := first at: x @ y.
			there := second at: x @ y.
			self assert: here class equals: there class.
			here class = MirrorCell ifTrue: [
				self assert: here isLeft equals: there isLeft ] ] ]
]

{ #category : 'tests' }
GridFactoryTestCase >> testTheTargetCornerIsMarkedUsedOnABoardOfAnySize [
	"The top right corner of the board is marked used before a single mirror is dealt, so the
	target keeps its cell whatever the size of the board. The dictionary holds one flag per
	location, false for the locations still free."

	| grid flags |
	grid := Grid newOfSize: 8 @ 10.
	flags := GridFactory emptyRandomLocationsFor: grid.
	self assert: flags size equals: 80.
	self assert: (flags at: 8 @ 1).
	self
		assert: (flags keys count: [ :each | flags at: each ])
		equals: 1
]
