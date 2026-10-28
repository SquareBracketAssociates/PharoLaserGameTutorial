Class {
	#name : 'LaserGameBoardElementTestCase',
	#superclass : 'TestCase',
	#instVars : [
		'grid'
	],
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'running' }
LaserGameBoardElementTestCase >> setUp [
	"Every test of mine builds on the board of the book, so I make it once here."

	super setUp.
	grid := GridExample demoGrid
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testANewBoardHoversNothingAndHasNoClick [
	"A board that no pointer has visited yet hovers no cell and holds no click."

	| board |
	board := LaserGameBoardElement on: GridExample demoGrid.
	self assert: board hoveredCellElement isNil.
	self assert: board hoveredCell isNil.
	self assert: board clickedCell isNil
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testBoardHasOneElementPerCell [
	"Every cell of the grid gets exactly one element, and no element is left over."

	| board |
	board := LaserGameBoardElement on: grid.
	self
		assert: board children size
		equals: grid numberOfRows * grid numberOfColumns
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testBoardLaysCellsOutInAGridAndFitsThem [
	"The layout does the placing, and the board takes the size of the cells it holds. Both are
	read without a layout pass. BlGridLayout keeps its column count privately, so the number of
	columns is not asserted here; the placement it produces is checked by opening the example."

	| board |
	board := LaserGameBoardElement on: grid.
	self assert: board layout class equals: BlGridLayout.
	self
		assert: board constraints horizontal resizer class
		equals: BlLayoutFitContentResizer.
	self
		assert: board constraints vertical resizer class
		equals: BlLayoutFitContentResizer
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testCellElementsAreInRowMajorOrder [
	"Cells are added row by row, so the element of a location is found by arithmetic and
	every location answers a different element."

	| board elements |
	board := LaserGameBoardElement on: grid.
	self
		assert: (board cellElementAt: 1 @ 1)
		equals: board children first.
	self
		assert:
			(board cellElementAt:
				 grid numberOfColumns @ grid numberOfRows)
		equals: board children last.
	elements := IdentitySet new.
	1 to: grid numberOfRows do: [ :row |
		1 to: grid numberOfColumns do: [ :column |
			elements add: (board cellElementAt: column @ row) ] ].
	self assert: elements size equals: board children size
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testExtentForGridComesFromTheCellSize [
	"The board extent is the cell extent times the grid dimensions. Borders are painted inside
	the cells, so they add nothing, and the number is never written down as a literal."

	self
		assert: (LaserGameBoardElement extentForGrid: grid)
		equals:
			CellRenderer cellExtent x * grid numberOfColumns
			@ (CellRenderer cellExtent y * grid numberOfRows)
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testFiringTheLaserLightsTheTargetOfANewBoard [
	"Firing the laser turns the target on. The cells are built from the model, so a board built
	after the shot shows the lit target. The disc is the last child of the target, since a lit
	target draws the beam under its picture."

	| board center |
	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	center := (board cellElementAt: 5 @ 1) children last.
	self assert: (grid at: 5 @ 1) isOn.
	self
		assert: center background paint color
		equals: LaserGameColors targetCenterColorActive
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testSettingAnotherGridRebuildsTheCells [
	"The same board can show another game. Nothing of the previous grid is left behind."

	| board first second |
	first := GridExample demoGrid.
	second := Grid new.
	board := LaserGameBoardElement on: first.
	board grid: second.
	self assert: board grid equals: second.
	self
		assert: board children size
		equals: second numberOfRows * second numberOfColumns.
	self
		assert: (board cellElementAt: 1 @ 1)
		equals: board children first
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testTheBoardCastsADropShadow [
	"The board casts a drop shadow: three pixels down and to the right, in a dark grey. It is an
	element effect rather than a shape of its own, so the shadow is drawn under the board and the
	board keeps the size its cells give it, which is what the game's arithmetic counts on."

	| board |
	board := LaserGameBoardElement on: GridExample demoGrid.
	self assert: board effect class equals: BlSimpleShadowEffect.
	self
		assert: board effect color
		equals: LaserGameColors boardShadowColor.
	self
		assert: board effect offset
		equals: LaserGameBoardElement shadowOffset.
	board measure: BlExtentMeasurementSpec unspecified.
	self
		assert: board measuredExtent
		equals: (LaserGameBoardElement extentForGrid: GridExample demoGrid)
]
