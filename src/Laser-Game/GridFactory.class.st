"
I build the grids the game is played on.

`defaultGrid` is the board the game opens on: eight columns by ten rows, dealt. `emptyStandardGrid` is a board of that size with nothing on it. `randomizedGridOfExtent:` deals a board of any size. The fixed board of the book is not mine: it is `GridExample class >> demoGrid`, since a board the tests and the examples share is a fixture, not a board I deal.

`randomizeGrid:` deals a board with its target in the top right corner, and `randomizeGrid:targetAt:` puts the target in the corner it is given. Either way it deals mirrors onto locations it has not used yet, one for every two and a half cells of the board. It writes onto the grid it is given and clears nothing, which is why `LaserGameElement >> newGame` empties the grid first.

```
GridFactory randomizedGridOfExtent: 8@10
```

`randomNumberGenerator` holds one seeded `Random` for the whole class, seeded from the clock the first time it is asked for, and `reSeed` puts it back on the clock. A test that wants the same board twice seeds it itself.

"
Class {
	#name : 'GridFactory',
	#superclass : 'Object',
	#classVars : [
		'RandomNumberGenerator'
	],
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'instance creation' }
GridFactory class >> defaultGrid [
	"Answer the board a new game is dealt on: eight columns by ten rows, randomized."

	^self randomizedGridOfExtent: 8@10
]

