Class {
	#name : 'LaserGameElementTestCase',
	#superclass : 'TestCase',
	#instVars : [
		'game'
	],
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'running' }
LaserGameElementTestCase >> setUp [
	"Every test of mine plays the board of the book, so I build the game on it once here."

	super setUp.
	game := LaserGameElement on: GridExample demoGrid
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAClickThatChangesNothingIsNoMove [
	"A click on a blank cell does nothing, so the board is never told and nothing is counted. The
	count is what the player is asked to keep down, so only a move that happened counts."

	self assert: (game grid at: 2 @ 2) class equals: BlankCell.
	(game board cellElementAt: 2 @ 2) clickAt:
		CellClickRegionRotateClockwise regionRectangle center.
	self assert: game moves equals: 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameIgnoresAWindowOfNoSize [
	"A space announces its extent while it is being opened, and that extent can be nothing at all.
	Scaling by zero would take the game off the screen, so a window of no size is left alone."

	| natural |
	natural := game naturalExtent.
	game fitIn: natural * 2.
	game fitIn: 0 @ 0.
	self assert: game transformation matrix sx equals: 2.0.
	self assert: game constraints position equals: 0 @ 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameKeepsItsShapeInAWindowOfAnotherShape [
	"A board is as wide and as tall as it is. A window of another shape scales the game by the
	tighter of the two directions and centres what is left over, so the cells stay square and the
	game is never stretched. The window is twice the natural extent in one direction only, so the
	scale is one and the leftover is half the other direction, at any cell size."

	| natural |
	natural := game naturalExtent.
	game fitIn: natural x * 2 @ natural y.
	self assert: (game scaleToFitIn: natural x * 2 @ natural y) equals: 1.0.
	self assert: game transformation matrix sx equals: 1.0.
	self assert: game constraints position equals: natural x / 2 @ 0.
	game fitIn: natural x @ (natural y * 2).
	self assert: game transformation matrix sx equals: 1.0.
	self assert: game constraints position equals: 0 @ (natural y / 2)
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameMadeWithNoGridPlaysTheStandardBoard [
	"A game takes its grid from outside, and falls back on GridFactory defaultGrid, eight columns
	by ten rows, dealt, when nobody gave it one. The fallback is dealt when the grid is first
	asked for rather than in #initialize, so a game that is given a grid deals no board it would
	throw away."

	game := LaserGameElement new.
	self assert: game grid numberOfColumns equals: 8.
	self assert: game grid numberOfRows equals: 10.
	self assert: game board grid equals: game grid.
	self
		assert: game constraints horizontal resizer size
			@ game constraints vertical resizer size
		equals: (LaserGameElement extentForGrid: game grid).
	self
		assert: (LaserGameElement on: GridExample demoGrid) grid numberOfColumns
		equals: 5
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameScalesToFillTheWindowItIsGiven [
	"The game is drawn at the size the board asks for and scaled to whatever the window is, so a
	window of twice that extent shows the same game twice as big, filling it. The extent is read
	from the game and not written down, because the cell size decides it."

	| natural |
	natural := game naturalExtent.
	game fitIn: natural * 2.
	self assert: (game scaleToFitIn: natural * 2) equals: 2.0.
	self assert: game transformation matrix sx equals: 2.0.
	self assert: game transformation matrix sy equals: 2.0.
	self assert: game constraints position equals: 0 @ 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameShowsItsCountsBeforeAnythingHappens [
	"A game just opened shows the counts of the board it was dealt, not zeroes. The panel sets its
	counters at the end of #rebuild, which is what building it does, so there is no window in which
	a counter shows a number nothing has written yet. This test says so, here and after a new
	board is dealt."

	self
		assert: game controlPanel mirrorsCounter value
		equals: game grid numberOfMirrors.
	self assert: game controlPanel mirrorsCounter value > 0.
	self assert: game controlPanel movesCounter value equals: 0.
	self assert: game controlPanel laserPathCounter value equals: 0.
	game newGame.
	self
		assert: game controlPanel mirrorsCounter value
		equals: game grid numberOfMirrors.
	self assert: game controlPanel mirrorsCounter value > 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameShrinksWithASmallerWindow [
	"A window smaller than the board scales the game down rather than cutting it off, so the whole
	board is always in view. Half the natural extent is half the game, whatever a cell measures."

	| natural |
	natural := game naturalExtent.
	game fitIn: natural / 2.
	self assert: game transformation matrix sx equals: 0.5.
	self assert: game constraints position equals: 0 @ 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameTakesTheSizeOfWhateverBoardItIsGiven [
	"A game is handed a grid rather than building one, so the size of the board is the size of the
	grid. The game is one cell per location, the panel keeps its width and takes the height of the
	board beside it, or of what it holds when the board is shorter than that, and the window is the
	two of them and the margins. The sizes are read from the layout constraints, since nothing is
	laid out until a space shows it."

	| wanted panelHeight |
	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	wanted := LaserGameElement extentForGrid: game grid.
	panelHeight := 10 * CellRenderer cellExtent y
	               max: LaserGameControlPanelElement contentHeight.
	self assert: game board children size equals: 80.
	self
		assert: wanted
		equals: (8 * CellRenderer cellExtent x + LaserGameElement panelWidth
		         + (2 * LaserGameElement gameMargin))
			        @ (panelHeight + (2 * LaserGameElement gameMargin)).
	self assert: game constraints horizontal resizer size equals: wanted x.
	self assert: game constraints vertical resizer size equals: wanted y.
	self
		assert: game controlPanel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: game controlPanel constraints vertical resizer size
		equals: panelHeight
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAMoveOnTheBoardSetsTheCounter [
	"A move changes the path, so it changes the counter too. The board says that a move was made
	and the game asks its panel to catch up; a board opened on its own says the same thing to
	nobody. Turning the mirror at the foot of the first column sends the beam somewhere else, and
	the path gets shorter."

	| cellElement before |
	game toggleLaser.
	before := game controlPanel laserPathCounter value.
	self assert: before equals: game grid laserBeamPath size.
	cellElement := game board cellElementAt: 1 @ 5.
	cellElement clickAt: CellClickRegionRotateClockwise regionRectangle center.
	self
		assert: game controlPanel laserPathCounter value
		equals: game grid laserBeamPath size.
	self deny: game controlPanel laserPathCounter value equals: before
]

{ #category : 'tests' }
LaserGameElementTestCase >> testANewGameDealsAFreshBoardAndForgetsTheMoves [
	"A new game clears the cells, stops the laser, sets the count to zero and randomizes the grid.
	The demo grid holds ten mirrors and so does a randomized five by five board, so the proof that
	the old cells went first is the count: the randomizer writes onto the board it is given and
	clears nothing, and ten mirrors is what it deals."

	game grid fireLaser.
	game incrementMoves.
	game newGame.
	self assert: game moves equals: 0.
	self deny: game grid laserIsActive.
	self assert: game grid numberOfMirrors equals: 10.
	self assert: (game grid at: 5 @ 1) class equals: TargetCell.
	self assert: game controlPanel movesCounter value equals: 0.
	self assert: game controlPanel laserPathCounter value equals: 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testANewGameIsShownOnTheBoard [
	"Every cell element is built again from the cell that stands at its location now, so a cell
	that was a mirror and is now blank draws itself blank. Nothing has to be erased: a cell
	element draws only its own cell."

	game newGame.
	1 to: game grid numberOfRows do: [ :row |
		1 to: game grid numberOfColumns do: [ :column |
			self
				assert: (game board cellElementAt: column @ row) renderer cell
				equals: (game grid at: column @ row) ] ]
]

{ #category : 'tests' }
LaserGameElementTestCase >> testANewGameKeepsTheSizeOfTheBoard [
	"New deals the grid the game already plays on, so a bigger board stays bigger: the cells are
	emptied and dealt again, one target in the corner and the mirrors of that size."

	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	game newGame.
	self assert: game grid numberOfColumns equals: 8.
	self assert: game grid numberOfRows equals: 10.
	self assert: game grid numberOfMirrors equals: 32.
	self assert: (game grid at: 8 @ 1) class equals: TargetCell.
	self assert: game board children size equals: 80
]

{ #category : 'tests' }
LaserGameElementTestCase >> testANewGameStartsWithNoMoves [
	"The move count is zero when the game is built."

	self assert: game moves equals: 0.
	self assert: game controlPanel movesCounter value equals: 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAnsweringNoLeavesTheGameAsItWas [
	"No takes the question away and does nothing else."

	game quit.
	game confirmation answer: false.
	self assert: game confirmation isNil.
	self assert: game children asArray equals: {
			game controlPanel.
			game board parent }
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAnsweringYesToAGameThatIsNotOpenIsHarmless [
	"Yes takes the question away and closes the game. A game that was never opened has no space,
	and closing it is harmless."

	self assert: game space isNil.
	game quit.
	game confirmation answer: true.
	self assert: game confirmation isNil.
	self assert: game children size equals: 2
]

{ #category : 'tests' }
LaserGameElementTestCase >> testBoardShowsTheGridOfTheGame [
	"The board the game holds renders the game's own grid, one element per cell."

	| grid |
	grid := GridExample demoGrid.
	game := LaserGameElement on: grid.
	self assert: game grid equals: grid.
	self assert: game board grid equals: grid.
	self assert: game board children size equals: 25
]

{ #category : 'tests' }
LaserGameElementTestCase >> testControlPanelIsAFixedColumnAsTallAsTheBoardOrItsContents [
	"The panel keeps its width whatever the grid is, and it is as tall as the board beside it — or
	as tall as what it holds, when that is more, which is what a board of five rows comes to once
	the panel holds four counters. Sizes are read from the layout constraints, since nothing is
	laid out yet."

	| grid |
	grid := GridExample demoGrid.
	game := LaserGameElement on: grid.
	self
		assert: game controlPanel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: game controlPanel constraints vertical resizer size
		equals: (LaserGameControlPanelElement heightForGrid: grid).
	self
		assert: game controlPanel background paint color
		equals: LaserGameColors controlPanelColor
]

{ #category : 'tests' }
LaserGameElementTestCase >> testEveryMoveOnTheBoardCountsOne [
	"The board announces the move and the game counts it, so the count is shown without anything
	searching for the display."

	(game board cellElementAt: 1 @ 5) clickAt:
		CellClickRegionRotateClockwise regionRectangle center.
	self assert: game moves equals: 1.
	self assert: game controlPanel movesCounter value equals: 1
]

{ #category : 'tests' }
LaserGameElementTestCase >> testExtentIsTheBoardPlusThePanelPlusTheMargins [
	"The game is as wide as the board, the panel beside it and a margin on each side, and as tall
	as the taller of the board and what the panel holds, with a margin above and below. The second
	assertion states the numbers rather than the constants: the panel is a hundred and thirty, two
	fifty pixel buttons and the three gaps a row of two stands in."

	| grid expected |
	grid := GridExample demoGrid.
	expected := (LaserGameBoardElement extentForGrid: grid) x
	            + LaserGameElement panelWidth
	            @ (LaserGameControlPanelElement heightForGrid: grid)
	            + (2 * LaserGameElement gameMargin).
	self assert: (LaserGameElement extentForGrid: grid) equals: expected.
	self
		assert: (LaserGameElement extentForGrid: grid)
		equals: 5 * CellRenderer cellExtent x + 130
			@ (5 * CellRenderer cellExtent y
				 max: LaserGameControlPanelElement contentHeight) + 20
]

{ #category : 'tests' }
LaserGameElementTestCase >> testFiringTheLaserSetsTheCounter [
	"The fire button reaches the counter: toggling the laser sets the counters as well as the
	board."

	self assert: game controlPanel laserPathCounter value equals: 0.
	game toggleLaser.
	self
		assert: game controlPanel laserPathCounter value
		equals: game grid laserBeamPath size.
	self assert: game controlPanel laserPathCounter highlighted.
	game toggleLaser.
	self assert: game controlPanel laserPathCounter value equals: 0.
	self deny: game controlPanel laserPathCounter highlighted
]

{ #category : 'tests' }
LaserGameElementTestCase >> testGameHoldsABoardAndAControlPanel [
	"A game is a row of two children: the control panel first, the board beside it. The board is
	wrapped in a column, which holds the mark of the laser's home under it, and the board itself
	is reached through its own accessor."

	self assert: game children size equals: 2.
	self assert: game children first equals: game controlPanel.
	self assert: game children second equals: game board parent.
	self assert: game board class equals: LaserGameBoardElement.
	self assert: game layout class equals: BlLinearLayout
]

{ #category : 'tests' }
LaserGameElementTestCase >> testGameShowsWhereTheLaserComesFrom [
	"A bar one cell wide and one margin tall marks where the laser enters the board, in the colour
	of the splatter of the beam. It belongs under the bottom left corner of the board, which is
	where the beam starts: Grid >> startingCell is column one of the last row, and the beam enters
	it from the south. It is a plain element with a background, standing under the board in a
	column of its own."

	| column |
	column := game board parent.
	self assert: column children asArray equals: {
			game board.
			game laserHome }.
	self
		assert: game laserHome constraints horizontal resizer size
		equals: CellRenderer cellExtent x.
	self
		assert: game laserHome constraints vertical resizer size
		equals: LaserGameElement gameMargin.
	self
		assert: game laserHome background paint color
		equals: LaserGameColors laserBeamSplatterColor
]

{ #category : 'tests' }
LaserGameElementTestCase >> testGameTakesTheExtentItCalculates [
	"The game asks for exactly the size its own arithmetic gives, and the margin around its two
	children is padding, so the window ramp shows through it. The bottom margin is the one
	exception, kept free for the mark of the laser's home and asserted by
	#testTheLaserHomeSitsInTheMarginAndCostsNoSize."

	| grid |
	grid := GridExample demoGrid.
	game := LaserGameElement on: grid.
	self
		assert: game constraints horizontal resizer size
		equals: (LaserGameElement extentForGrid: grid) x.
	self
		assert: game constraints vertical resizer size
		equals: (LaserGameElement extentForGrid: grid) y.
	self assert: game padding top equals: LaserGameElement gameMargin.
	self assert: game padding left equals: LaserGameElement gameMargin.
	self assert: game padding right equals: LaserGameElement gameMargin
]

{ #category : 'tests' }
LaserGameElementTestCase >> testQuittingAsksBeforeItCloses [
	"Quit sits beside Fire and is easy to hit by accident, so quitting asks first. The
	question covers the game and is not one of the two children the game lays out in a row. A
	second click on Quit while the question stands asks nothing more."

	game quit.
	self assert: game confirmation class equals: LaserGameConfirmElement.
	self assert: game children size equals: 3.
	self assert: game children last equals: game confirmation.
	game quit.
	self assert: game children size equals: 3
]

{ #category : 'tests' }
LaserGameElementTestCase >> testResetPutsEveryCellBackAndZeroesTheMoves [
	"Reset unwinds the whole undo stack, stops the laser and sets the move count back to zero, so
	the player can start the same board again."

	game grid fireLaser.
	game grid pushCellEastFromLocation: 1 @ 2.
	game incrementMoves.
	game grid rotateCellClockwiseAt: 2 @ 2.
	game incrementMoves.
	self assert: game grid movesStack size equals: 2.
	game reset.
	self assert: game grid movesStack isEmpty.
	self assert: (game grid at: 1 @ 2) class equals: MirrorCell.
	self deny: game laserIsActive.
	self assert: game moves equals: 0.
	self assert: game controlPanel movesCounter value equals: 0.
	self assert: game controlPanel laserPathCounter value equals: 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testSettingAnotherGridRebuildsTheGame [
	"Handing the game another grid throws away the board and the panel it held and builds them
	again for the new grid, so its size follows."

	| oldBoard smallGrid |
	oldBoard := game board.
	smallGrid := Grid new.
	game grid: smallGrid.
	self assert: game children size equals: 2.
	self deny: game board identicalTo: oldBoard.
	self assert: game board grid equals: smallGrid.
	self assert: game board children size equals: 1.
	self
		assert: game constraints horizontal resizer size
		equals: (LaserGameElement extentForGrid: smallGrid) x
]

{ #category : 'tests' }
LaserGameElementTestCase >> testTheCountersStillHoldWhatABiggerBoardProduces [
	"A bigger board makes a longer beam, and a counter has three digits. Eighty cells cannot make
	a path of a thousand, so the beam counter still shows the whole number the grid answers,
	whatever board the game was dealt."

	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	game toggleLaser.
	self assert: game grid laserBeamPath size < 1000.
	self
		assert: game controlPanel laserPathCounter value
		equals: game grid laserBeamPath size.
	self
		assert: game controlPanel laserPathCounter led digitCount
		equals: 3
]

{ #category : 'tests' }
LaserGameElementTestCase >> testTheLaserHomeSitsInTheMarginAndCostsNoSize [
	"The bar stands in the margin under the board, not in a row of its own, so it costs the game no
	size. That is arranged by taking the bottom margin out of the padding and giving it to the
	panel instead: the column under the board then ends where the game ends, and the bar fills the
	band between the last row of cells and the bottom edge."

	| column |
	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	column := game board parent.
	column measure: BlExtentMeasurementSpec unspecified.
	self
		assert: column measuredExtent
		equals: (LaserGameBoardElement extentForGrid: game grid)
			+ (0 @ LaserGameElement gameMargin).
	self
		assert: game padding
		equals: (BlInsets
				 top: LaserGameElement gameMargin
				 left: LaserGameElement gameMargin
				 bottom: 0
				 right: LaserGameElement gameMargin).
	self
		assert: game controlPanel margin
		equals: (BlInsets bottom: LaserGameElement gameMargin).
	self
		assert:
		LaserGameElement gameMargin + (column measuredExtent y
			 max: LaserGameControlPanelElement contentHeight
				 + LaserGameElement gameMargin)
		equals: (LaserGameElement extentForGrid: game grid) y
]

{ #category : 'tests' }
LaserGameElementTestCase >> testTogglingTheLaserFiresItAndStopsItAgain [
	"The fire button toggles: the first click fires the laser and lights the target, the second
	stops it and puts the target out. The board and the button label both follow. The disc is the
	last child of the target, since a lit target draws the beam under its picture."

	| target |
	target := game grid at: 5 @ 1.
	game toggleLaser.
	self assert: game laserIsActive.
	self assert: target isOn.
	self
		assert: (game board cellElementAt: 5 @ 1) children last background paint color
		equals: LaserGameColors targetCenterColorActive.
	self assert: game controlPanel fireButton labelText asString equals: 'Stop'.
	game toggleLaser.
	self deny: game laserIsActive.
	self assert: target isOff.
	self
		assert: (game board cellElementAt: 5 @ 1) children last background paint color
		equals: LaserGameColors targetCenterColorIdle.
	self assert: game controlPanel fireButton labelText asString equals: 'Fire'
]

{ #category : 'tests' }
LaserGameElementTestCase >> testUndoOnABoardNobodyHasTouchedDoesNothing [
	"An empty undo stack answers false, and the game does nothing with it: no move is counted and
	the board is left as it stands."

	self deny: game grid undo.
	game undo.
	self assert: game moves equals: 0.
	self assert: game controlPanel movesCounter value equals: 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testUndoTakesTheLastMoveBackAndCountsAsAMove [
	"The Undo button asks the grid to undo, and when the grid says it did, the game counts a move
	and draws itself again. The count is not taken back, since an undo must not remove any count
	from the total of the player, so a move and its undo are two moves."

	game grid pushCellEastFromLocation: 1 @ 2.
	game incrementMoves.
	self assert: (game grid at: 2 @ 2) class equals: MirrorCell.
	game undo.
	self assert: (game grid at: 1 @ 2) class equals: MirrorCell.
	self assert: game grid movesStack isEmpty.
	self assert: game moves equals: 2.
	self
		assert: game controlPanel movesCounter value
		equals: game moves
]

{ #category : 'tests' }
LaserGameElementTestCase >> testWindowIsFilledWithTheColorRamp [
	"The window is filled with a ramp of two colours rather than one flat colour, running the
	fraction of the way across and down that the ramp direction states."

	| paint |
	paint := game background paint.
	self assert: paint class equals: BlLinearGradientPaint.
	self assert: paint stops equals: LaserGameColors windowColorRamp.
	self assert: paint start equals: 0 @ 0.
	self assert: paint end equals: LaserGameColors windowColorRampDirection
]
