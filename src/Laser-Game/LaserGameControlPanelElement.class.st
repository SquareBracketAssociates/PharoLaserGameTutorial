"
I am the control panel of the game: the column beside the board that holds its buttons and its counters. I hold what I am asked about in an instance variable, so nothing has to search my children by name.

Five buttons. Quit asks the game to close. Fire has a label that says what a click will do: `'Fire'` while the laser is off, `'Stop'` while it fires. New deals a new randomized board. Undo takes the last move back. Reset unwinds the whole undo stack at once. Quit and Fire share the bottom row, New and Undo the row above it, and Reset has the top row to itself.

Four counters: the length of the beam, the number of moves made, the number of mirrors standing on the board, and the number of those the beam lights. Only the first is ever bright, since it alone says whether the laser is on.

The buttons sit at my bottom left corner and the counters at my top left corner. A divider bar stands above the buttons. I am painted transparent, so the window ramp behind me shows through.

Instance variables:

- `game`: the `LaserGameElement` I control. Setting it builds everything I show.
- `quitButton`, `fireButton`, `newGameButton`, `undoButton`: four of the five buttons. The fifth, Reset, is not held: a tenth instance variable would trip `ReExcessiveVariablesRule`, and `resetButton` reads it from `resetRow`, which is the only button of its row.
- `laserPathCounter`, `movesCounter`, `mirrorsCounter`, `activeMirrorsCounter`: the four counters, in the order they are stacked.

The two columns I stack are not held either: `counterColumn` is my first child and `buttonColumn` my last, and `resetRow`, `newGameRow` and `buttonRow` read the three rows of the button column the same way.