{ #category : 'randomizing' }
GridFactory class >> emptyRandomLocationsFor: aGrid [
	"Answer a flag per location of aGrid, true where a cell has been taken. Every location starts
	free but the corner the target stands in."
	| dict |
	dict := Dictionary new.
	1 to: aGrid numberOfColumns do: [:x |
		1 to: aGrid numberOfRows do: [:y |
			| pt |
			pt := x@y.
			dict at: pt put: false]].
	dict at: (aGrid numberOfColumns)@1 put: true.  "Target Cell"
	^dict
]

{ #category : 'instance creation' }
GridFactory class >> emptyStandardGrid [
	"Answer an empty board of the size the game is dealt on: eight columns by ten rows, with no
	mirror and no target on it. The randomizer fills a board of this shape, and a test that wants a
	full sized board with nothing on it starts here."

	^Grid newOfSize: 8@10
]

{ #category : 'inspecting' }
GridFactory class >> inspectionBoardFacts [
	"Answer each board I can deal, named by the selector that deals it: an empty board of the
	standard size, and the board a new game is dealt. The second is dealt afresh every time this
	is asked, since that is what a new game gets. The fixed board of the book is not here: it is
	an example, not a board I deal."

	^ OrderedCollection new
		  add: 'emptyStandardGrid' -> self emptyStandardGrid;
		  add: 'defaultGrid' -> self defaultGrid;
		  yourself
]

{ #category : 'inspecting' }
GridFactory class >> inspectionBoards: aBuilder [
	"Show every board I deal, drawn side by side by the board element of the game. I answer boards
	and nothing else, so a picture of the boards is a picture of me."

	<inspectorPresentationOrder: 1 title: 'Boards'>
	^ aBuilder newMorph
		  morph: self inspectionBoardsElement asPreviewMorph;
		  yourself
]

{ #category : 'inspecting' }
GridFactory class >> inspectionBoardsElement [
	"Answer one element holding each board of #inspectionBoardFacts, drawn by the element the
	game draws with and laid out left to right. The boards are different sizes, so each one is
	placed at the width the board before it took."

	| gap canvas left height |
	gap := 10.
	canvas := BlElement new
		          background: Color white;
		          yourself.
	left := gap.
	height := 0.
	self inspectionBoardFacts do: [ :each |
			| extent |
			extent := LaserGameBoardElement extentForGrid: each value.
			canvas addChild: ((LaserGameBoardElement on: each value)
					 extent: extent;
					 position: left @ gap;
					 yourself).
			left := left + extent x + gap.
			height := height max: extent y ].
	canvas extent: left @ (height + (2 * gap)).
	^ canvas
]

{ #category : 'inspecting' }
GridFactory class >> inspectionCounts: aBuilder [
	"Show each board I deal counted: its size, and how its cells are shared out between mirrors,
	the target and blanks. A dealt board is random, so the only thing worth stating about it is
	the counts, and the counts have to add up to the cells."

	<inspectorPresentationOrder: 2 title: 'Counts'>
	^ aBuilder newTable
		  items: self inspectionBoardFacts;
		  addColumn: (SpStringTableColumn title: 'Board' evaluated: [ :each |
					   each key ]);
		  addColumn: (SpStringTableColumn title: 'Columns' evaluated: [ :each |
					   each value numberOfColumns printString ]);
		  addColumn: (SpStringTableColumn title: 'Rows' evaluated: [ :each |
					   each value numberOfRows printString ]);
		  addColumn: (SpStringTableColumn title: 'Cells' evaluated: [ :each |
					   (each value numberOfColumns * each value numberOfRows)
						   printString ]);
		  addColumn: (SpStringTableColumn title: 'Mirrors' evaluated: [ :each |
					   each value numberOfMirrors printString ]);
		  addColumn: (SpStringTableColumn title: 'Targets' evaluated: [ :each |
					   (self inspectionNumberOf: TargetCell in: each value)
						   printString ]);
		  addColumn: (SpStringTableColumn title: 'Blanks' evaluated: [ :each |
					   (self inspectionNumberOf: BlankCell in: each value)
						   printString ]);
		  yourself
]

{ #category : 'inspecting' }
GridFactory class >> inspectionNumberOf: aCellClass in: aGrid [
	"Answer how many cells of aGrid are instances of aCellClass. The class is compared exactly,
	so a subclass of a cell is not counted as its superclass."

	| count |
	count := 0.
	1 to: aGrid numberOfColumns do: [ :x |
		1 to: aGrid numberOfRows do: [ :y |
			(aGrid at: x @ y) class = aCellClass ifTrue: [ count := count + 1 ] ] ].
	^ count
]

{ #category : 'randomizing' }
GridFactory class >> randomBoolean [
	"Answer true or false, each as likely as the other."

	| int |
	int := self randomNumberGenerator nextInteger: 2.
	^int > 1
]

{ #category : 'randomizing' }
GridFactory class >> randomNumberGenerator [
	"Answer the one generator the class deals from, seeded from the clock the first time it is
	asked for."
	RandomNumberGenerator isNil ifTrue: [
		RandomNumberGenerator := Random new.
		RandomNumberGenerator seed: Time totalSeconds].
	^RandomNumberGenerator
]

{ #category : 'randomizing' }
GridFactory class >> randomizeGrid: aGrid [
	"Deal mirrors and a target onto aGrid, with the target in the top right corner of whatever
	board it is."
	self randomizeGrid: aGrid targetAt: (aGrid numberOfColumns@1)
]

{ #category : 'randomizing' }
GridFactory class >> randomizeGrid: aGrid targetAt: pt [
	"Deal a target at pt and mirrors onto aGrid: one mirror per two and a half cells, each on a
	location no other mirror took and none of them on the target. The cells of aGrid are not
	cleared, so a board that is being dealt again is emptied first."
	| emptyList loc howMany |
	emptyList := self emptyRandomLocationsFor: aGrid.
	aGrid at: pt put: TargetCell new.
	howMany := ((aGrid numberOfColumns * aGrid numberOfRows) / 2.5) rounded.
	howMany timesRepeat: [
		loc := self unusedRandomLocationIn: emptyList forGrid: aGrid.
		aGrid at: loc put: self randomizedMirrorCell]
]

{ #category : 'instance creation' }
GridFactory class >> randomizedGridOfExtent: ext [
	"Answer a board of ext columns by ext rows, dealt ready to play: the target in the top right
	corner of that board, and the mirrors of that size."
	| grid |
	grid := Grid newOfSize: ext.
	self randomizeGrid: grid targetAt: ((ext x)@1).
	^grid
]

{ #category : 'randomizing' }
GridFactory class >> randomizedMirrorCell [
	^self randomBoolean
		ifTrue: [MirrorCell leanLeft]
		ifFalse: [MirrorCell leanRight]
]

{ #category : 'randomizing' }
GridFactory class >> reSeed [
	"Seed the generator from the clock again, so the next board dealt differs from this one."
	self randomNumberGenerator seed: Time totalSeconds
]

{ #category : 'randomizing' }
GridFactory class >> unusedRandomLocationIn: list forGrid: aGrid [
	"Answer a location of aGrid that list does not hold yet, and mark it used. nextInteger: answers
	one of 1 to the number asked for, so the location is always on the board."

	| x y pt |
	[
	x := self randomNumberGenerator nextInteger: aGrid numberOfColumns.
	y := self randomNumberGenerator nextInteger: aGrid numberOfRows.
	pt := x@y.
	list at: pt
	] whileTrue: [].
	list at: pt put: true.
	^pt
]
