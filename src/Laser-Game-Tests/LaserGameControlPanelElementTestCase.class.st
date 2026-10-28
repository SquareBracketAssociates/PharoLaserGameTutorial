Class {
	#name : 'LaserGameControlPanelElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'helpers' }
LaserGameControlPanelElementTestCase >> newPanel [
	"Answer the control panel of a game playing on the demo grid, with the laser not firing."

	^ (LaserGameElement on: GridExample demoGrid) controlPanel
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testARowOfTwoButtonsFitsInsideThePanel [
	"A row of buttons is as wide as its buttons and the gaps around and between them. Two buttons
	fill the panel exactly, so the last button of a row stops one gap short of the board beside
	the panel; a third button in the same row would not fit."

	| widthOfTwo |
	widthOfTwo := (2 * LaserGameControlPanelElement buttonWidth)
	              + (3 * LaserGameControlPanelElement buttonGap).
	self assert: widthOfTwo equals: LaserGameElement panelWidth.
	self
		assert: widthOfTwo + LaserGameControlPanelElement buttonWidth
			+ LaserGameControlPanelElement buttonGap
			> LaserGameElement panelWidth
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testActiveMirrorsCounterIsThreeDigitsCaptionedActiveMirrors [
	"The same three digit display again, captioned Active Mirrors. That caption is the longest of
	the four, so it decides how wide a counter has to be."

	| panel |
	panel := self newPanel.
	self assert: panel activeMirrorsCounter class equals: LaserGameCounterElement.
	self assert: panel activeMirrorsCounter led digitCount equals: 3.
	self
		assert: panel activeMirrorsCounter label text asString
		equals: 'Active Mirrors'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testButtonColumnSitsAtTheBottomLeftOneGapIn [
	"The buttons are aligned to the bottom left corner of the panel, one gap away from both edges,
	and the rows are one gap apart. The cell spacing is the whole of the gap, since a linear
	layout spaces its cells from its own edges as well as from each other; a margin on top of it
	would take the bottom row past the right edge of the panel and up against the board."

	| panel column |
	panel := self newPanel.
	column := panel buttonColumn.
	self
		assert: column constraints frame horizontal alignment
		equals: BlElementAlignment horizontal start.
	self
		assert: column constraints frame vertical alignment
		equals: BlElementAlignment bottom.
	self assert: column margin equals: BlInsets empty.
	self
		assert: column layout cellSpacing
		equals: LaserGameControlPanelElement buttonGap
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testContentHeightIsWhatTheCountersAndButtonsMeasure [
	"The height the panel falls back on is stated from the constants, so that it can be asked of
	the class before a panel exists. Here it is checked against what the two columns actually
	measure, which is the only thing that keeps the statement true."

	| panel counters buttons |
	panel := self newPanel.
	counters := panel counterColumn.
	buttons := panel buttonColumn.
	counters measure: BlExtentMeasurementSpec unspecified.
	buttons measure: BlExtentMeasurementSpec unspecified.
	self
		assert: LaserGameControlPanelElement contentHeight
		equals:
			counters measuredExtent y
			+ (2 * LaserGameControlPanelElement counterGap)
			+ buttons measuredExtent y.
	self
		assert: counters children size
		equals: LaserGameControlPanelElement counterCount
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testCounterColumnHoldsTheFourCountersInOrder [
	"The four counters sit in one column, in order: the beam, the moves, the mirrors, then the
	active mirrors."

	| panel |
	panel := self newPanel.
	self assert: panel counterColumn children asArray equals: {
			panel laserPathCounter.
			panel movesCounter.
			panel mirrorsCounter.
			panel activeMirrorsCounter }
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testCounterColumnSitsAtTheTopLeftOneGapIn [
	"The counters are aligned to the top left corner of the panel, one counter gap away from both
	edges. The buttons keep the bottom."

	| panel column |
	panel := self newPanel.
	column := panel counterColumn.
	self assert: (panel children includes: column).
	self
		assert: column constraints frame horizontal alignment
		equals: BlElementAlignment horizontal start.
	self
		assert: column constraints frame vertical alignment
		equals: BlElementAlignment top.
	self
		assert: column margin
		equals: (BlInsets all: LaserGameControlPanelElement counterGap)
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testCounterShowsTheBeamLengthOnlyWhileTheLaserFires [
	"While the laser fires the counter is bright and holds the number of path elements of the
	grid; while it does not, the counter is dim and holds zero. The counter follows the grid only
	when it is updated, which is what the fire button and a move do."

	| panel |
	panel := self newPanel.
	self assert: panel laserPathCounter value equals: 0.
	self deny: panel laserPathCounter highlighted.
	panel game grid fireLaser.
	panel updateCounters.
	self assert: panel laserPathCounter highlighted.
	self
		assert: panel laserPathCounter value
		equals: panel game grid laserBeamPath size.
	self assert: panel laserPathCounter value > 0.
	panel game grid stopLaser.
	panel updateCounters.
	self deny: panel laserPathCounter highlighted.
	self assert: panel laserPathCounter value equals: 0
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testEveryButtonCentresItsLabel [
	"A button is wider than any of its labels, so the label has to stand in the middle of it. A
	Toplo button lays its label container out with a linear layout, and that layout aligns to the
	start unless it is told otherwise, which leaves every label against the left edge of its
	button. Where the label lands is Bloc's arithmetic and is not repeated here: nothing is laid
	out, and no element is opened."

	| panel |
	panel := self newPanel.
	panel buttonColumn children do: [ :row |
		row children do: [ :button |
			self
				assert: button layout alignment horizontal
				equals: BlElementAlignment horizontal center ] ]
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testEveryButtonIsFortyByTwenty [
	"Every button is forty by twenty. Sizes are read from the layout constraints, since nothing is
	laid out yet."

	| panel |
	panel := self newPanel.
	{
		panel quitButton.
		panel fireButton.
		panel newGameButton } do: [ :button |
		self
			assert: button constraints horizontal resizer size
			equals: LaserGameControlPanelElement buttonWidth.
		self
			assert: button constraints vertical resizer size
			equals: LaserGameControlPanelElement buttonHeight ]
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testEveryButtonLabelFitsInsideTheButton [
	"The width of a button is stated rather than measured, so the six labels the panel can show
	are measured against it instead, with a margin on each side of the longest. Reset and Undo
	are the longest two: in a forty pixel button they filled all but a few pixels of it, and a
	font a little wider would have painted them over its edge."

	LaserGameControlPanelElement buttonLabels do: [ :each |
		self
			assert:
				(LaserGameControlPanelElement widthOfButtonLabel: each)
				+ (2 * LaserGameControlPanelElement buttonLabelMargin)
			<= LaserGameControlPanelElement buttonWidth
			description: each , ' does not fit inside a button' ]
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testEveryCounterFitsInsideThePanel [
	"The panel is as wide as a row of two buttons, so the widest counter has to fit in the width
	the buttons ask for, with the gap on both sides. A counter takes the size of its caption, so
	the column is asked to measure itself first; nothing is laid out, and no element is opened."

	| panel |
	panel := self newPanel.
	panel counterColumn measure: BlExtentMeasurementSpec unspecified.
	panel counterColumn children do: [ :counter |
		self
			assert:
				counter measuredExtent x
				+ (2 * LaserGameControlPanelElement counterGap)
			<= LaserGameElement panelWidth ]
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testEveryCounterIsAsWideAsThePanelLessAGapOnEachSide [
	"A counter that took the width of its own caption would leave the four boxes four different
	widths, with their right edges ragged. They are all given the width of the panel less the gap
	the column stands in, so the four boxes are the same width and their edges line up under each
	other."

	| panel widths |
	panel := self newPanel.
	panel counterColumn measure: BlExtentMeasurementSpec unspecified.
	widths := (panel counterColumn children collect: [ :each |
		           each measuredExtent x ]) asSet.
	self assert: widths size equals: 1.
	self
		assert: widths anyOne
		equals: LaserGameControlPanelElement counterWidth.
	self
		assert: LaserGameControlPanelElement counterWidth
		equals:
		LaserGameElement panelWidth
		- (2 * LaserGameControlPanelElement counterGap)
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testFireButtonSaysWhatAClickWillDo [
	"The label names the action, not the state: Fire while the laser is off, Stop while it fires."

	| panel |
	panel := self newPanel.
	self deny: panel game laserIsActive.
	self assert: panel fireButtonLabel equals: 'Fire'.
	panel game grid fireLaser.
	self assert: panel fireButtonLabel equals: 'Stop'.
	panel game grid stopLaser.
	self assert: panel fireButtonLabel equals: 'Fire'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testLaserPathCounterIsThreeDigitsCaptionedLaserPath [
	"The counter of the beam is three digits, captioned Laser Path."

	| panel |
	panel := self newPanel.
	self assert: panel laserPathCounter class equals: LaserGameCounterElement.
	self assert: panel laserPathCounter led digitCount equals: 3.
	self assert: panel laserPathCounter label text asString equals: 'Laser Path'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testMirrorCountersShowTheGridCountsAndAreNeverBright [
	"Both mirror counters are set from the grid and never highlighted, like the move counter: only
	the beam counter says whether the laser is on. The demo grid holds ten mirrors, of which three
	are lit once the laser fires; the numbers are read from the grid, since GridTestCase is where
	they are written down."

	| panel |
	panel := self newPanel.
	self
		assert: panel mirrorsCounter value
		equals: panel game grid numberOfMirrors.
	self assert: panel activeMirrorsCounter value equals: 0.
	panel game grid fireLaser.
	panel updateCounters.
	self
		assert: panel mirrorsCounter value
		equals: panel game grid numberOfMirrors.
	self
		assert: panel activeMirrorsCounter value
		equals: panel game grid numberOfActiveMirrors.
	self assert: panel activeMirrorsCounter value > 0.
	self deny: panel mirrorsCounter highlighted.
	self deny: panel activeMirrorsCounter highlighted
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testMirrorsCounterIsThreeDigitsCaptionedMirrors [
	"The same three digit display as the others, captioned Mirrors."

	| panel |
	panel := self newPanel.
	self assert: panel mirrorsCounter class equals: LaserGameCounterElement.
	self assert: panel mirrorsCounter led digitCount equals: 3.
	self assert: panel mirrorsCounter label text asString equals: 'Mirrors'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testMovesCounterIsThreeDigitsCaptionedMoves [
	"The same three digit display as the beam counter, captioned Moves."

	| panel |
	panel := self newPanel.
	self assert: panel movesCounter class equals: LaserGameCounterElement.
	self assert: panel movesCounter led digitCount equals: 3.
	self assert: panel movesCounter label text asString equals: 'Moves'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testMovesCounterShowsTheMoveCountAndIsNeverBright [
	"The move counter is never highlighted: only the counter of the beam says whether the laser is
	on."

	| panel |
	panel := self newPanel.
	self assert: panel movesCounter value equals: 0.
	panel game incrementMoves.
	panel game grid fireLaser.
	panel updateCounters.
	self assert: panel movesCounter value equals: 1.
	self deny: panel movesCounter highlighted.
	self assert: panel laserPathCounter highlighted
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testNewGameButtonHasTheRowAboveTheOthers [
	"New sits in the second row from the bottom, first column: the Quit and Fire row is the lowest
	of the column and the New row sits directly above it. What else stands in the row, and what
	rows stand above it, is asserted by #testUndoButtonSharesTheRowWithNewGame and
	#testResetButtonHasTheTopRowToItself."

	| panel rows |
	panel := self newPanel.
	rows := panel buttonColumn children asArray.
	self assert: rows last equals: panel buttonRow.
	self
		assert: (rows indexOf: panel newGameRow) + 1
		equals: (rows indexOf: panel buttonRow).
	self assert: panel newGameRow children first equals: panel newGameButton.
	self assert: panel newGameButton labelText asString equals: 'New'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testPanelHoldsARowOfTwoButtons [
	"The game's panel is a control panel element. It holds the column of button rows, and the
	bottom row holds the Quit button then the Fire button."

	| panel row |
	panel := self newPanel.
	self assert: panel class equals: LaserGameControlPanelElement.
	row := panel buttonRow.
	self assert: (panel children includes: panel buttonColumn).
	self assert: (panel buttonColumn children includes: row).
	self assert: row children asArray
		equals: { panel quitButton. panel fireButton }.
	self assert: panel quitButton class equals: ToButton.
	self assert: panel fireButton class equals: ToButton.
	self assert: panel quitButton labelText asString equals: 'Quit'.
	self assert: panel fireButton labelText asString equals: 'Fire'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testPanelIsAPanelWideColumnAsTallAsTheBoardOrItsContents [
	"The panel sizes itself: a panel width, and the height of the board beside it — unless the
	board is shorter than what the panel holds. Then the panel keeps the height of its contents, so
	the counters never reach the buttons. Both halves of that rule are checked, on a board of one
	row and on a board of enough rows to be taller than the panel, so neither half depends on what
	a cell measures."

	| short tall rows |
	short := GridFactory randomizedGridOfExtent: 5 @ 1.
	rows := LaserGameControlPanelElement contentHeight
	        // CellRenderer cellExtent y + 2.
	tall := GridFactory randomizedGridOfExtent: 5 @ rows.
	{ short. tall } do: [ :grid |
		| panel |
		panel := (LaserGameElement on: grid) controlPanel.
		self
			assert: panel constraints horizontal resizer size
			equals: LaserGameElement panelWidth.
		self
			assert: panel constraints vertical resizer size
			equals: ((LaserGameBoardElement extentForGrid: grid) y
				 max: LaserGameControlPanelElement contentHeight) ].
	self
		assert: (LaserGameBoardElement extentForGrid: short) y
		< LaserGameControlPanelElement contentHeight.
	self
		assert: (LaserGameBoardElement extentForGrid: tall) y
		> LaserGameControlPanelElement contentHeight
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testResetButtonHasTheTopRowToItself [
	"Reset sits in row three, column one, which is the row above New and Undo and the topmost of
	the three. Its button is the one thing the panel does not hold in an instance variable, so it
	is read from its row. The column starts with the divider bar, so the three rows follow it."

	| panel |
	panel := self newPanel.
	self assert: panel buttonColumn children asArray equals: {
			panel panelDivider.
			panel resetRow.
			panel newGameRow.
			panel buttonRow }.
	self assert: panel resetRow children asArray equals: { panel resetButton }.
	self assert: panel resetButton class equals: ToButton.
	self assert: panel resetButton labelText asString equals: 'Reset'
]

{ #category : 'tests - inspecting' }
LaserGameControlPanelElementTestCase >> testTheLabelsTabSaysWhetherEveryLabelFitsInsideItsButton [
	"The Labels tab is testEveryButtonLabelFitsInsideTheButton with the numbers shown: what each
	label needs, what a button holds, and the room left over. This is the tab to read before
	changing a label or a button width, because it says which label is the one that decides the
	width."

	| builder table rows needs spare |
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := LaserGameControlPanelElement inspectionLabels: builder.
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals: #( 'Label' 'Needs' 'Button holds' 'Spare' 'Fits' ).
	rows := table items.
	self
		assert: (rows collect: [ :each | each key ]) asArray
		equals: LaserGameControlPanelElement buttonLabels.
	needs := table columns second.
	spare := table columns fourth.
	rows do: [ :each |
			self
				assert: (needs evaluation value: each)
				equals: each value printString.
			self
				assert: (spare evaluation value: each)
				equals:
					(LaserGameControlPanelElement buttonWidth - each value)
						printString.
			self assert: (table columns last evaluation value: each) equals: 'yes' ]
]

{ #category : 'tests - inspecting' }
LaserGameControlPanelElementTestCase >> testTheMeasuresTabStatesEveryWidthAndHeightIKeep [
	"The Measures tab is every number the panel is laid out from, on one page. The panel is a
	column of fixed widths and gaps, and a reader who wants to know why a button is fifty wide
	should not have to open eleven methods to find out."

	| builder table facts |
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := LaserGameControlPanelElement inspectionMeasures: builder.
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals: #( 'Measure' 'Pixels' ).
	facts := table items.
	self
		assert: (facts collect: [ :each | each key ]) asArray
		equals: (LaserGameControlPanelElement inspectionMeasureFacts collect: [
				 :each | each key ]) asArray.
	self
		assert:
			(facts detect: [ :each | each key = 'Button width' ]) value
		equals: LaserGameControlPanelElement buttonWidth.
	self
		assert:
			(facts detect: [ :each | each key = 'Counter width' ]) value
		equals: LaserGameControlPanelElement counterWidth.
	self
		assert: (table columns last evaluation value: facts first)
		equals: facts first value printString
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testThePanelShowsADividerAboveItsButtons [
	"A bar runs across the panel above the buttons, a gap in from each edge and five pixels tall.
	It is the first child of the column of button rows, so it stands above them wherever they
	stand, rather than hanging off the bottom edge of the panel at an offset that would have to be
	found again whenever a row of buttons is added."

	| panel divider |
	panel := self newPanel.
	divider := panel panelDivider.
	self assert: (panel buttonColumn children includes: divider).
	self assert: panel buttonColumn children first equals: divider.
	self
		assert: divider constraints horizontal resizer size
		equals:
		LaserGameElement panelWidth
		- (2 * LaserGameControlPanelElement buttonGap).
	self
		assert: divider constraints vertical resizer size
		equals: LaserGameControlPanelElement dividerHeight.
	self
		assert: divider background paint stops first value
		equals: LaserGameColors panelDividerDarkColor.
	self
		assert: divider background paint stops last value
		equals: LaserGameColors panelDividerLightColor
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testUndoButtonSharesTheRowWithNewGame [
	"Undo sits in row two, column two: beside New, above Quit and Fire."

	| panel |
	panel := self newPanel.
	self assert: panel newGameRow children asArray equals: {
			panel newGameButton.
			panel undoButton }.
	self assert: panel undoButton class equals: ToButton.
	self assert: panel undoButton labelText asString equals: 'Undo'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testUpdatingTheLabelPutsItOnTheButton [
	"The label on the button follows the grid only when it is updated, which is what a click does."

	| panel |
	panel := self newPanel.
	panel game grid fireLaser.
	self assert: panel fireButton labelText asString equals: 'Fire'.
	panel updateFireButtonLabel.
	self assert: panel fireButton labelText asString equals: 'Stop'
]