I ask the game what to display and I tell the game what the player did. What I read from the grid is the length of the beam and the two mirror counts.
"
Class {
	#name : 'LaserGameControlPanelElement',
	#superclass : 'BlElement',
	#instVars : [
		'game',
		'quitButton',
		'fireButton',
		'newGameButton',
		'laserPathCounter',
		'movesCounter',
		'mirrorsCounter',
		'activeMirrorsCounter',
		'undoButton'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonGap [
	"Answer the gap, in pixels, between the buttons and around the row they sit in."

	^ 10
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonHeight [
	"Answer the height, in pixels, of a control panel button."

	^ 20
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonLabelMargin [
	"Answer the space, in pixels, my button width keeps on each side of its longest label. It is
	what makes the width a statement about the labels rather than a number that happens to fit."

	^ 6
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonLabels [
	"Answer every label a button of mine can show: the five buttons, and the second label the
	fire button takes while the laser is firing. They are what my button width has to hold."

	^ #( 'Quit' 'Fire' 'Stop' 'New' 'Undo' 'Reset' )
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonRowCount [
	"Answer how many rows of buttons I stack: two rows of two, and the row Reset has to itself."

	^ 3
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonWidth [
	"Answer the width, in pixels, of a control panel button. Fifty holds every label of
	#buttonLabels with #buttonLabelMargin to spare on each side, which
	#testEveryButtonLabelFitsInsideTheButton is what checks. The panel width follows from this
	number, so widening a button widens the panel and not the space the buttons stand in."

	^ 50
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> contentHeight [
	"Answer the height, in pixels, of everything I hold: my counters, stacked with a gap between
	them and a gap above and below, and under them the divider bar and the rows of buttons,
	spaced the same way. A counter takes the size of its caption, so one is built and measured;
	nothing is laid out and nothing is opened."

	| counter |
	counter := LaserGameCounterElement labelled: 'Active Mirrors' digits: 3.
	counter measure: BlExtentMeasurementSpec unspecified.
	^ ((self counterCount * counter measuredExtent y)
	   + ((self counterCount + 3) * self counterGap)
	   + (self buttonRowCount * self buttonHeight)
	   + self dividerHeight
	   + ((self buttonRowCount + 2) * self buttonGap)) ceiling
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> counterCount [
	"Answer how many counters I stack."

	^ 4
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> counterGap [
	"Answer the gap, in pixels, between the counters and around the column they sit in."

	^ 4
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> counterWidth [
	"Answer the width, in pixels, of every counter: my own width, less the gap the column of
	counters stands in on each side. A counter left to take the size of its caption would leave
	the four of them four different widths; one width for all four lines their edges up under
	each other and fills the panel."

	^ LaserGameElement panelWidth - (2 * self counterGap)
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> dividerHeight [
	"Answer the height, in pixels, of the bar drawn across me above the buttons."

	^ 5
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> heightForGrid: aGrid [
	"Answer how tall I am beside a board showing aGrid: as tall as that board, or as tall as what I
	hold when the board is shorter than that. Without the second half, a board small enough would
	have my counters and my buttons overlap."

	^ (LaserGameBoardElement extentForGrid: aGrid) y max: self contentHeight
]

{ #category : 'inspecting' }
LaserGameControlPanelElement class >> inspectionLabelFacts [
	"Answer each label a button of mine can show, with the width that label needs: the width Toplo
	measures for the text, with my label margin on each side of it. The width is rounded up,
	since a button takes whole pixels."

	^ self buttonLabels collect: [ :each |
		  each
		  -> ((self widthOfButtonLabel: each) ceiling + (2 * self buttonLabelMargin)) ]
]

{ #category : 'inspecting' }
LaserGameControlPanelElement class >> inspectionLabels: aBuilder [
	"Show what each of my labels needs, what a button holds, and the room left over. My button
	width is a number chosen to hold the longest label, so this tab is where a reader finds out
	which label chose it and how little room is left."

	<inspectorPresentationOrder: 2 title: 'Labels'>
	^ aBuilder newTable
		  items: self inspectionLabelFacts;
		  addColumn: (SpStringTableColumn title: 'Label' evaluated: [ :each |
					   each key ]);
		  addColumn: (SpStringTableColumn title: 'Needs' evaluated: [ :each |
					   each value printString ]);
		  addColumn:
			  (SpStringTableColumn title: 'Button holds' evaluated: [ :each |
					   self buttonWidth printString ]);
		  addColumn: (SpStringTableColumn title: 'Spare' evaluated: [ :each |
					   (self buttonWidth - each value) printString ]);
		  addColumn: (SpStringTableColumn title: 'Fits' evaluated: [ :each |
					   each value <= self buttonWidth
						   ifTrue: [ 'yes' ]
						   ifFalse: [ 'no' ] ]);
		  yourself
]

{ #category : 'inspecting' }
LaserGameControlPanelElement class >> inspectionMeasureFacts [
	"Answer every number I am laid out from, each one named, in the order the panel is built:
	the panel and its counters first, then the buttons, then the height the two of them come to."

	^ OrderedCollection new
		  add: 'Panel width' -> LaserGameElement panelWidth;
		  add: 'Counters' -> self counterCount;
		  add: 'Counter width' -> self counterWidth;
		  add: 'Counter gap' -> self counterGap;
		  add: 'Rows of buttons' -> self buttonRowCount;
		  add: 'Button width' -> self buttonWidth;
		  add: 'Button height' -> self buttonHeight;
		  add: 'Button gap' -> self buttonGap;
		  add: 'Button label margin' -> self buttonLabelMargin;
		  add: 'Divider height' -> self dividerHeight;
		  add: 'Content height' -> self contentHeight;
		  yourself
]

{ #category : 'inspecting' }
LaserGameControlPanelElement class >> inspectionMeasures: aBuilder [
	"Show every width, height and gap I lay myself out from. Two of these numbers were bugs the
	player reported -- four counters of four widths, and labels running off their buttons -- and
	both were found by writing the numbers down beside each other."

	<inspectorPresentationOrder: 1 title: 'Measures'>
	^ aBuilder newTable
		  items: self inspectionMeasureFacts;
		  addColumn: (SpStringTableColumn title: 'Measure' evaluated: [ :each |
					   each key ]);
		  addColumn: (SpStringTableColumn title: 'Pixels' evaluated: [ :each |
					   each value printString ]);
		  yourself
]

{ #category : 'instance creation' }
LaserGameControlPanelElement class >> on: aGame [
	"Answer a control panel for aGame."

	| panel |
	panel := self new.
	panel game: aGame.
	^ panel
]

{ #category : 'measuring' }
LaserGameControlPanelElement class >> widthOfButtonLabel: aString [
	"Answer the width, in pixels, a button captioned aString needs for its label: a button is
	built and measured, and nothing is laid out and nothing is opened. Toplo measures the label
	with the font its theme gives a button, which is the only thing that knows how wide the text
	is going to be."

	| button |
	button := ToButton labelText: aString.
	button measure: BlExtentMeasurementSpec unspecified.
	^ button measuredExtent x
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> activeMirrorsCounter [
	"Answer the counter showing how many mirrors the beam lights."

	^ activeMirrorsCounter
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> buttonColumn [
	"Answer the column of button rows at the bottom of me. It is my last child, since #rebuild
	adds it after the counters."

	^ self children last
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> buttonRow [
	"Answer the bottom row of buttons: Quit and Fire. It is the last row of the button column."

	^ self buttonColumn children last
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> counterColumn [
	"Answer the column of counters at the top of me. It is my first child, since #rebuild adds the
	counters before the buttons; the rows of the button column are read by position in the same
	way."

	^ self children first
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> fireButton [
	"Answer the button that fires and stops the laser. I hold it, so nothing has to search for it
	by name."

	^ fireButton
]

{ #category : 'updating' }
LaserGameControlPanelElement >> fireButtonLabel [
	"Answer what the fire button says: what a click will do, not what the laser is doing."

	^ self game laserIsActive
		  ifTrue: [ 'Stop' ]
		  ifFalse: [ 'Fire' ]
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> game [
	"Answer the game this panel controls."

	^ game
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> game: aGame [
	"Control aGame. Setting the game builds the buttons, since a button acts on a game."

	game := aGame.
	self rebuild
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> initialize [
	"A panel is a blank column with its buttons at the bottom left corner and its counters at the
	top left corner. A frame layout puts a child where it is aligned, which is what those two
	corners need."

	super initialize.
	self background: LaserGameColors controlPanelColor.
	self layout: BlFrameLayout new
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> laserPathCounter [
	"Answer the counter showing how long the laser beam is."

	^ laserPathCounter
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> mirrorsCounter [
	"Answer the counter showing how many mirrors stand on the board."

	^ mirrorsCounter
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> movesCounter [
	"Answer the counter showing how many moves the player has made."

	^ movesCounter
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newActiveMirrorsCounter [
	"Answer the counter showing how many mirrors the beam lights: three digits, captioned 'Active
	Mirrors'. That caption is the longest of the four, but every counter is the width of the panel
	less its gaps, so the longest caption decides nothing."

	^ self newCounterLabelled: 'Active Mirrors' digits: 3
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newButton: aLabel action: aBlock [
	"Answer a labelled button that evaluates aBlock when it is clicked. Toplo gives the look and
	the click, so only the label, the size and the action are left here. A Toplo button lays its
	label out with a linear layout, which aligns to the start unless it is told otherwise, so the
	label is centred here: a button is wider than any of its labels."

	| button |
	button := ToButton labelText: aLabel.
	button layout alignCenter.
	button extent: self class buttonWidth @ self class buttonHeight.
	button clickAction: aBlock.
	^ button
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newButtonColumn [
	"Answer the column of button rows: the bottom left corner of the panel, one gap from both
	edges, the rows one gap apart, the last row against the bottom. The divider bar is the first
	child, so it stands above every row of buttons. The cell spacing of a linear layout is added
	around the cells as well as between them, so it is the whole of the gap: a margin here would
	double the gap on the left and push the last button of the bottom row against the board."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class buttonGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignBottom ].
	column addChild: self newPanelDivider.
	column addChild: self newResetRow.
	column addChild: self newNewGameRow.
	column addChild: self newButtonRow.
	^ column
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newButtonRow [
	"Answer the bottom row of buttons: Quit first, then Fire."

	^ self newRowOfButtons: {
			  quitButton.
			  fireButton }
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newCounterColumn [
	"Answer the column of counters, at the top left corner of the panel, one gap away from both
	edges: the beam length, the move count, the number of mirrors, and the number of mirrors the
	beam lights. The layout stacks them one gap apart, so no offset is counted here."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class counterGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignTop ].
	column margin: (BlInsets all: self class counterGap).
	column addChild: laserPathCounter.
	column addChild: movesCounter.
	column addChild: mirrorsCounter.
	column addChild: activeMirrorsCounter.
	^ column
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newCounterLabelled: aString digits: anInteger [
	"Answer a counter of anInteger digits captioned aString, as wide as every other counter I
	hold. A counter takes the size of its caption when it is not told otherwise, which would leave
	my four counters four different widths; stating the width here is what lines their edges up,
	and the counter centres its display and its caption in whatever width it is given."

	| counter |
	counter := LaserGameCounterElement labelled: aString digits: anInteger.
	counter constraintsDo: [ :aConstraints |
		aConstraints horizontal exact: self class counterWidth ].
	^ counter
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newFireButton [
	"Answer the button that fires the laser, or stops it if it is already firing. Its label says
	which of the two a click will do."

	^ self newButton: self fireButtonLabel action: [ self game toggleLaser ]
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> newGameButton [
	"Answer the button that starts a new game."

	^ newGameButton
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> newGameRow [
	"Answer the middle row of buttons, holding New and Undo. The column reads from the top and
	starts with the divider bar, so the middle row is its third child."

	^ self buttonColumn children third
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newLaserPathCounter [
	"Answer the counter showing how long the laser beam is: three digits. Three digits hold every
	path a board of this size can produce."

	^ self newCounterLabelled: 'Laser Path' digits: 3
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newMirrorsCounter [
	"Answer the counter showing how many mirrors stand on the board: three digits."

	^ self newCounterLabelled: 'Mirrors' digits: 3
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newMovesCounter [
	"Answer the counter showing how many moves the player has made: three digits."

	^ self newCounterLabelled: 'Moves' digits: 3
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newNewGameButton [
	"Answer the button that throws the board away and deals a new one."

	^ self newButton: 'New' action: [ self game newGame ]
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newNewGameRow [
	"Answer the middle row of buttons, holding New on the left and Undo on its right."

	^ self newRowOfButtons: {
			  newGameButton.
			  undoButton }
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newPanelDivider [
	"Answer the bar that separates my counters from my buttons: as wide as I am but for a gap on
	each side, five pixels tall, filled with a vertical gradient. It is a child of the button
	column, so it stands above the buttons wherever they end up."

	| divider |
	divider := BlElement new.
	divider background: (BlLinearGradientPaint vertical stops: {
					 (0 -> LaserGameColors panelDividerDarkColor).
					 (1 -> LaserGameColors panelDividerLightColor) }).
	divider constraintsDo: [ :aConstraints |
		aConstraints horizontal exact:
			LaserGameElement panelWidth - (2 * self class buttonGap).
		aConstraints vertical exact: self class dividerHeight ].
	^ divider
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newQuitButton [
	"Answer the button that closes the game."

	^ self newButton: 'Quit' action: [ self game quit ]
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newResetButton [
	"Answer the button that puts the board back where it started."

	^ self newButton: 'Reset' action: [ self game reset ]
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newResetRow [
	"Answer the top row of buttons, holding Reset alone. Its button is built here and not kept in
	an instance variable: a tenth would trip ReExcessiveVariablesRule, whose limit is ten, and
	#resetButton reads it back from the row the way #buttonRow and #newGameRow read the rows from
	the column."

	^ self newRowOfButtons: { self newResetButton }
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newRowOfButtons: aCollection [
	"Answer a row holding the buttons of aCollection, one gap apart, no wider than they need."

	| row |
	row := BlElement new.
	row background: BlTransparentBackground new.
	row layout: (BlLinearLayout horizontal cellSpacing: self class buttonGap).
	row constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ].
	aCollection do: [ :each | row addChild: each ].
	^ row
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newUndoButton [
	"Answer the button that takes the last move back. Its label never changes, so only the action
	is needed."

	^ self newButton: 'Undo' action: [ self game undo ]
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> panelDivider [
	"Answer the bar drawn across me above the buttons. It is the first child of the button column,
	which reads from the top."

	^ self buttonColumn children first
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> quitButton [
	"Answer the button that closes the game."

	^ quitButton
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> rebuild [
	"Replace what I hold with fresh counters at my top and fresh buttons at my bottom, both acting
	on my game, and take the width of a panel and the height of the board beside me, or the height
	of what I hold when that is more. The counter column goes in first and the button column
	second, which is the order #counterColumn and #buttonColumn read them back in."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	newGameButton := self newNewGameButton.
	undoButton := self newUndoButton.
	laserPathCounter := self newLaserPathCounter.
	movesCounter := self newMovesCounter.
	mirrorsCounter := self newMirrorsCounter.
	activeMirrorsCounter := self newActiveMirrorsCounter.
	self addChild: self newCounterColumn.
	self addChild: self newButtonColumn.
	self extent: LaserGameElement panelWidth
		@ (self class heightForGrid: self game grid).
	self updateCounters
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> resetButton [
	"Answer the button that puts the board back where it started. It is the only button of its
	row, and the only one I do not hold."

	^ self resetRow children first
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> resetRow [
	"Answer the top row of buttons, holding Reset alone. The column reads from the top and starts
	with the divider bar, so the top row of buttons is its second child."

	^ self buttonColumn children second
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> undoButton [
	"Answer the button that takes the last move back."

	^ undoButton
]

{ #category : 'updating' }
LaserGameControlPanelElement >> updateCounters [
	"Show how long the beam is while the laser fires, and nothing while it does not, show how many
	moves have been made, and show how many mirrors stand on the board and how many of them the
	beam lights. I hold all four counters, so none has to be looked for. Only the beam counter is
	ever bright: it alone says whether the laser is on."

	self game laserIsActive
		ifTrue: [
			self laserPathCounter
				highlighted: true;
				value: self game grid laserBeamPath size ]
		ifFalse: [
			self laserPathCounter
				highlighted: false;
				value: 0 ].
	self movesCounter
		highlighted: false;
		value: self game moves.
	self mirrorsCounter
		highlighted: false;
		value: self game grid numberOfMirrors.
	self activeMirrorsCounter
		highlighted: false;
		value: self game grid numberOfActiveMirrors
]

{ #category : 'updating' }
LaserGameControlPanelElement >> updateFireButtonLabel [
	"Make the fire button say what a click will do now. I hold the button in an instance variable,
	so it does not have to be looked for."

	self fireButton labelText: self fireButtonLabel
]
