# Adding more game stats

Two more numbers for the player: how many mirrors stand on the board, and how many of them the beam lights.
The board can count the mirrors already — *Dealing a random board* gave it `numberOfMirrors` to check the dealer with — so there is one question left to answer and the rest of the work is in the panel, which turns out to be a good thing, because the panel does not fit.

This chapter adds the lit count to the grid, hangs two more counters off the panel, and then makes the panel tall enough and wide enough for the captions it now carries.

There are three lessons in this chapter.
An object that holds something can answer for it, so nothing has to go looking.
A size you need before the thing exists has to be stated, and a stated size needs a test.
And a class that collects instance variables is telling you something.

## The grid can count the lit ones too

Counting mirrors is a question about the board, not about the display, and the board answers it already.
The lit ones are the same question with one more word in it, so the answer goes in the same place:

```smalltalk
Grid >> numberOfActiveMirrors
	"Answer how many of my mirror cells the beam lights. A mirror is lit once the beam has crossed
	it, so this is zero until the laser fires."

	^(self cells select: [:each | (each class = MirrorCell) and: [each isOn]]) size
```

`self cells` answers every cell of the board as a flat collection.
`select:` keeps the ones the block answers true for, and `size` counts what is left.
Reading those two lines aloud gives you the sentence in the comment, which is what you want from a method this small.

It asks each mirror `isOn`.
A cell knows whether the beam is in it, because the beam was traced through the grid and each cell it crossed was told so.
The counter does not re-trace anything; it asks.

We test it on the demo board, where the answer is known:

```smalltalk
GridTestCase >> testNumberOfActiveMirrorsCounter
	"No mirror is lit before the laser fires. The demo beam crosses three of the ten."

	| count |
	count := grid numberOfActiveMirrors.
	self assert: count equals: 0.
	grid fireLaser.
	count := grid numberOfActiveMirrors.
	self assert: count equals: 3
```

That test is two tests in one body, and we did that deliberately: it checks the count before the laser fires and again after, which is the only way we can see that firing is what changed it.
A test that only asserted `3` after firing would pass just as well on a method that always answered three.

It uses `assert:equals:` rather than `assert:`.
Prefer it everywhere you can.
`self assert: count = 3` tells you, when it fails, that something was false; `self assert: count equals: 3` tells you it got 0 and wanted 3, and that difference is most of the time you will spend reading failures.

> **Assert the value, not a true-or-false.** A failure message that carries both numbers is worth more than a shorter line of code.

## Two more counters in the panel

The panel already shows the beam length and the move count, so the new ones are the same thing again.
We write the tests first — they say what the panel is going to be asked for:

```smalltalk
LaserGameControlPanelElementTestCase >> testMirrorsCounterIsThreeDigitsCaptionedMirrors
	"The same three digit display as the others, captioned Mirrors."

	| panel |
	panel := self newPanel.
	self assert: panel mirrorsCounter class equals: LaserGameCounterElement.
	self assert: panel mirrorsCounter led digitCount equals: 3.
	self assert: panel mirrorsCounter label text asString equals: 'Mirrors'
```

```smalltalk
LaserGameControlPanelElementTestCase >> testActiveMirrorsCounterIsThreeDigitsCaptionedActiveMirrors
	"The same three digit display again, captioned Active Mirrors. That caption is the longest of
	the four, so it decides how wide a counter has to be."

	| panel |
	panel := self newPanel.
	self assert: panel activeMirrorsCounter class equals: LaserGameCounterElement.
	self assert: panel activeMirrorsCounter led digitCount equals: 3.
	self
		assert: panel activeMirrorsCounter label text asString
		equals: 'Active Mirrors'
```

`self newPanel` is a helper we have had on the test class since the panel appeared.
It is one line, and it is the reason these tests are three lines each:

```smalltalk
LaserGameControlPanelElementTestCase >> newPanel
	"Answer the control panel of a game playing on the demo grid, with the laser not firing."

	^ (LaserGameElement on: GridExample demoGrid) controlPanel
```

Write that helper the second time you need its two lines, not the fifth.
A test reads better when its first line is the thing it is about.

The column holds four counters now instead of two, so we rewrite the test that listed them rather than add to it:

```smalltalk
LaserGameControlPanelElementTestCase >> testCounterColumnHoldsTheFourCountersInOrder
	"The four counters sit in one column, in order: the beam, the moves, the mirrors, then the
	active mirrors."

	| panel |
	panel := self newPanel.
	self assert: panel counterColumn children asArray equals: {
			panel laserPathCounter.
			panel movesCounter.
			panel mirrorsCounter.
			panel activeMirrorsCounter }
```

We compare the children against an array of the four accessors, which says two things at once: that all four are in the column, and in which order they are drawn.

Nothing in the test mentions a pixel.
The column stacks its children, so their order *is* their position, and a test that measured offsets would be testing the layout instead of the panel.

The last test we write is the one about behaviour:

```smalltalk
LaserGameControlPanelElementTestCase >> testMirrorCountersShowTheGridCountsAndAreNeverBright
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
```

The counts are read from the grid and not written down: the ten and the three live in `GridTestCase`, where they are what is being tested, and here the claim is only that the display agrees with the model.

But a test that compares two things it did not choose can pass by accident — if both were zero, the first assertion would hold and say nothing.
That is what `activeMirrorsCounter value > 0` is for.
One line, and the comparison cannot be vacuous any more.

> **A test that compares two values it did not choose needs one assertion that neither of them is empty.** Otherwise "they agree" and "there is nothing there" look the same.

The two `deny:` lines are about meaning.
The panel has one bright counter, the beam length, and it is bright exactly while the laser fires.
If the mirror counters lit up as well, brightness would stop meaning anything at all.

## What the panel gains

We add two builders, the same shape as the two that were there:

```st
LaserGameControlPanelElement >> newMirrorsCounter
	"Answer the counter showing how many mirrors stand on the board: three digits."

	^ LaserGameCounterElement labelled: 'Mirrors' digits: 3
```
> **Note.** *Counters of one width*, the last chapter but one, sends `newCounterLabelled:digits:` here instead, which gives every counter of the panel the same width.

```st
LaserGameControlPanelElement >> newActiveMirrorsCounter
	"Answer the counter showing how many mirrors the beam lights: three digits, captioned 'Active
	Mirrors'."

	^ LaserGameCounterElement labelled: 'Active Mirrors' digits: 3
```
> **Note.** The same chapter rewrites this one the same way.

And we add two accessors, so that nothing has to look for them:

```smalltalk
LaserGameControlPanelElement >> mirrorsCounter
	"Answer the counter showing how many mirrors stand on the board."

	^ mirrorsCounter
```

```smalltalk
LaserGameControlPanelElement >> activeMirrorsCounter
	"Answer the counter showing how many mirrors the beam lights."

	^ activeMirrorsCounter
```

Those four lines are worth a paragraph of your time.
The alternative — and it is a common one — is to give each display a name when it is built, and to search the element tree for that name when it has to be updated.

Then every update walks the whole game, a misspelled name fails silently, and the panel has no idea what it contains.
Holding the four counters in four variables costs four accessors and removes all of that.
The panel built them; the panel keeps them.

> **Keep what you build.** An object that has to search its own children for them has given away something it already had.

We add the two new ones to the column in order:

```smalltalk
LaserGameControlPanelElement >> newCounterColumn
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
```

Adding a counter here is one line.
Nothing is positioned, because `BlLinearLayout vertical` stacks children in the order they were added and `cellSpacing:` puts the gap between them; nothing is measured, because `fitContent` means "be as big as what you hold"; and the whole column is held one gap in from the edges of the panel by `margin:`.

And we set the two new numbers where the two old ones are set:

```smalltalk
LaserGameControlPanelElement >> updateCounters
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
```

Every counter is set every time, including the ones that cannot have changed.
That is on purpose.
A method that updated only what it thought had changed would need to know what changed, and that is exactly the kind of knowledge that goes stale and leaves a stale number on the screen.

Four assignments are cheap; a counter showing yesterday's value is not.

## The panel that was too short

Run the game now and you get the New button drawn across the caption of the active mirrors counter.

Nothing is broken in the model, and nothing is broken in the counters: the panel is simply not tall enough to hold what it holds.
It had been given the height of the board beside it, which was always more than its two counters and two rows of buttons needed.

Four counters are two hundred and twenty pixels on their own, and the demo board — five rows of fifty pixel cells — is two hundred and fifty tall.
The buttons sit at the bottom, the counters grow from the top, and they met.

The honest fix is to let the panel say how tall it needs to be, so we state the height before any panel exists:

```smalltalk
LaserGameControlPanelElement class >> counterCount
	"Answer how many counters I stack."

	^ 4
```

```st
LaserGameControlPanelElement class >> contentHeight
	"Answer the height, in pixels, of everything I hold: my counters, stacked with a gap between
	them and a gap above and below, and the two rows of buttons under them. A counter takes the
	size of its caption, so one is built and measured; nothing is laid out and nothing is opened."

	| counter |
	counter := LaserGameCounterElement labelled: 'Active Mirrors' digits: 3.
	counter measure: BlExtentMeasurementSpec unspecified.
	^ ((self counterCount * counter measuredExtent y)
	   + ((self counterCount + 3) * self counterGap)
	   + (2 * self buttonHeight) + (3 * self buttonGap)) ceiling
```
> **Note.** *Reset* states the button part of this over `buttonRowCount`, because it adds a third row, and *Minor cosmetic tweaks* adds the divider above the buttons to the sum.

`measure:` is how you ask an element how big it wants to be without opening anything and without a layout pass.
`BlExtentMeasurementSpec unspecified` means "no constraint, tell me what you would like", and `measuredExtent` is the answer.

One counter is built, measured, and thrown away, which is all it takes: the four counters are alike, so one of them times four is the stack.

The height of a counter is not a number you can write down — a counter is as tall as the text in its caption, in whatever font the image is using.
We have to measure it, and `ceiling` turns the measurement into whole pixels, because a window is an integer number of pixels wide and tall.

Then we write the rule, with its two cases:

```smalltalk
LaserGameControlPanelElement class >> heightForGrid: aGrid
	"Answer how tall I am beside a board showing aGrid: as tall as that board, or as tall as what I
	hold when the board is shorter than that. Without the second half, a board small enough would
	have my counters and my buttons overlap."

	^ (LaserGameBoardElement extentForGrid: aGrid) y max: self contentHeight
```

`max:` is the whole fix.
A big board decides the height, as before; a small board does not get a say any more.

A height stated from constants can drift away from what is really in the panel, so we hold the statement to the measurement with a test:

```smalltalk
LaserGameControlPanelElementTestCase >> testContentHeightIsWhatTheCountersAndButtonsMeasure
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
```

This is the test to copy whenever you state a size in one place and build the thing in another.

The constant and the measurement are computed by different code from different directions, so the day somebody adds a fifth counter and forgets `counterCount`, this test says so — and the last assertion says it in one line rather than through a difference of pixels.

> **Whenever a number describes something that is also built, test the number against the thing.** A constant nobody checks is a comment with worse manners.

The panel takes the new height, and so does the window around it.
Two tests that said "as tall as the board" now say "as tall as the board, or as tall as what it holds":

```st
LaserGameControlPanelElementTestCase >> testPanelIsAPanelWideColumnAsTallAsTheBoardOrItsContents
	"The panel sizes itself: a panel width, and the height of the board beside it — unless the
	board is shorter than what the panel holds, which the demo grid of five rows is once the mirror
	counters are there. Then the panel keeps the height of its contents, so the counters never
	reach the buttons."

	| grid panel |
	grid := GridExample demoGrid.
	panel := (LaserGameElement on: grid) controlPanel.
	self
		assert: panel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: panel constraints vertical resizer size
		equals: LaserGameControlPanelElement contentHeight
```
> **Note.** *A missed bug*, the next chapter, rewrites this test: as written here it says which of the two cases the demo board is in, which is true at fifty pixel cells and false at a hundred.

```smalltalk
LaserGameElementTestCase >> testControlPanelIsAFixedColumnAsTallAsTheBoardOrItsContents
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
```

That one asks `heightForGrid:` for the expected value, which is the code under test, so it cannot catch an error inside the rule — the test above it is what does that.
What it does catch is the panel being given some *other* height than the rule's.

The game's own size follows from the panel's:

```smalltalk
LaserGameElement class >> extentForGrid: aGrid
	"Answer the extent a game showing aGrid occupies: the board, the control panel beside it, and
	one margin on each side. The height is the taller of the board and the panel, since a board of
	few rows is shorter than everything the panel holds."

	^ (LaserGameBoardElement extentForGrid: aGrid) x + self panelWidth
	  @ (LaserGameControlPanelElement heightForGrid: aGrid)
	  + (2 * self gameMargin)
```

```st
LaserGameElementTestCase >> testExtentIsTheBoardPlusThePanelPlusTheMargins
	"The game is as wide as the board, the panel beside it and a margin on each side, and as tall
	as the taller of the board and the panel, with a margin above and below. The demo grid is short
	enough for the panel to decide the height."

	| grid expected |
	grid := GridExample demoGrid.
	expected := (LaserGameBoardElement extentForGrid: grid) x
	            + LaserGameElement panelWidth
	            @ (LaserGameControlPanelElement heightForGrid: grid)
	            + (2 * LaserGameElement gameMargin).
	self assert: (LaserGameElement extentForGrid: grid) equals: expected.
	self
		assert: (LaserGameElement extentForGrid: grid)
		equals:
			5 * CellRenderer cellExtent x + 110
			@ LaserGameControlPanelElement contentHeight + 20
```
> **Note.** *A missed bug* rewrites the second assertion so that it does not say which case the board is in, and *Buttons of one width*, the last chapter, changes the `110` to `130` when it widens the buttons.

The window is taller than it was by the difference, and a strip of it sits under the board where the panel goes on.
A board of eight by ten is unchanged, because there the board is the taller of the two.

## The widest caption still has to fit

We made the panel wide enough for a row of two buttons and not a pixel more:

```smalltalk
LaserGameElement class >> panelWidth
	"Answer the width, in pixels, of the control panel beside the board: exactly two buttons and
	the three gaps a row of two stands in. That identity is what makes a row of two fill the panel
	and a row of three not fit, so the panel is stated from the buttons rather than beside them."

	^ (2 * LaserGameControlPanelElement buttonWidth)
	  + (3 * LaserGameControlPanelElement buttonGap)
```

`Active Mirrors` is the longest caption in the panel, so it is the one that could overflow that width.
Rather than widening the panel until it looks right, we ask every counter whether it fits:

```smalltalk
LaserGameControlPanelElementTestCase >> testEveryCounterFitsInsideThePanel
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
```

The test loops over the children instead of naming the longest caption, so a counter added later is checked without your remembering to check it.
And it asserts `<=` rather than an exact width: this is a constraint, not a measurement, and writing it as an equality would make it fail every time a font changed.

> **Test a constraint as a constraint.** `fits inside` is `<=`; turning it into `=` invents a claim the design never made.

## Eight variables, not ten

Four counters and three buttons brought the panel to ten instance variables, and Pharo's code critic says so: `ReExcessiveVariablesRule` complains at nine.
Run the critic on the package from time to time — it is quick, and it usually points you at something real.

It was here.
Two of the ten were not carrying anything.
The counter column and the button column are the panel's two children, in the order the panel adds them, so we can read them rather than remember them:

```smalltalk
LaserGameControlPanelElement >> counterColumn
	"Answer the column of counters at the top of me. It is my first child, since #rebuild adds the
	counters before the buttons; the rows of the button column are read by position in the same
	way."

	^ self children first
```

```smalltalk
LaserGameControlPanelElement >> buttonColumn
	"Answer the column of button rows at the bottom of me. It is my last child, since #rebuild
	adds it after the counters."

	^ self children last
```

That is a trade, and we should name it.
A variable is a second place where the truth lives, and two places can disagree.

`self children first` cannot be stale, because there is nothing to keep up to date; in exchange, the panel now depends on the order in which it adds its own children, which is why both comments say so and why `rebuild` adds them in that order in one place only:

```st
LaserGameControlPanelElement >> rebuild
	"Replace what I hold with fresh counters at my top and fresh buttons at my bottom, both acting
	on my game, and take the width of a panel and the height of the board beside me, or the height
	of what I hold when that is more. The counter column goes in first and the button column
	second, which is the order #counterColumn and #buttonColumn read them back in."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	newGameButton := self newNewGameButton.
	laserPathCounter := self newLaserPathCounter.
	movesCounter := self newMovesCounter.
	mirrorsCounter := self newMirrorsCounter.
	activeMirrorsCounter := self newActiveMirrorsCounter.
	self addChild: self newCounterColumn.
	self addChild: self newButtonColumn.
	self extent: LaserGameElement panelWidth
		@ (self class heightForGrid: self game grid).
	self updateCounters
```
> **Note.** *Undo*, the chapter after the next one, builds an Undo button here as well.

> **A variable that only remembers where something already is, is not state.** Read it from where it is, and say in the comment what the position means.

Eight variables, no critic, and every counter and every button still held rather than hunted for.

## Checking it

Open the game, press Fire, and you get ten and three on the two new counters.
Without opening anything:

```smalltalk
| panel |
panel := (LaserGameElement on: GridExample demoGrid) controlPanel.
panel game grid fireLaser.
panel updateCounters.
{ panel mirrorsCounter value. panel activeMirrorsCounter value }
```

You get `#(10 3)`, which is the chapter in one line: the grid counts, the panel shows, and nothing in between had to go looking for a display.

The suite is green.
In the next chapter we ask what that is actually worth.

# A missed bug

We have had a green suite at the end of every chapter so far.
That is worth something, but it is worth less than you think.
Green means the code does what the tests say, and the tests were written by the same person, on the same afternoon, against the same board.

A test can agree with the code and both can be wrong together, so this chapter changes one number the whole package rests on, reads the failures that come back, and asks of each one whether it found a bug or only noticed that a number moved.

This chapter is about the bug that kind of agreement hides, and about the two habits that find it.
The first is small: run every test before you save your work.
The second is the subject of the chapter: once in a while, change something the whole package depends on, run the tests again, and read the failures.

## One number the whole package rests on

Every size in the game comes from one method:

```smalltalk
CellRenderer class >> cellExtent
	"Answer the size, in pixels, of one cell. Every other size in the package is derived from
	this one, so a cell of another size needs no other change anywhere."

	^50@50
```

Read the second sentence of that comment again.
It is not a description, it is a claim: change this and nothing else needs changing.

The board is cells, the panel stands beside the board, the window holds both, the click regions are cut out of a cell, the arrows are drawn inside one.
If the claim is true, all of that follows one number.

Nothing in the suite checks it.
Every test so far has run at fifty pixels, because that is what the method answers, so the suite says the game works at fifty pixels and says nothing at all about the claim.

> **A claim the design rests on is a claim worth testing.** When a comment says "and nothing else needs changing", that sentence is a test waiting to be written.

## The experiment

A test cannot do this one.
The cell size is read while the tests run, so a test that changed it would be changing the ground under the other tests in the same suite.
This is an experiment we run by hand, in a playground:

```smalltalk
| source classes |
source := (CellRenderer class >> #cellExtent) sourceCode.
classes := TestCase allSubclasses select: [ :c |
	           c package name beginsWith: 'Laser' ].
[
CellRenderer class
	compile: (source copyReplaceAll: '^50@50' with: '^30@30')
	classified: 'constants'.
(classes inject: TestSuite new into: [ :suite :c |
	 suite addTests: c buildSuite tests;
	 yourself ]) run ] ensure: [
	CellRenderer class compile: source classified: 'constants' ]
```

Three things about that snippet are deliberate.
The old source is kept first and put back in an `ensure:` block, so a failure in the middle does not leave the image with a thirty pixel cell in it.

The test classes are found by asking which classes under `TestCase` belong to a package whose name starts with `Laser`, rather than by listing them: a test class added next week is included without anyone remembering to add it.

And `compile:classified:` is how you change a method from code — the same thing the editor does when you accept a method, which means the change is real and the next evaluation sees it.

Run it, and you no longer have a green suite.
The failures come in three kinds, and each kind is a lesson.

## Four tests that wrote the answer down

We wrote lines like this in the window tests of *A window the player can resize*:

```smalltalk
self assert: game naturalExtent equals: 380 @ 270.
game fitIn: 760 @ 540.
```
> **Note.** This is how those tests were written in *A window the player can resize*.
> The two numbers are the extent of the demo board at the cell size of that chapter, and twice it.

`380 @ 270` is not a fact about scaling.
It is the answer the game gave on the day the test was written, copied into the test by hand.

The test now says two things at once: that a window of twice the natural extent doubles the game, which is what the chapter was about, and that the natural extent is three hundred and eighty by two hundred and seventy, which the chapter never meant to claim.

Change a cell, a margin, a button, or a counter, and the test fails for the second reason while the first is still perfectly true.

So we ask the game instead:

```smalltalk
LaserGameElementTestCase >> testAGameScalesToFillTheWindowItIsGiven
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
```

`natural` is read once and every window in the test is built from it.
The assertions are now about ratios — twice as big, half as big — and a ratio is what the method under test is for.

```smalltalk
LaserGameElementTestCase >> testAGameShrinksWithASmallerWindow
	"A window smaller than the board scales the game down rather than cutting it off, so the whole
	board is always in view. Half the natural extent is half the game, whatever a cell measures."

	| natural |
	natural := game naturalExtent.
	game fitIn: natural / 2.
	self assert: game transformation matrix sx equals: 0.5.
	self assert: game constraints position equals: 0 @ 0
```

```smalltalk
LaserGameElementTestCase >> testAGameIgnoresAWindowOfNoSize
	"A space announces its extent while it is being opened, and that extent can be nothing at all.
	Scaling by zero would take the game off the screen, so a window of no size is left alone."

	| natural |
	natural := game naturalExtent.
	game fitIn: natural * 2.
	game fitIn: 0 @ 0.
	self assert: game transformation matrix sx equals: 2.0.
	self assert: game constraints position equals: 0 @ 0
```

The fourth one is the interesting one, because it has a number of its own for you to be careful about: the leftover strip the game is centred in.

```smalltalk
LaserGameElementTestCase >> testAGameKeepsItsShapeInAWindowOfAnotherShape
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
```

The window is stretched in one direction only, so the tighter direction is unchanged, the scale is one, and the slack is the whole of the stretch.
Half of it goes on each side, which is `natural x / 2` — a fraction of a measured value, not a measured value.

> **Ask the object for the number; never copy it into the test.** A copied number turns into a second claim nobody meant to make, and the test fails for the wrong reason on the day something moves.

## One test that stepped a fixed number of pixels

The second kind of failure needs a smaller cell to show itself.
The cross hair test moves the pointer twice and expects both points to land in the same push region, so that the arrow is built once and only the cross hair moves.
It moved the second point four pixels down.

Four pixels is a short distance in a fifty pixel cell and a long one in a twenty six pixel cell.
The push region of a small cell is a few pixels across, so four pixels down from its centre is out of the north region and into the south one, the arrow is rebuilt, and the test fails — for a reason that has nothing to do with cross hairs.

So we measure a step inside a region in that region:

```smalltalk
LaserGameCellElementTestCase >> testTheCrossHairFollowsThePointerWithinOneRegion
	"The arrow is built once per region, since it does not change while the pointer stays in one,
	but the cross hair marks a point and moves with every event. The step down is a quarter of the
	inside region rather than four pixels, so the second point is in the same push region as the
	first at any cell size."

	| element first second extent step |
	element := board cellElementAt: 4 @ 1.
	extent := CellRenderer crossHairExtent.
	step := CellClickRegionInside regionRectangle height // 4 max: 1.
	first := CellClickRegionInside regionRectangle center.
	second := first + (0 @ step).
	element dispatchEvent: (BlMouseMoveEvent new
			 position: first;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushNorth.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: second;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushNorth.
	self
		assert: element crossHairElement constraints position + (extent // 2)
		equals: second
```

A quarter of the region's height, and `max: 1` so that the step is never nothing at all: two points one pixel apart are still two points, and a test that stepped zero would pass while testing nothing.
Integer division rounds the quarter down, which is the safe direction — a shorter step stays inside the region.

> **A step in a test belongs to the thing it steps through.** Write it as a fraction of that thing, and put a floor under it so it cannot round away to nothing.

## Two tests that said which of two things is taller

The third kind of failure is the one worth the whole experiment, because it is not a stale number at all.
These two tests were right, in the sense that every assertion in them was true and remains true at fifty pixels.
They were right the way a coincidence is right.

We gave the panel beside the board a height rule with two cases in the last chapter:

```smalltalk
LaserGameControlPanelElement class >> heightForGrid: aGrid
	"Answer how tall I am beside a board showing aGrid: as tall as that board, or as tall as what I
	hold when the board is shorter than that. Without the second half, a board small enough would
	have my counters and my buttons overlap."

	^ (LaserGameBoardElement extentForGrid: aGrid) y max: self contentHeight
```

Which case applies depends on the cell size, because the board grows with the cell and the contents of the panel do not: a counter is as tall as its caption and a button is as tall as its label.

At fifty pixels the five row demo board is two hundred and fifty tall and the panel holds three hundred and thirty five, so the demo grid is the second case.
At a hundred pixels the same board is five hundred tall, and it is the first case.

The two tests of the last chapter had written down which case they were in.
One asserted that the panel is exactly as tall as its contents, and another that a ten row board is exactly as tall as the panel beside it.

Both are statements about a range of cell sizes, written as if they were statements about the rule.

So we say the rule in the test:

```smalltalk
LaserGameElementTestCase >> testAGameTakesTheSizeOfWhateverBoardItIsGiven
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
```

The expected height is now a `max:` of the two candidates, computed in the test from the cell size and the panel's own constant.

Notice what did *not* change: the test still spells out the arithmetic — eight columns of cells, plus a panel width, plus two margins — rather than calling `extentForGrid:` and comparing it with itself.
A test that repeats the expression under test passes whatever that expression says, including nonsense.

> **State the expected value in different terms from the code that produces it.** `max:` of two measured heights is a different sentence from `heightForGrid:`; copying `heightForGrid:` into the test would be the same sentence twice.

We give the game's own extent the same treatment, and keep one line of plain numbers on purpose:

```smalltalk
LaserGameElementTestCase >> testExtentIsTheBoardPlusThePanelPlusTheMargins
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
```

The `130` and the `20` are the panel width and the margins, written out.
They are numbers that do not follow the cell size, so writing them down costs nothing and buys something: if the panel were ever widened by accident, the first assertion would still pass — it is the code's own expression — and this one would fail.

The panel's own test has the more interesting repair, because its subject is the two cases themselves, and a test about two cases has to be in both of them:

```smalltalk
LaserGameControlPanelElementTestCase >> testPanelIsAPanelWideColumnAsTallAsTheBoardOrItsContents
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
```

Instead of hoping that the grid it had was a short board, the test builds one: a single row is shorter than the panel's contents at any cell size the game supports.

And instead of hoping some other grid is a tall board, it computes the number of rows that makes it one — the panel's contents divided by a cell, plus two for safety.
Then the rule is asserted once, in a loop over the two grids.

The last two assertions are the ones that keep the test honest.
They say the two grids really are on opposite sides of the line.
Without them the loop would still pass if both grids landed in the same case, and the second half of the rule would go untested while the test's name claimed otherwise.

> **A test that depends on which of two values is bigger has a range, not a value.** Either write the rule that covers both cases, or build the inputs that put you in the case you mean — and assert that they did.

## Where the floor is

With those seven repairs we get a green suite at twenty six, thirty, forty, fifty, sixty four, and a hundred pixels.
Below twenty six it is not, and the reason is not a test:

```smalltalk
CellRenderer class >> insideRegionExtent
	"Answer the size of the square in the middle of a cell where a click asks for a push: the
	cell less twenty pixels, so the ring around it keeps its width while the cell grows."

	^self cellExtent - 20
```

Twenty pixels of every cell belong to the ring where a click rotates the mirror, so the square where a click pushes it is the cell less twenty, whatever the cell is.
At twenty six pixels that square is six pixels across.

At twenty four it is four, its centre and its corners are two pixels apart, and the nine points the push table samples stop being nine different points: one test fails.
At twenty the square is nothing at all and twenty six tests fail together.

That is a limit of the design, not a bug in it.
A cell has to be big enough to hold a ring and a square, and the ring was given a fixed width on purpose so that it stays easy to hit as the board grows.

The game supports cells of twenty six pixels and up, and now that is a sentence we have checked rather than a sentence somebody wrote.

> **When a design has a limit, find it on purpose.** A limit you measured is documentation; a limit you have not measured is a bug report waiting to arrive.

## Checking it

Keep the experiment as a habit.
Run it whenever a size, a margin, or a constant changes, and read the failures before fixing them — each one is telling you where a number was written down:

```smalltalk
| source classes report |
source := (CellRenderer class >> #cellExtent) sourceCode.
classes := TestCase allSubclasses select: [ :c |
	           c package name beginsWith: 'Laser' ].
report := WriteStream on: String new.
[
#( '^26@26' '^30@30' '^40@40' '^64@64' '^100@100' ) do: [ :each |
	| result |
	CellRenderer class
		compile: (source copyReplaceAll: '^50@50' with: each)
		classified: 'constants'.
	result := (classes inject: TestSuite new into: [ :suite :c |
		            suite addTests: c buildSuite tests;
		            yourself ]) run.
	report
		nextPutAll: each;
		nextPutAll: ' ';
		nextPutAll: result printString;
		cr ] ] ensure: [
	CellRenderer class compile: source classified: 'constants' ].
report contents
```

Two hundred and seven tests, five cell sizes, all green.
The habit costs you a minute and it is the cheapest test in the book: it checks a claim no single test can reach, by changing the one thing the whole package agrees about.

In the next chapter we let the player take a move back.

# Undo

A button that takes the last move back.
Two rules decide what it means, and we agree on them before writing any code.

There is no limit on how far back it goes: every move of a game can be taken back, one at a time, down to the board the player started with.
And an undo takes nothing off the move counter — taking a move back is itself work, and the statistics are meant to stay honest.

The code that follows is a class per reversible move, a stack on the grid, and a fourth button on the panel.

The second rule is the one people argue about, so notice what it buys you.
A counter that went down would let a player push a mirror back and forth forever and finish with a move count of one.
A counter that only goes up measures the game that was actually played.

## A class for every move that can be taken back

A move is recorded as a symbol: `#north`, `#east`, `#south`, `#west`, `#clockwise`, `#counterClockwise`.
To take one back, the grid has to know which move reverses it.
That is a question with six answers, which by now has a familiar shape — the answers become classes, and the question is asked of the superclass:

```smalltalk
ReverseLaserGameAction class >> reverseActionClassFor: aSymbol
	"Answer the subclass of mine that undoes the move aSymbol stands for. Each of them claims one
	symbol, so a new kind of move means a new subclass and no change here."

	^self subclasses detect: [:cls | cls actionSymbol = aSymbol]
```

```smalltalk
ReverseLaserGameAction class >> reverseActionSymbolFor: aSymbol
	"Answer the selector that undoes the move aSymbol stands for. The grid performs it with the
	location the move was recorded at."

	| cls |
	cls := self reverseActionClassFor: aSymbol.
	^cls reverseActionSymbol
```

We give each subclass two methods: the move it undoes, and the selector that undoes it.

```smalltalk
ReversePushCellEastLaserGameAction class >> actionSymbol
	^#east
```

```smalltalk
ReversePushCellEastLaserGameAction class >> reverseActionSymbol
	^#pushCellWestFromLocation:
```

```smalltalk
ReverseRotateClockwiseLaserGameAction class >> actionSymbol
	^#clockwise
```

```smalltalk
ReverseRotateClockwiseLaserGameAction class >> reverseActionSymbol
	^#rotateCellCounterClockwiseAt:
```

We write the other four subclasses as those same two methods with the other four pairs:

| the move | undone by |
| --- | --- |
| `#north` | `#pushCellSouthFromLocation:` |
| `#east` | `#pushCellWestFromLocation:` |
| `#south` | `#pushCellNorthFromLocation:` |
| `#west` | `#pushCellEastFromLocation:` |
| `#clockwise` | `#rotateCellCounterClockwiseAt:` |
| `#counterClockwise` | `#rotateCellClockwiseAt:` |

That table could have been a `Dictionary` built once somewhere, and it is instructive to see why it is not.
`self subclasses` is answered by the system: nothing registers, nothing is listed, and there is no place where the table could be half updated.

A seventh kind of move means a seventh subclass and no other edit anywhere — and if you forget to give it a `reverseActionSymbol`, the failure is a loud `doesNotUnderstand`, not a missing dictionary key answering `nil`.

`detect:` here has no `ifNone:` block, so a symbol no subclass claims raises an error rather than answering `nil`.

That is the right choice for this method.
The only symbols that ever reach it are the ones the grid itself wrote on the stack, so an unclaimed symbol is a bug in the game, and the sooner it says so the better.

What is new, compared with the direction and click-region hierarchies of the earlier sections, is that these classes answer *selectors*.
`#pushCellWestFromLocation:` is the name of a method, carried around as a value, and the grid will send it by name.
That is worth a paragraph of its own.

## Sending a message by its name

```smalltalk
Grid >> undo
	"Take the youngest move off my stack, play the move that reverses it, and answer true. Answer
	false and do nothing when there is no move left to take back. Playing the reverse goes through
	the methods that record moves, so it records one of its own, and the second #removeLast takes
	that entry off again."

	| actionAssociation symbol location reverseAction arguments |
	self movesStack isEmpty ifTrue: [^false].
	actionAssociation := self movesStack removeLast.
	symbol := actionAssociation key.
	location := actionAssociation value.
	reverseAction := ReverseLaserGameAction reverseActionSymbolFor: symbol.
	arguments := Array with: location.
	self perform: reverseAction withArguments: arguments.
	self movesStack removeLast.
	^true
```

`self perform: reverseAction withArguments: arguments` sends the grid the message whose name is in `reverseAction`, with the arguments in `arguments`.
It is an ordinary message send, decided while the program runs rather than while it is compiled.
Six methods become one line.

Everything you give up by writing it is about tools.
The browser cannot show you that `undo` calls `pushCellWestFromLocation:`, so a rename of that method will not find this call site; the compiler cannot tell you that you spelled it wrong.

Use `perform:` when the set of messages is a set the program itself owns — six symbols, listed in six classes, all written by the same package — and reach for it rarely.
And when you do, let the tests cover what the compiler no longer can, which is exactly what `testUndoActions` below is for.

Two more things about that method.
It answers `true` or `false`, because the caller has a real decision to make: an undo that did nothing must not count a move.
And the second `removeLast` is the line that will surprise you, including the one who wrote it.

Playing the reverse move goes through the grid's ordinary push and rotate methods — the same ones a player's click goes through — and those methods record what they do.
So the undo pushes an entry of its own onto the stack, and the second `removeLast` takes it straight off again.

That is a load-bearing assumption, not an invariant: it is right only as long as every reverse move records exactly one entry.

It does, for all six — a reverse push is a push the rules allow, since it puts the cell back where it just came from, and a rotation always records.
But nothing in the code *says* so, which is the kind of thing to hold with a test rather than with hope.

> **When a method depends on something it cannot check, write the test that checks it.** Comments describe an assumption; a test defends it.

## The stack

We write the stack itself as three short methods:

```smalltalk
Grid >> movesStack
	"Answer the stack of moves made on me, oldest first, built on first use. Each entry is an
	association of the symbol of a move and the location the move has to be undone from."

	movesStack isNil ifTrue: [self movesStack: OrderedCollection new].
	^movesStack
```

```smalltalk
Grid >> movesStack: aCollection
	"Set the stack of moves made on me."

	movesStack := aCollection
```

```smalltalk
Grid >> stackAction: aSymbol forCell: aCell
	"Record that aSymbol was done to aCell, so that the move can be taken back and counted. An
	entry holds the symbol of the move and where the cell is now: a pushed cell has already
	moved, and the push that undoes it starts from where it landed."

	self movesStack add: aSymbol->(aCell gridLocation)
```

The getter builds the collection the first time it is asked for.
That pattern is called lazy initialization, and the thing you should notice is that every reader goes through the getter — `movesStack isEmpty`, `self movesStack add:`, never the bare variable — which is what makes it safe.

A grid that was never played on has an empty stack rather than `nil`, and no caller has to know which.

An entry is an `Association`, written with `->`: a key and a value in one object, here the symbol of the move and a `Point`.
`OrderedCollection` is used as a stack, with `add:` to push and `removeLast` to pop, so the youngest move is the one at the end.

The location stored is where the cell is *after* the move, which is the only one that can be used to undo it: to take an eastward push back you push the cell west from where it now stands.
Reading that comment carefully is faster than working it out from the four push methods, which is what comments are for.

Nothing on this page is new to the game, by the way.
The push and rotate methods have been recording their moves since the section where pushing was written — that is what the `stackAction:forCell:` line in each of them does — and a push the rules refuse records nothing, because it changed nothing.

The undo button is the first thing to read what was being written all along.

## The tests

The first test we write covers what the compiler cannot:

```smalltalk
GridTestCase >> testUndoActions
	"Every action symbol the stack can hold answers the selector that takes it back. The six pairs
	are the four pushes, each answering the push the other way, and the two rotations, each
	answering the other turn."

	| undoAction |
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #north.
	self assert: undoAction equals: #pushCellSouthFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #east.
	self assert: undoAction equals: #pushCellWestFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #south.
	self assert: undoAction equals: #pushCellNorthFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #west.
	self assert: undoAction equals: #pushCellEastFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor:
		              #clockwise.
	self assert: undoAction equals: #rotateCellCounterClockwiseAt:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor:
		              #counterClockwise.
	self assert: undoAction equals: #rotateCellClockwiseAt:
```

Six pairs, written out, no loop.
A loop here would need a table of the six pairs to loop over, and that table is the thing under test — it would be the same list twice, agreeing with itself.
Written out, the expectations are stated by hand and a mistake in the hierarchy cannot hide.

The next one we write is the shape of a single undo:

```smalltalk
GridTestCase >> testUndoStackAfterPush
	"A push puts one entry on the stack, the undo takes it off and answers true, and a
	second undo finds the stack empty and answers false."

	self assert: grid movesStack isEmpty.
	grid pushCellEastFromLocation: 1 @ 2.
	self assert: grid movesStack size equals: 1.
	self assert: grid undo.
	self deny: grid undo
```

Four assertions, and each one is a different claim: an untouched grid has nothing to undo, a push records exactly one entry, an undo reports that it did something, and a second undo reports that it did not.

`self assert: grid undo` works because `undo` answers a boolean — a method with a useful answer is a method that is easy to test.

And then we test the rule, which is stronger than any single example of it:

```smalltalk
GridTestCase >> testUndoingEveryMoveGivesTheGridBackAsItWas
	"Undo takes one move off the stack and plays its reverse. A run of pushes and turns mixed
	together, undone one at a time, has to leave every cell of the grid where it was and facing
	the way it did, and leave the stack empty. Only a move that changed something is stacked, so
	each move is checked to have been recorded before the run is undone."

	| before after reading |
	reading := [ :aGrid |
	            aGrid cells collect: [ :each |
		            | lean |
		            lean := (each isKindOf: MirrorCell)
			                    ifTrue: [ each leansLeft printString ]
			                    ifFalse: [ '' ].
		            each class name , ' ' , each gridLocation printString , ' '
		            , lean ] ].
	before := reading value: grid.
	{
		(#pushCellEastFromLocation: -> (1 @ 2)).
		(#rotateCellClockwiseAt: -> (2 @ 2)).
		(#pushCellSouthFromLocation: -> (4 @ 1)).
		(#rotateCellCounterClockwiseAt: -> (3 @ 3)).
		(#pushCellWestFromLocation: -> (5 @ 3)) } doWithIndex: [ :each :index |
		grid perform: each key with: each value.
		self assert: grid movesStack size equals: index ].
	[ grid undo ] whileTrue.
	self assert: grid movesStack isEmpty.
	after := reading value: grid.
	self assert: after equals: before
```

This is the test that defends the whole design, and three things in it are habits you should copy.

We compare the grid by *reading* it into something comparable.
`Cell` has no `=`, so two grids cannot be compared directly, and writing one would mean deciding what equality of cells means for the rest of the program.

Instead the block collects, for every cell, its class, the location it says it sits at, and which way it leans if it is a mirror — which is the whole of what a move can change.
Comparing those two collections is comparing the boards.

The undoing is `[ grid undo ] whileTrue`, which keeps undoing while the grid reports that it did something.
That is the first rule of the chapter — any number of moves, back to the start — written as a loop, and it is why `undo` answers a boolean rather than nothing.

And the assertion inside the loop that makes the moves is not decoration.
A push is refused unless the cell is a mirror and its neighbour in that direction is blank, and a refused push records nothing.

The first version of this test picked five moves of which the demo board refused two; it undid three moves, got the board back, and passed, while testing a third of what it claimed to.
The assertion `grid movesStack size equals: index` fails immediately when a chosen move did not happen.

> **When a test builds a scenario, assert that the scenario got built.** A test that quietly does less than it says is worse than no test, because it reports green while it does it.

## A tab that reads the undo stack out loud

The stack is an `OrderedCollection` of associations, and that is exactly how an inspector shows it: `an OrderedCollection(#clockwise->(2@3) #east->(2@2))`.
Those are the moves, but they are not the question.
The question a reader has in front of a played board is what the next undo will do, and answering it means finding which of the six `ReverseLaserGameAction` subclasses claims the youngest symbol.

That is a question worth a tab, because it is one the object can answer and we keep answering by hand:

```smalltalk
Grid >> inspectionMoves: aBuilder
	"Show my undo stack, youngest move first: what was played, where the cell it was played on
	stands now, and the selector undo will send to take that move back. Read this tab when undo
	does something unexpected, because the move and its reversal sit side by side here."

	<inspectorPresentationOrder: 4 title: 'Moves'>
	^ aBuilder newTable
		  items: self movesStack reversed;
		  addColumn: (SpStringTableColumn title: 'Move' evaluated: [ :each | each key asString ]);
		  addColumn: (SpStringTableColumn title: 'Cell now at' evaluated: [ :each |
					   each value printString ]);
		  addColumn: (SpStringTableColumn title: 'Undo sends' evaluated: [ :each |
					   (ReverseLaserGameAction reverseActionSymbolFor: each key) asString ]);
		  yourself
```

`reversed` puts the youngest move first, because the youngest move is the one undo will take back.
The third column asks `ReverseLaserGameAction` the same question `undo` asks it, so the table cannot promise one thing and the button do another.

Rotate the mirror at `1@5` clockwise, push the one at `1@2` east, and the tab reads:

```text
east       (2@2)  pushCellWestFromLocation:
clockwise  (2@3)  rotateCellCounterClockwiseAt:
```

The middle column is worth a second look.
A push stores the location of the cell it moved, and that cell has since moved, so the location in the stack is where the cell is *now* — which is exactly what the reverse push needs.
Reading that off a table is a good deal quicker than working it out in your head.

A grid that has not been played has an empty stack, and a tab with nothing in it is noise, so we hide it until there is something to read:

```smalltalk
Grid >> inspectionMovesContext: aContext
	"Hide the Moves tab until something has been played, because an empty stack has nothing to
	say."

	aContext active: self movesStack isNotEmpty
```

A method named `inspectionXxxContext:` is asked about the tab `inspectionXxx:` would build, and `active:` decides whether the tab appears at all.
It needs no pragma of its own; the name is the wiring.

> **A tab with nothing to say should not be on the screen.** Tabs are a reader’s first list of questions, and an empty one wastes a glance.

The tab is tested like any other method, by building it and reading the table it answers:

```smalltalk
GridTestCase >> testTheMovesTabListsWhatUndoWillDo
	"The Moves tab is the undo stack read out loud: one row per move, youngest first, with the
	selector undo will send for it. It is the view that saves reading the seven Reverse classes
	the grid looks up by symbol."

	| builder table undoSends |
	grid rotateCellClockwiseAt: 1 @ 5.
	grid pushCellEastFromLocation: 1 @ 2.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := grid inspectionMoves: builder.
	self assert: table items size equals: 2.
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals: #( 'Move' 'Cell now at' 'Undo sends' ).
	self assert: table items first key equals: #east.
	self assert: table items last key equals: #clockwise.
	undoSends := table columns third.
	self
		assert: (undoSends evaluation value: table items last)
		equals: 'rotateCellCounterClockwiseAt:'
```

The push in that test is east from `1@2`, and not any push we fancied, because `2@2` is the one blank cell next to it.
A push the rules refuse records nothing, and a test built on one would have asserted against an empty stack.

A tab that hides itself until a move has been played is a tab you cannot see on any board we have a name for, so the examples get one more:

```smalltalk
GridExample class >> gridAfterAMoveAndARotation
	"The demo board with the mirror at 1@2 turned clockwise and the one at 3@3 pushed east.
	The Moves tab hides itself until something has been played, so this is the board to click when you want to read it.
	GridExample gridAfterAMoveAndARotation"

	<sampleInstance>
	| grid |
	grid := self demoGrid.
	grid rotateCellClockwiseAt: 1 @ 2.
	grid pushCellEastFromLocation: 3 @ 3.
	^ grid
```

`GridExample demoGrid` opens on a board nobody has touched, where the Moves tab is correctly absent.
This one plays one push and one rotation first, so the tab is there with two rows in it the moment you click the example.
A view and the example that shows it off arrive together, or the view is only ever seen by whoever wrote it.

## The button

The panel builds its buttons the same way it builds the other three:

```smalltalk
LaserGameControlPanelElement >> newUndoButton
	"Answer the button that takes the last move back. Its label never changes, so only the action
	is needed."

	^ self newButton: 'Undo' action: [ self game undo ]
```

```smalltalk
LaserGameControlPanelElement >> undoButton
	"Answer the button that takes the last move back."

	^ undoButton
```

The action is a block, and the block says `self game undo` — the panel does not undo anything itself.
A button's job is to name a message and send it when clicked; the decisions belong to the object that owns them.

Nothing is positioned.
The panel has had two rows of buttons since the panel was written, and a row lays its children out side by side, so Undo is one more element in the row the New button stands in:

```smalltalk
LaserGameControlPanelElement >> newNewGameRow
	"Answer the middle row of buttons, holding New on the left and Undo on its right."

	^ self newRowOfButtons: {
			  newGameButton.
			  undoButton }
```

```smalltalk
LaserGameControlPanelElement >> rebuild
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
```

That is the ninth instance variable of the panel, and the ninth is only available because we stopped keeping two of them in the last chapter.
`ReExcessiveVariablesRule` draws its line at ten, so the room was made just in time — which is the usual way that kind of tidying pays off.

We write two tests to say where the button stands:

```smalltalk
LaserGameControlPanelElementTestCase >> testUndoButtonSharesTheRowWithNewGame
	"Undo sits in row two, column two: beside New, above Quit and Fire."

	| panel |
	panel := self newPanel.
	self assert: panel newGameRow children asArray equals: {
			panel newGameButton.
			panel undoButton }.
	self assert: panel undoButton class equals: ToButton.
	self assert: panel undoButton labelText asString equals: 'Undo'
```

The test that was written when New was alone in its row claimed two things: that the row held New, and that it held nothing else.
The second half is not true any more, so we give it up and keep the half that is the test's own business, sharpened — which rows stand where:

```smalltalk
LaserGameControlPanelElementTestCase >> testNewGameButtonHasTheRowAboveTheOthers
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
```

Its assertions are about *relative* position — the lowest row, and the row directly above it — so a row added above them later leaves this test alone.
The comment names the two tests that own what it gave up, one of which belongs to a chapter still to come; that is cheap to write and it saves the next reader the search.

> **When a test stops being true, work out which half of it stopped.** Delete that half, keep the rest, and say in the comment who owns the part you dropped.

## What the game does with it

```smalltalk
LaserGameElement >> undo
	"Take the last move back, and count the undo as a move of its own: an undo must not remove any
	count from the player's total, so the counter goes up, not down. The grid answers whether it
	undid anything, and on an empty stack there is nothing to draw again."

	self grid undo ifFalse: [ ^ self ].
	self incrementMoves.
	self refresh
```

Three lines, and the first is a guard: ask the model whether anything happened, and leave if it did not.
Without it, a click on Undo with nothing to undo would count a move and redraw a board that had not changed.

```smalltalk
LaserGameElement >> incrementMoves
	"Count one more move."

	self moves: self moves + 1
```

```smalltalk
LaserGameElement >> refresh
	"Show what the model says now: redraw the cells, put the right label on the fire button and
	set the counters."

	self board rebuildCells.
	self controlPanel updateFireButtonLabel.
	self controlPanel updateCounters
```

`refresh` is the one method the whole game uses to catch the display up with the model, and every action ends by calling it.
Having exactly one of those is what keeps a display honest: there is no path through the code that changes the model and forgets to redraw a part of the screen, because nobody redraws parts.

The two tests we write are the two rules of the chapter:

```smalltalk
LaserGameElementTestCase >> testUndoTakesTheLastMoveBackAndCountsAsAMove
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
```

```smalltalk
LaserGameElementTestCase >> testUndoOnABoardNobodyHasTouchedDoesNothing
	"An empty undo stack answers false, and the game does nothing with it: no move is counted and
	the board is left as it stands."

	self deny: game grid undo.
	game undo.
	self assert: game moves equals: 0.
	self assert: game controlPanel movesCounter value equals: 0
```

The first checks the mirror came home, the stack is empty, the counter reads two for one move and one undo, and the display agrees with the counter.
The second is the guard: nothing clicked on an untouched board costs a move.

## Checking it

Open the game, push a few mirrors around, and press Undo until nothing more happens.
You get the board walking back to where it started while the moves counter keeps climbing.
Without a window:

```smalltalk
| game |
game := LaserGameElement on: GridExample demoGrid.
game grid pushCellEastFromLocation: 1 @ 2.
game incrementMoves.
game undo.
{ (game grid at: 1 @ 2) class name.
  game grid movesStack size.
  game moves }
```

You get `#('MirrorCell' 0 2)`: the mirror is back where it was, nothing is left on the stack, and the player is charged for both moves.

In the next chapter we move the tests into a package of their own.

# Tests in their own package

This chapter changes no code.
It changes where the code lives, which matters the first time somebody other than you loads it: a person who wants to play the game should not have to take the tests with it.

Moving the test classes into a package of their own means a baseline that says what loads with what, and it uncovers a bug that the single package had been hiding.

Until now we have kept everything in one package, `Laser-Game`, with the test classes gathered under a tag called `Tests`.
That reads tidily in the browser and does nothing at all for a loader, which is the difference this chapter is about.

## A tag is not a package

Pharo has two levels of grouping, and you can easily confuse them, because the browser shows them side by side.

A **package** is the unit that gets loaded, committed, and versioned.
It is what a baseline names, what Iceberg writes to disk as a directory, and what somebody else asks for by name.

A **tag** groups classes inside one package.
It is a label for reading.
A tag cannot be loaded on its own, cannot be left out of a load, and cannot be named in a baseline.

So `Model`, `Graphics` and `Tests` kept the three concerns apart for the reader and left them welded together for everyone else.
Anybody loading the game got 23 test classes and a dependency on SUnit whether they wanted them or not.

The fix is to make the tests a package.
We do it in the image, one line per class:

```smalltalk
aClass package: (Smalltalk packageOrganizer ensurePackage: 'Laser-Game-Tests')
```

and the `Tests` tag disappears along with its last class.
On disk the Tonel files move from `src/Laser-Game/` to `src/Laser-Game-Tests/`, and that is the whole of the change.

The name is not free choice.
Pharo's convention is the package name with `-Tests` appended, and the tools rely on it: the browser offers to jump between a class and its tests, the test runner finds the suite, and a baseline group called `tests` is what people expect to be able to ask for.

A package called `LaserGameTests` or `Tests-LaserGame` would work and would quietly cost you all of that.

> **Follow a naming convention even when nothing enforces it.** A convention is what the tools guess with.

## The baseline says what loads with what

The baseline is the method that describes the project to a loader: which packages it has, what each one needs, and which sets of them somebody can ask for.
This is where we say the split out loud, or nothing outside the image knows about it:

```smalltalk
BaselineOfLaserGame >> baseline: spec
	<baseline>
	spec for: #common do: [
		spec
			baseline: 'Bloc'
			with: [ spec repository: 'github://pharo-graphics/Bloc:dev/src' ].
		spec
			baseline: 'Toplo'
			with: [ spec repository: 'github://pharo-graphics/Toplo:dev/src' ].
		spec package: 'Laser-Game' with: [ spec requires: #( 'Bloc' 'Toplo' ) ].
		spec
			package: 'Laser-Game-Examples'
			with: [ spec requires: #( 'Laser-Game' ) ].
		spec
			package: 'Laser-Game-Tests'
			with: [ spec requires: #( 'Laser-Game' 'Laser-Game-Examples' ) ].
		spec group: 'core' with: #( 'Laser-Game' ).
		spec group: 'examples' with: #( 'Laser-Game-Examples' ).
		spec group: 'tests' with: #( 'Laser-Game-Tests' ).
		spec group: 'default' with: #( 'core' 'examples' 'tests' ) ]
```

We declare two packages, and the tests require the game while the game requires nothing of the tests.

Then three groups, which are the names a loader can ask for: `core` loads the game alone — the point of the chapter — `tests` loads the tests, and `default` is what a load with no group named takes, which here means both.
Somebody who only wants to play writes `load: 'core'`.

We can check the baseline without a network and without loading anything, by asking Metacello to work out the order it would load in:

```smalltalk
BaselineOfLaserGame project version spec packageSpecsInLoadOrder
"an Array('Bloc' 'Toplo' 'Laser-Game' 'Laser-Game-Tests' 'core' 'tests' 'default')"
```

## The bug that was hiding in it

Look at the first `spec package:` line again.
It requires both Bloc and Toplo, and Toplo had no business being a surprise: the panel's buttons are `ToButton`s, and `ToButton` is a Toplo class.

Only Bloc was declared.
For several chapters the baseline described a project that could not possibly compile — load it into a fresh Pharo and the control panel would be compiled against a class the image did not have — and nothing ever complained, because the image this game was written in had Toplo loaded before the first line of it was typed.

That is the shape of a whole family of bugs, and you want to recognise it early.
The code was right, the tests were green, and the *description* of what the code needs was wrong.

Nothing you can run in your own image will tell you, because your image is exactly the one place where the missing piece is already present.

> **A dependency you did not declare is invisible from inside your own image.** Every time you use a class from a library, check that the baseline names it.

## A critic that went quiet

Every test class we wrote had carried one Renraku critique since the day it was written:

```text
ReTestClassNotInPackageWithTestEndingNameRule
Test class not in a package with name ending with '-Tests'
```

Twenty-three classes, twenty-three critiques, noted as pre-existing and ignored after every chapter.
They are all gone now, because the package the rule wanted is the package we made in this chapter.

You should sit with that for a moment.
The rule was right the whole time, and the reason it gives is the reason this chapter gives: what you ship and what you test it with are two different things.
A linter complaint that will not go away is sometimes a design decision you have not made yet.

> **Before dismissing a critique as noise, read what it is actually claiming.** Some of them are waiting for you to understand them.

## Checking it

We run the suite on the test package now, and it answers what it answered before:

```text
215 run, 215 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

`Laser-Game` holds 42 classes and `Laser-Game-Tests` 23.
Nothing was renamed, nothing was deleted, and no method changed: the game the last chapter left running is the same game.

In the next chapter we give the player a Reset button, and turn up a bug on the way.

# Reset

Reset puts the board back the way it was dealt.
After the last chapter it is almost free: Reset is Undo, repeated until there is nothing left to undo.

The work left is a fifth button, a third row of buttons on a panel that has to grow again, and a test that had been reading the counters before anything happened.

Before that, a test we should have had for several chapters and did not.

## The state before anything happens

Every counter test so far has made a move first.
Push a mirror, then look at the counter; fire the laser, then look at the counter.

None of them ever looked at a game that had just been opened and not touched, and that is a real gap, because a counter that is only written when something happens reads zero until something happens.
A player opening the game would see a board full of mirrors and a Mirrors counter saying none.

That bug cannot occur here, and we should know why.
The counters are written at the end of `rebuild`, the method that builds the panel's children, so a panel that exists has already counted.

That was not foresight: the call went there because `rebuild` runs again whenever the game is refreshed, and a panel rebuilt mid-game would otherwise show the counts of the game before it.
The placement that was chosen for one reason happens to cover the other.

A claim like that still deserves a test rather than an argument, so we write one that makes no move at all:

```smalltalk
LaserGameElementTestCase >> testAGameShowsItsCountsBeforeAnythingHappens
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
```

It passed the first time it ran, which is the answer we wanted.
Note its second half: `newGame` deals a fresh board, and that is the other way a game arrives in front of a player with counts that nothing has yet updated.
One gap found means we look for the others of the same shape.

Note too the assertion `mirrorsCounter value > 0`.
The first assertion compares the counter with the grid, and two zeroes would satisfy it.
That is the lesson of the counter tests two chapters back, and it applies here more sharply than anywhere: this test exists precisely because zero is the wrong answer that looks plausible.

> **Test the state an object is in before anything is done to it.** It is the state every user sees first and the one tests reach last.

## Reset on the grid

```smalltalk
Grid >> reset
	"Take every move back, in the reverse of the order they were made in, so that the board is
	as it was dealt. #undo answers whether it undid anything, so the loop has its work in its
	condition and ends when the stack of moves is empty."

	[self undo] whileTrue: []
```

One line, and every part of it is working.
`undo` answers whether it undid anything, so `[self undo] whileTrue: []` is a loop with its work in the *condition* and nothing in the body: undo, ask whether there was something to undo, go round again while the answer is yes.

On an empty stack `undo` answers `false` without touching anything, and the loop stops.

That shape reads strangely the first time you meet it.
The usual loop puts a question in the condition and work in the body; this one puts a method that both acts and reports in the condition, which is only possible because `undo` was written to answer something useful.

Had it answered nothing, `reset` would need to ask the stack about its size and the two methods would both know how moves are stored.

> **A method that does something and reports whether it did can be driven by a loop.** That is worth remembering when choosing what a method answers.

We test it with two pushes, a reset, and the cell that moved back where it started:

```smalltalk
GridTestCase >> testResetGrid
	"Two pushes, then a reset, and the cells that moved are back where they were with an empty
	stack behind them. Reset is the undo stack unwound to the end, so this is the same rule
	#testUndoingEveryMoveGivesTheGridBackAsItWas states one move at a time."

	| cell |
	cell := grid at: 4 @ 4.
	self assert: cell class equals: BlankCell.
	grid pushCellEastFromLocation: 3 @ 3.
	grid pushCellSouthFromLocation: 4 @ 3.
	cell := grid at: 3 @ 3.
	self assert: cell class equals: BlankCell.
	cell := grid at: 4 @ 3.
	self assert: cell class equals: BlankCell.
	cell := grid at: 4 @ 4.
	self assert: cell class equals: MirrorCell.
	self assert: grid movesStack size equals: 2.
	grid reset.
	cell := grid at: 4 @ 4.
	self assert: cell class equals: BlankCell.
	self assert: grid movesStack isEmpty
```

It checks the board before the moves, after the moves, and after the reset, which is more than it strictly needs and exactly what makes it readable: a failure tells you *which* of the three states was wrong.

The stronger claim — any run of moves, undone, gives the board back — is the test of the last chapter, and this one is the same rule stated at one remove.
Both are worth having.
The general test catches the design, the specific one is what a reader learns from.

## The fifth button

```smalltalk
LaserGameControlPanelElement >> newResetButton
	"Answer the button that puts the board back where it started."

	^ self newButton: 'Reset' action: [ self game reset ]
```

Nothing new.
Then we add its row, at the top of the column of rows:

```smalltalk
LaserGameControlPanelElement >> newResetRow
	"Answer the top row of buttons, holding Reset alone. Its button is built here and not kept in
	an instance variable: a tenth would trip ReExcessiveVariablesRule, whose limit is ten, and
	#resetButton reads it back from the row the way #buttonRow and #newGameRow read the rows from
	the column."

	^ self newRowOfButtons: { self newResetButton }
```

```st
LaserGameControlPanelElement >> newButtonColumn
	"Answer the column of button rows: the bottom left corner of the panel, one gap from both
	edges, the rows one gap apart, the last row against the bottom. The cell spacing of a linear
	layout is added around the cells as well as between them, so it is the whole of the gap: a
	margin here would double the gap on the left and push the last button of the bottom row
	against the board."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class buttonGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignBottom ].
	column addChild: self newResetRow.
	column addChild: self newNewGameRow.
	column addChild: self newButtonRow.
	^ column
```
> **Note.** *Minor cosmetic tweaks* puts a divider bar in front of the three rows, as the first child of this column.

A row added to a column is the whole of the layout work.
The column lays its children out one above another and takes its size from them, so a third row needs no coordinates, no offsets, and no rearranging of the other two.

That is what a layout is for, and it is the reason this chapter's geometry section is three methods long instead of thirty.

Reset is also the first button the panel does not keep in an instance variable.
Two chapters ago we got the panel down to eight by giving up the two it did not need, and `undoButton` made nine; `ReExcessiveVariablesRule` allows ten.
A tenth would be legal and pointless, because the row Reset is the only button of can answer it:

```st
LaserGameControlPanelElement >> resetRow
	"Answer the top row of buttons, holding Reset alone. The column reads from the top, so the top
	row of buttons is its first child."

	^ self buttonColumn children first
```
> **Note.** *Minor cosmetic tweaks* puts the divider bar in front of the rows, so this row becomes the second child.

```smalltalk
LaserGameControlPanelElement >> resetButton
	"Answer the button that puts the board back where it started. It is the only button of its
	row, and the only one I do not hold."

	^ self resetRow children first
```

Two methods instead of one instance variable, and they read from the thing that already holds the answer.
This is the same argument as the counter column two chapters ago: a variable that remembers where something already is, is not state.

## A third row makes the panel taller

The panel has had a height of its own to fall back on since the counters outgrew the demo board.
That arithmetic assumed two rows of buttons, and now there are three, so we make the number of rows something the class says rather than something the sum assumes:

```smalltalk
LaserGameControlPanelElement class >> buttonRowCount
	"Answer how many rows of buttons I stack: two rows of two, and the row Reset has to itself."

	^ 3
```

```st
LaserGameControlPanelElement class >> contentHeight
	"Answer the height, in pixels, of everything I hold: my counters, stacked with a gap between
	them and a gap above and below, and the rows of buttons under them, spaced the same way. A
	counter takes the size of its caption, so one is built and measured; nothing is laid out and
	nothing is opened."

	| counter |
	counter := LaserGameCounterElement labelled: 'Active Mirrors' digits: 3.
	counter measure: BlExtentMeasurementSpec unspecified.
	^ ((self counterCount * counter measuredExtent y)
	   + ((self counterCount + 3) * self counterGap)
	   + (self buttonRowCount * self buttonHeight)
	   + ((self buttonRowCount + 1) * self buttonGap)) ceiling
```
> **Note.** *Minor cosmetic tweaks* adds the divider bar to this sum.

The two literals that were there — `2 * self buttonHeight` and `3 * self buttonGap` — have become `buttonRowCount` and `buttonRowCount + 1`, and that second one is worth your attention.

A column of *n* rows with a gap around and between them has *n + 1* gaps, which is a relation and not a number.

Write it as a relation and the method stays right at four rows; write it as `4` and the next row is a bug that nothing announces, because an answer 30 pixels too small still looks like a plausible height.

> **Replace a literal with the expression that produced it.** The literal is right once; the expression is right every time.

The third row adds a button's height and a gap, 30 pixels, to the number — enough that the panel is taller than the demo board, so the panel decides the height of the window:

```smalltalk
LaserGameControlPanelElement class >> heightForGrid: aGrid
	"Answer how tall I am beside a board showing aGrid: as tall as that board, or as tall as what I
	hold when the board is shorter than that. Without the second half, a board small enough would
	have my counters and my buttons overlap."

	^ (LaserGameBoardElement extentForGrid: aGrid) y max: self contentHeight
```

Nothing else had to change.
The height rule was written against `contentHeight` rather than against the number `contentHeight` answered, so a taller panel is a taller window and a taller board is still a taller window, with no edit anywhere.

The test that holds the arithmetic honest did not change either, which is the whole point of having written it against the columns:

```smalltalk
LaserGameControlPanelElementTestCase >> testContentHeightIsWhatTheCountersAndButtonsMeasure
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
```

A test written against a measurement rather than against a number survives the change that made the number different.
That is the second time in three chapters that this one method has paid for itself.

## A test that had to be narrowed again

Adding the row broke a test for the second chapter running.
`testNewGameButtonHasTheRowAboveTheOthers` was written when New was alone in the top row of two, and said so.
The last chapter put Undo beside New, and the test gave up the half about being alone.
Now the row is not the top one either:

```smalltalk
LaserGameControlPanelElementTestCase >> testNewGameButtonHasTheRowAboveTheOthers
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
```

It reads the rows by index now: the button row is the last of them, and the New row is the one directly before it.
Both claims are about *relative* position, so anything stacked above leaves this test alone — and something is stacked above it four chapters from now.

A test rewritten twice for the same reason is a signal, and the signal is not "tests are fragile".
It is that the first two versions asserted more than they were about.

The question to ask of an assertion is what the test is *for*: this one is for where New stands relative to Quit and Fire, and every sentence of it should be about that.

> **When a test breaks because the world grew around it, narrow it to its own claim.** Then it breaks only when its claim is wrong.

We give the new row the test that owns the rest:

```st
LaserGameControlPanelElementTestCase >> testResetButtonHasTheTopRowToItself
	"Reset sits in row three, column one, which is the row above New and Undo and the topmost of
	the three. Its button is the one thing the panel does not hold in an instance variable, so it
	is read from its row."

	| panel |
	panel := self newPanel.
	self assert: panel buttonColumn children asArray equals: {
			panel resetRow.
			panel newGameRow.
			panel buttonRow }.
	self assert: panel resetRow children asArray equals: { panel resetButton }.
	self assert: panel resetButton class equals: ToButton.
	self assert: panel resetButton labelText asString equals: 'Reset'
```
> **Note.** *Minor cosmetic tweaks* adds the divider bar to the column this test reads back.

Somebody has to assert how many rows there are and in what order, and this is now the test that does.
Giving up a claim in one test means we find it a home in another; dropped claims are how a suite goes quietly green.

## What the game does with it

```smalltalk
LaserGameElement >> reset
	"Put the board back where the game started: unwind the whole undo stack, stop the laser and
	set the move count to zero."

	self grid reset.
	self grid stopLaser.
	self moves: 0.
	self refresh
```

We should read it beside `newGame`, the other button that starts something over:

```smalltalk
LaserGameElement >> newGame
	"Start again on a fresh random grid. The stack of moves the grid keeps is left alone: it is
	emptied where Undo and Reset are added."

	self grid initializeCells.
	self grid stopLaser.
	self moves: 0.
	GridFactory randomizeGrid: self grid.
	self refresh
```

Both stop the laser, both zero the move count, both refresh.
They differ in one thing: New deals a fresh random board and leaves the stack of moves where it finds it, while Reset unwinds the stack and so keeps the board it was dealt.

A player who wants this board again presses Reset; a player who wants another one presses New.

Notice that the move count goes to zero in both, while an undo pushes it up.
That is not an inconsistency.
Undo is a move in a game being played, and Reset ends that game — there is nothing left to be honest about.

In the test we make two moves of different kinds, fire the laser, and ask for all of it back:

```smalltalk
LaserGameElementTestCase >> testResetPutsEveryCellBackAndZeroesTheMoves
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
```

The last two assertions read the panel, not the game: `refresh` has to have carried the zeroes out to the counters.
A counter the model has moved past is exactly the bug this chapter opened with, so it is a fitting thing to assert in the chapter that went looking for it.

## Checking it

Five buttons in three rows.
Push some mirrors, fire the laser, press Reset: you get the board back, the beam stops, and the counter reads zero.
Without a window:

```smalltalk
| game |
game := LaserGameElement on: GridExample demoGrid.
game grid pushCellEastFromLocation: 1 @ 2.
game incrementMoves.
game reset.
{ game moves.
  game grid movesStack size.
  LaserGameControlPanelElement buttonRowCount.
  (LaserGameControlPanelElement heightForGrid: game grid)
    > (LaserGameBoardElement extentForGrid: game grid) y }
```

You get nothing moved, no moves counted, three rows of buttons, and a panel that is now the taller of the two things in the window.

In the next chapter we give the laser's home cell something to show for itself.

# Showing where the laser comes from

A small chapter.
The beam has been drawn for several chapters now, and it appears at the bottom of the first column as though out of nowhere.

We add a mark saying the laser lives there: the grid answers its starting cell, the board goes into a column of its own so there is a margin to draw in, and the mark costs the game no size.

It is small and it is not trivial, because the mark has to go in a band of the window that no element occupies, and a layout places the children it is given.
Getting something into empty space is a layout problem, and a good one for you to meet on something this harmless.

## Where the laser comes from

The grid has answered this since the first section, and until now nothing drew it:

```smalltalk
Grid >> startingCell
	"Answer the cell the laser enters me at: column one of my last row. The beam enters it from
	the south, so it arrives through the bottom edge of my bottom left corner."

	| pt |
	pt := 1@(self numberOfRows).
	^self at: pt
```

Column one, last row, entered from the south — `calculatePath` starts the beam with `#south` as the side it comes in by.
So the beam arrives through the bottom edge of the bottom left cell, and the mark goes directly under that edge, in the margin between the last row of cells and the bottom of the window.

## A column for the board

Here is the problem.
A game is a horizontal row of two children, the panel and the board, with the margin around them as padding.
Padding is not a place to put things: a linear layout lays out every child it is given, and a third child would be laid out *beside* the other two, not underneath one of them.

The move is to stop thinking about where to put the mark and change what stands where the board stands.
We give the board a column of its own, with the mark as its second child:

```smalltalk
LaserGameElement >> newBoardColumn
	"Answer the column standing where the board stands: the board itself, and under its first
	column of cells the bar marking where the laser enters. The bar is the last child, so it
	falls under the bottom row, and it is as tall as my bottom margin, which is why I have no
	bottom padding: the column ends where I end and the bar fills the band under the board."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: BlLinearLayout vertical.
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ].
	column addChild: board.
	column addChild: laserHome.
	^ column
```

`fitContent` on both axes means the column is exactly as big as what it holds, so it is the board's size plus the height of the mark.
A child that is laid out below another child needs no coordinates: it is the second child of a vertical column, and that is the whole of the positioning.

> **To place something a layout has no room for, change the thing that holds it.** Wrapping a child in a container of its own is cheaper than stepping outside the layout.

Then we take the bottom margin out of the padding, so the column ends where the game ends and the mark fills the band:

```smalltalk
LaserGameElement >> initialize
	"A game is a row of two: the control panel, and the board beside it. The margin around both is
	padding, and the ramp behind them shows through it. There is none at the bottom: the mark of
	the laser's home stands in that band, so the bottom margin belongs to the panel and to the
	board column, and they carry it as a margin instead. No move has been made yet."

	super initialize.
	self background: self class windowBackgroundPaint.
	self layout: BlLinearLayout horizontal.
	self padding: (BlInsets
			 top: self class gameMargin
			 left: self class gameMargin
			 bottom: 0
			 right: self class gameMargin).
	moves := 0
```

The margin has not disappeared.
It has moved from the game to the two things standing in it: the board column carries it as the mark, and the panel carries it as a margin of its own.

```smalltalk
LaserGameElement >> rebuild
	"Replace what I hold with a control panel for me and a board showing my grid beside it, and
	take the size the two of them and my margins need. The panel is added first, so it stands to
	the left of the board. The board tells me when a move changed the grid, so the counters follow
	a click as well as the fire button. The board goes in inside a column that also holds the mark
	of the laser's home, and the panel carries the bottom margin that mark stands in."

	self removeChildren.
	confirmation := nil.
	board := LaserGameBoardElement on: self grid.
	laserHome := self newLaserHome.
	controlPanel := self newControlPanel.
	controlPanel margin: (BlInsets bottom: self class gameMargin).
	self addChild: controlPanel.
	self addChild: self newBoardColumn.
	board whenMoveMadeDo: [ self moveMade ].
	self extent: (self class extentForGrid: self grid)
```

Padding and margin are easy to mix up, and this method has one of each.
**Padding** is space a parent keeps inside itself, around all of its children at once.
**Margin** is space a child asks for around itself.

The game had padding on four sides; now it has padding on three, and the fourth side's worth of space is asked for by each child separately — the panel with `margin:`, the board column with a mark that happens to be exactly that tall.

And the size of the window did not change at all.
`extentForGrid:` was not touched: the game is one margin, then the taller of (panel plus its margin) and (board plus its mark), and both of those grew by the same ten pixels that the padding lost.

## The mark

```smalltalk
LaserGameElement >> newLaserHome
	"Answer the bar that marks where the laser comes from: one cell wide, one margin tall, in the
	colour the beam splatters the board with. An element with a background is the whole of it, and
	it scales with the rest of the game."

	^ BlElement new
		  background: LaserGameColors laserBeamSplatterColor;
		  extent: self class laserHomeExtent;
		  yourself
```

```smalltalk
LaserGameElement class >> laserHomeExtent
	"Answer the size, in pixels, of the bar marking where the laser enters the board: one cell
	wide and one margin tall."

	^ CellRenderer cellExtent x @ self gameMargin
```

A `BlElement` with a background and an extent.
No drawing, no image, no subclass: a coloured rectangle is an element whose background is that colour, and it scales with the cell size like everything else because its size is stated in terms of `cellExtent`.

```smalltalk
LaserGameElement >> laserHome
	"Answer the bar that marks where the laser enters the board."

	^ laserHome
```

That is the sixth instance variable of the game, four below the limit the panel ran into two chapters ago.
It is held rather than read back from the column because the game builds it, and `rebuild` builds the column from it.

## The tests

The first test we write says what the mark is and where it stands in the tree:

```smalltalk
LaserGameElementTestCase >> testGameShowsWhereTheLaserComesFrom
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
```

`constraints horizontal resizer size` is where `extent:` ends up.
Asking an element for its `extent` before it has been laid out answers the size it currently has, which is nothing; asking its constraints answers the size it was *told* to have, which is what this test is about.

That is the same reading used for the game's own size several chapters ago, and it is the reason these tests need no window.

The second test is the one that matters, because the whole chapter is an arrangement whose job is to leave the size alone:

```smalltalk
LaserGameElementTestCase >> testTheLaserHomeSitsInTheMarginAndCostsNoSize
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
```

Four assertions, and together they are an argument rather than a list.
The column is the board plus one margin; the game's padding is open at the bottom; the panel asks for that margin itself; and therefore the height the game claims is one margin plus the taller of the two things inside it.

If any one of those four changes, the mark either overlaps the cells or makes the window taller, and the test says which of the four went wrong.

Writing the last assertion as the *same addition the method does* would be a mistake — it would pass whatever the method answered.
It is written from the measurement instead: `column measuredExtent y` is what Bloc says the column is, not what the arithmetic predicted.

> **An assertion that re-states the code it is checking checks nothing.** Get one side of it from somewhere else: a measurement, a constant, a count.

## Three tests that learned about one more level

The board is still reached through `board`, but it is no longer the game's second child — the column is.
Three existing tests had to say the same thing about a tree one element deeper:

```smalltalk
LaserGameElementTestCase >> testGameHoldsABoardAndAControlPanel
	"A game is a row of two children: the control panel first, the board beside it. The board is
	wrapped in a column, which holds the mark of the laser's home under it, and the board itself
	is reached through its own accessor."

	self assert: game children size equals: 2.
	self assert: game children first equals: game controlPanel.
	self assert: game children second equals: game board parent.
	self assert: game board class equals: LaserGameBoardElement.
	self assert: game layout class equals: BlLinearLayout
```

`game children second equals: game board parent` is the honest way to write it.
The test is about the game holding two children, one of which is where the board is; it is not about how many containers deep the board sits, and writing `children second children first` would make it about that.

`testAnsweringNoLeavesTheGameAsItWas` changed in the same way, and the padding assertion of the extent test moved to the three sides that still have padding:

```smalltalk
LaserGameElementTestCase >> testGameTakesTheExtentItCalculates
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
```

Three existing tests editing their expectations is a cost, and you should be honest about which kind of cost it is.
None of them was wrong about the game; all three were specific about a tree that changed shape.

Tests that read a tree pay a little whenever the tree moves, and the way to keep the bill small is the one used here: name what you are reaching for — `game board`, `game controlPanel` — rather than counting your way to it.

## Checking it

Open the game and look under the bottom left cell: you get a short bar in the colour of the beam's splatter, filling the margin, exactly one cell wide.
Fire the laser and it lines up with where the beam comes in.

Without a window:

```smalltalk
| game |
game := LaserGameElement on: GridExample demoGrid.
{ game board parent children size.
  game board parent children last = game laserHome.
  LaserGameElement laserHomeExtent.
  game padding bottom }
```

You get two children in the board column, the mark being the lower of them, a bar one cell wide and one margin tall, and no padding at the bottom for it to sit outside of.

In the next chapter we turn the cell-size experiment of *A missed bug* into something the suite runs by itself.

# A less brittle test design

In *A missed bug* we ran an experiment by hand: recompile `cellExtent`, run everything, read the failures, put the method back.
It found three brittle tests and a design floor, which was worth the trouble.

In this chapter we turn the experiment into a harness any test case can inherit, and then rewrites the push, rotate and boundary tests as tables that have to hold at every cell size.

An experiment you run by hand is one you run when you remember to.
This chapter turns it into something the suite does by itself, and then uses it on the part of the game that has the most numbers in it: the click tables.

No code outside the test package changes anywhere in this chapter.

## The harness

The playground version we ran was six lines, of which four were bookkeeping: keep the old source, compile the new one, run the block, put the old one back whatever happens.
That belongs in a method:

```smalltalk
LaserGameTestCase class >> withCellExtent: anExtent do: aBlock
	"Run aBlock with the cell size of the whole package set to anExtent, and put the old size
	back afterwards. The method is on the class side as well as on the instance side, because a
	test case that has no reason to inherit from me still has reason to ask the question: the
	cell element tests check where a hint arrow lands at more than one cell size."

	| previous |
	previous := CellRenderer class >> #cellExtent.
	[
	CellRenderer class
		compile: 'cellExtent' , String cr , String tab , '^ ' , anExtent printString
		classified: 'constants'.
	aBlock value ] ensure: [
		CellRenderer class compile: previous sourceCode classified: 'constants' ]
```

`previous` holds the `CompiledMethod`, not its text, and the `ensure:` block recompiles it from `previous sourceCode`.
Keeping the method object is the easy way for you to get the source back exactly as it was, comment and all.

The `ensure:` is the whole point of writing this as a method.
A failed assertion inside the block raises an exception, and without `ensure:` that exception would leave the image with whatever cell size the test was using — every later test in the run would be testing a game nobody plays, and the failures would be nonsense.

`ensure:` runs its block on the way out whether the way out is a return or an exception.

> **Anything that changes shared state for the duration of a block puts it back in an `ensure:`.** Tests fail; that is their job.
> They must not leave wreckage when they do.

```smalltalk
LaserGameTestCase >> withCellExtent: anExtent do: aBlock
	"Run aBlock with the cell size of the whole package set to anExtent, and put the old size
	back afterwards. Raising the cell size and asking the geometry whether it followed is the
	experiment this makes cheap. The click tables ask the same question, so the answer lives on
	my class side and this method passes it on."

	^ self class withCellExtent: anExtent do: aBlock
```

We put the work on the class side and the instance side passes it on, so a test writes `self withCellExtent: ...
do: [ ...
]` and a test case that does not inherit from `LaserGameTestCase` can still write `LaserGameTestCase withCellExtent: ...
do: [ ...
]`.
One implementation, reachable from both.

## An abstract test case

Four test classes now need that method, so we put it in a superclass of the four:

```text
LaserGameTestCase                    (abstract)
    CellRendererTestCase
    CellClickRegionTestCase
    CellClickInsideRegionPushTestCase
    CellClickOutsideRegionRotateTestCase
```

```smalltalk
LaserGameTestCase class >> isAbstract
	"Answer whether I am abstract. I hold what my subclasses share and no test of my own."

	^ self = LaserGameTestCase
```

`isAbstract` is how a test case tells the runner it has no tests of its own.
Written as `^ self = LaserGameTestCase` rather than `^ true`, so that the subclasses — which inherit the method — answer `false` without having to override it.
A plain `^ true` would make the whole hierarchy abstract and nothing would run.

We put nothing else in this class.
A test that never asks about a cell size has no reason to inherit from it, and a superclass that collects everything shared by anything is how test suites become impossible to read.

There is one consequence we should name, because it shows up in the numbers.
Pharo builds the suite of a test case out of its own test methods *and* those of its subclasses, so running the whole package runs these four classes twice: once from their own suites and once through their superclass.

The count of tests reported is larger than the count of test methods.
They are the same tests and they pass either way.

## The push table

Here is the table we write for what a click inside a mirror asks for.
Read the points:

```smalltalk
CellClickInsideRegionPushTestCase >> assertPushRegionTable
	"Check the table: a point of the inside region, and the push a click there asks for. Every
	point is written relative to the rectangle the region answers, so the table holds at any cell
	size."

	| pt regionClass pushRegion testTable cls rect |
	rect := CellClickRegionInside regionRectangle.
	pt := rect topLeft + (1 @ 1).
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionInside.
	testTable := {
		             (rect topLeft -> CellClickRegionPushEast).
		             (rect topRight -> CellClickRegionPushWest).
		             (rect center -> CellClickRegionPushNorth).
		             (rect bottomLeft -> CellClickRegionPushNorth).
		             (rect bottomRight -> CellClickRegionPushNorth).
		             (rect topLeft + (1 @ 3) -> CellClickRegionPushEast).
		             (rect center + (-1 @ 1) -> CellClickRegionPushNorth).
		             (rect bottomRight + (-1 @ -3)
		              -> CellClickRegionPushWest).
		             (rect topCenter + (0 @ 1) -> CellClickRegionPushSouth) }.
	testTable do: [ :assoc |
		pt := assoc key.
		cls := assoc value.
		pushRegion := regionClass pushRegionForPoint: pt.
		self assert: pushRegion equals: cls ]
```

Not one pixel number names a position.
`rect topLeft`, `rect center`, `rect bottomRight`: every row names a *landmark* of the rectangle the region answers, and the only literals are small nudges away from a landmark — `+ (1 @ 3)` is "just inside this corner", which is a statement about the corner and not about the cell.

Written the other way, with the nine points as the pixel pairs they come out to, the table would tell you two things at once: that a point in this part of the cell asks for an eastward push, which is what the test is for, and that the inside region's corner is at a particular pixel, which the test never meant to claim.

The second claim is already made, correctly, by the method that answers `regionRectangle` — and a test that repeats a fact it is not testing fails for reasons that have nothing to do with it.

> **In a test, write every position relative to the thing that defines it.** Then the test fails only when the thing it is about is wrong.

Notice also that we wrote the table as a `do:` over an array of associations, with the assertion written once.
Nine rows in nine lines, with the checking in one place.
Adding a tenth row means adding a row.

We write two tests against the table.
The first runs it at the size the game is actually played at:

```smalltalk
CellClickInsideRegionPushTestCase >> testClicksInPushRegions
	"Run the table at the cell size of the package. The table lives in a method of its own, so the
	test that runs it at three other sizes can share it."

	self assertPushRegionTable
```

and the second is why we wrote this chapter:

```smalltalk
CellClickInsideRegionPushTestCase >> testThePushRegionTableHoldsAtEveryCellSize
	"Run the same table at three cell sizes. Every row names a point of the rectangle a region
	answers, so no row goes stale when the cell grows. A table of pixel numbers would."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [ self assertPushRegionTable ] ]
```

Thirty, forty, and eighty, and we did not choose them arbitrarily.
Thirty is near the floor *A missed bug* measured, where the inside region is only ten pixels square — small enough that a row nudged `+ (1 @ 3)` from a corner has to land in the right triangle by geometry rather than by luck.

Eighty is a size nobody has opened the game at.
If the table holds at both ends it holds in between.

The two tests also show what a shared helper is for.
The helper holds the claim; the tests say under what conditions the claim must hold.
Put the table in the test method and you have to copy it to run it at a second size, and from then on there are two tables that must agree.

> **When the same assertions must run under different conditions, name the assertions once.** The tests become one line each, and the conditions are what you read.

## The rotate table

We write the same shape, with fifteen rows and two rectangles, because the rotate regions are the ring between the inside region and the outside one:

```smalltalk
CellClickOutsideRegionRotateTestCase >> assertRotateRegionTable
	"Check the table: a point of the outside region, and the rotation a click there asks for. The
	rows name the corners, the edge centres and a few points near them of both the inside and the
	outside rectangle, so the table says the same thing at any cell size."

	| pt regionClass testTable cls rotateRegion inRect outRect |
	inRect := CellClickRegionInside regionRectangle.
	outRect := CellClickRegionOutside regionRectangle.
	pt := outRect topLeft + (1 @ 1).
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionOutside.
	testTable := {
		             (inRect topLeft -> CellClickRegionRotateClockwise).
		             (inRect topRight -> CellClickRegionRotateClockwise).
		             (inRect leftCenter -> CellClickRegionRotateClockwise).
		             (inRect rightCenter -> CellClickRegionRotateClockwise).
		             (inRect bottomLeft
		              -> CellClickRegionRotateCounterClockwise).
		             (inRect bottomRight
		              -> CellClickRegionRotateCounterClockwise).
		             (outRect topLeft -> CellClickRegionRotateClockwise).
		             (outRect topRight -> CellClickRegionRotateClockwise).
		             (outRect leftCenter -> CellClickRegionRotateClockwise).
		             (outRect rightCenter -> CellClickRegionRotateClockwise).
		             (outRect bottomCenter
		              -> CellClickRegionRotateCounterClockwise).
		             (outRect bottomRight
		              -> CellClickRegionRotateCounterClockwise).
		             (outRect topLeft x + 2 @ inRect topLeft y
		              -> CellClickRegionRotateClockwise).
		             (inRect rightCenter + (2 @ -2)
		              -> CellClickRegionRotateClockwise).
		             (inRect bottomLeft + (2 @ 2)
		              -> CellClickRegionRotateCounterClockwise) }.
	testTable do: [ :assoc |
		pt := assoc key.
		cls := assoc value.
		rotateRegion := regionClass rotateRegionForPoint: pt.
		self assert: rotateRegion equals: cls ]
```

We should stop at one row:

```text
(outRect topLeft x + 2 @ inRect topLeft y -> CellClickRegionRotateClockwise)
```

Its x comes from the outer rectangle and its y from the inner one.
That is a point in the left arm of the ring, level with the top of the inside region, and there is no landmark for it because it is not a landmark of either rectangle — it is the intersection of two of them.

Writing it as a pixel pair would be shorter and would tell you nothing.
Written this way the row explains itself, which is what you want from the one row in fifteen that needs explaining.

```smalltalk
CellClickOutsideRegionRotateTestCase >> testClicksInRotateRegions
	"Run the table at the cell size of the package."

	self assertRotateRegionTable
```

```smalltalk
CellClickOutsideRegionRotateTestCase >> testTheRotateRegionTableHoldsAtEveryCellSize
	"Run the rotate table at three cell sizes. The line that divides the outside region sits at
	half the height of the cell, and every row names a corner or an edge centre of a rectangle a
	region answers, so no row goes stale when the cell grows."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [ self assertRotateRegionTable ] ]
```

## The boundaries

Three more tests we write say where one region stops and the next begins.
They are blunter than the tables and they are the ones most tempted by pixel numbers, because a boundary *is* a number:

```smalltalk
CellClickRegionTestCase >> assertIgnoreRegionBoundaries
	"Check where the ignore region begins and ends. It is the margin of the cell left over once
	the outside region is inset, so the corner of the cell belongs to it and the centre of the
	inside region does not. Both points are written relative to a rectangle a region answers, so
	neither goes stale when the cell size changes."

	| ignoreRect outsideRect |
	ignoreRect := CellClickRegionIgnore regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	self
		assert: (CellClickRegion clickRegionForPoint: ignoreRect topLeft)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: ignoreRect bottomRight - (1 @ 1))
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: outsideRect topLeft - (1 @ 1))
		equals: CellClickRegionIgnore.
	self
		deny: (CellClickRegion clickRegionForPoint: CellClickRegionInside regionRectangle center)
		equals: CellClickRegionIgnore
```

`outsideRect topLeft - (1 @ 1)` is the interesting one: the pixel diagonally outside the corner of the outside region, which must belong to the ignore margin.

That is a statement about a boundary written entirely in terms of the rectangle that defines it, and it is right at any cell size and any margin width.
The same point as a pixel pair would be right until somebody changed either.

The last line uses `deny:equals:`, which asserts that two things *differ*.
The centre of the inside region must not be ignored — a boundary test needs a point on each side of the boundary, or it only proves the region is not empty.

```smalltalk
CellClickRegionTestCase >> testClicksInIgnoreRegion
	"Check the boundaries of the ignore region at the cell size of the package."

	self assertIgnoreRegionBoundaries
```

We give the inside and outside regions the same pair — a helper and a one-line test — and one test runs all three helpers at all three sizes:

```smalltalk
CellClickRegionTestCase >> testTheRegionBoundariesHoldAtEveryCellSize
	"Run the three boundary tables at three cell sizes. The three regions are concentric squares
	derived from the cell size, one of them by a margin that stays four pixels wide and one by a
	ring that stays ten pixels wide, so the smallest size of the sweep is the one that could break
	them. None of the three loses a pixel to another."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [
			self assertIgnoreRegionBoundaries.
			self assertInsideRegionBoundaries.
			self assertOutsideRegionBoundaries ] ]
```

The smallest size is the one that can break: the ignore margin is four pixels at every cell size and the outside ring is ten, so a thirty pixel cell is a ten pixel inside region, inside a twenty-two pixel outside region, inside a thirty pixel cell.
Three squares with nothing to spare, and no pixel changes hands.

## And the renderer

We had already written the test that sweeps the renderer's geometry.
It now reads the harness from its superclass instead of holding its own copy, and it is the widest claim in the suite:

```smalltalk
CellRendererTestCase >> testEverySizeInACellFollowsTheCellSize
	"Every size in a cell is derived from the cell size, and this is what that claim means. At
	any cell size the two nested regions stay centred in the cell, every point of the cell
	falls in a region, the four push regions divide the inside square between them without
	overlapping, the ring of a target still fits in the cell, and a board is still the grid
	times the cell."

	#( 30 40 80 ) do: [ :side |
		self withCellExtent: side @ side do: [
			| cell inside outside middle renderer |
			cell := 0 @ 0 extent: side @ side.
			inside := CellClickRegionInside regionRectangle.
			outside := CellClickRegionOutside regionRectangle.
			self assert: inside extent equals: CellRenderer insideRegionExtent.
			self assert: outside extent equals: CellRenderer outsideRegionExtent.
			self assert: inside center equals: cell center.
			self assert: outside center equals: cell center.

			middle := side // 2.
			self assert: (CellClickRegionRotateClockwise containsPoint: 0 @ middle).
			self deny: (CellClickRegionRotateClockwise containsPoint: 0 @ (middle + 1)).
			self assert:
				(CellClickRegionRotateCounterClockwise containsPoint: 0 @ (middle + 1)).

			0 to: side - 1 do: [ :x |
				0 to: side - 1 do: [ :y |
					self assert: (CellClickRegion clickRegionForPoint: x @ y) notNil ] ].
			inside left to: inside right do: [ :x |
				inside top to: inside bottom do: [ :y |
					self
						assert: (CellClickRegionInside subclasses count: [ :each |
								 each containsPoint: x @ y ])
						equals: 1 ] ].

			renderer := CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid.
			self assert: renderer radius > 0.
			self assert: renderer innerRadius > 0.
			self assert: renderer radius * 2 <= side.

			self
				assert: (LaserGameBoardElement extentForGrid: grid)
				equals: side * grid numberOfColumns @ (side * grid numberOfRows) ] ]
```

Three of its claims are the kind that no example can make.
Every point of the cell falls in some region — that is a loop over every pixel of the cell, and at eighty pixels it is six thousand four hundred assertions.

Every point of the inside region falls in exactly *one* push region, counted by asking how many of the four subclasses contain it: not none, which would leave a dead patch, and not two, which would make a click ambiguous.
And the two nested regions stay centred.

A loop over every pixel is a crude test and a good one.
The clever version would reason about the diagonals; this one checks them all, runs in milliseconds, and cannot be wrong about a corner case because it has no notion of a corner case.

> **When the input space is small, test all of it.** Exhaustiveness is worth more than cleverness when you can afford it.

## Checking it

Nothing a player can see changed in this chapter.
What changed is that the claim "every size follows the cell size" is now checked by the suite at three sizes instead of being argued for in comments:

```smalltalk
| game |
game := LaserGameElement on: GridExample demoGrid.
LaserGameTestCase withCellExtent: 30 @ 30 do: [
	CellClickRegionInside regionRectangle extent ]
```

You get `10@10`, the inside region of a thirty pixel cell, and the method is back to fifty pixels the moment the block ends.
The suite is green, and green now means something it did not mean two chapters ago.

In the next chapter we go back to the hint arrows and put them where they belong.

# Centring the hint arrows

A hint arrow has to sit in the middle of the cell it belongs to.
That sounds like a sentence nobody needs to write a chapter about, and it is the kind of thing that goes wrong quietly: an arrow a few pixels off centre looks like a mistake in the drawing rather than a mistake in the arithmetic, and you cannot tell which from looking.

So this chapter states the rule as two tests, one on the shape and one on the cell, and gives the renderer an arrow extent and an offset that hold at every cell size.

So we do two things in this chapter.
We say where the arrow goes, in two constants, and we write the tests that measure where the arrow actually landed — at three cell sizes, using the harness of the last chapter.

## Why there is nothing to trim

The natural way to make six arrows is to draw each one into a picture and keep the picture.
It is also where the trouble starts: a picture has to be big enough to hold the shape, the shape ends up somewhere inside it, and the space around it is now part of the arrow as far as any later arithmetic is concerned.

Centring the picture does not centre the arrow, and finding out how far off it is means searching the pixels for the edge of the ink.

So we do not draw an arrow into a picture here.
It is a polygon, and its vertices are scaled onto the rectangle the caller asks for:

```smalltalk
LaserGameShapes class >> pointsOf: anArrayOfPoints scaledToExtent: anExtent
	"Answer anArrayOfPoints moved to the origin and stretched to fill anExtent exactly. The vertex
	arrays are written at the size the arrows were drawn at, around 260 pixels, and every user asks
	for the size it needs. A polygon geometry does not follow the extent of its element, so this is
	the step that makes one vertex array serve a 12 pixel hint and a 200 pixel drawing."

	| bounds scale |
	bounds := Rectangle encompassing: anArrayOfPoints.
	scale := anExtent x / bounds width @ (anExtent y / bounds height).
	^ anArrayOfPoints collect: [ :each |
		  ((each - bounds origin) * scale) asFloatPoint ]
```

`Rectangle encompassing:` is the tight rectangle around the vertices — four points for you to look at, not a hundred thousand pixels to search.
Subtracting `bounds origin` moves the shape to `0@0`, and the scale factor stretches it to exactly the extent asked for.

Every arrow reaches its element through that method:

```smalltalk
LaserGameShapes class >> eastArrowElementOfExtent: anExtent
	"Answer an arrow of anExtent that points east."

	^ self arrowElementFromPoints: self eastArrowPoints ofExtent: anExtent
```

So the ink of an arrow *is* the rectangle it was asked for, at every size, and there is nothing left over.
That is a claim, and we give a claim a test:

```smalltalk
LaserGameShapesTestCase >> testEveryArrowFillsTheRectangleItIsGiven
	"An arrow is a polygon whose points are scaled onto the rectangle asked for, so the ink is the
	rectangle and there is no margin anywhere around it to trim. Six arrows are asked at three
	sizes and every one of them is checked."

	#( 24 30 48 ) do: [ :size |
		#( #northArrowElementOfExtent: #southArrowElementOfExtent:
		   #eastArrowElementOfExtent: #westArrowElementOfExtent:
		   #clockwiseArrowElementOfExtent:
		   #counterClockwiseArrowElementOfExtent: ) do: [ :selector |
			| element |
			element := LaserGameShapes perform: selector with: size @ size.
			self
				assert: (Rectangle encompassing: element geometry vertices)
				equals: (0 @ 0 corner: size @ size) ] ]
```

Eighteen checks from eight lines, and the two loops are the two things you could get wrong: an arrow that does not fill its rectangle, and a size at which one of them does not.

The arrows are named in an array of selectors and sent with `perform:with:`, which is the right use of that message — six methods with one shape, listed in the test that covers all six, so a seventh arrow is one more line.

> **Prefer a shape you can scale to a picture you have to measure.** The arithmetic that follows is then about the shape and not about its packaging.

## Where the arrow goes

We write two constants, and both are statements rather than requests:

```smalltalk
CellRenderer class >> hintArrowExtent
	"Answer the size a hint arrow is drawn at: a couple of pixels smaller than a cell, so that
	the arrow keeps clear of the cell border."

	^ self cellExtent - 2
```

```smalltalk
CellRenderer class >> hintArrowOffset
	"Answer where a hint arrow sits within its cell: centred, which is half of what the cell has
	over the arrow."

	^ (self cellExtent - self hintArrowExtent) // 2
```

Read the second one as the definition of centred: take what the cell has over the arrow, and give half of it to each side.
Written that way it is right for any cell size and any arrow size, and it stays right if either changes.

Written as `^ 1 @ 1` it would be right today and silently wrong the first time `hintArrowExtent` changed — and one pixel off centre is exactly the error nobody notices.

The cell puts them together:

```smalltalk
LaserGameCellElement >> updateHintElement
	"Show the picture of the hint I hold, and no other, in the colour of what a click there would
	do. The arrow is a child of mine, so the previous one goes when it is removed and no arrow is
	ever left behind. The colour comes from my renderer: green when the move is allowed, red when
	it is refused. A region without a picture, such as the ignore margin, answers nothing and
	leaves me with no hint at all. The cross hair is shown exactly when the arrow is, and is
	dropped here so that it is added after the arrow and stays the child on top of it."

	hintElement ifNotNil: [ :each | self removeChild: each ].
	hintElement := hintRegion ifNotNil: [ :region |
		               region hintElementOfExtent: CellRenderer hintArrowExtent ].
	hintElement ifNotNil: [ :each |
		each
			background: (self renderer hintColorAt: hintPosition);
			position: CellRenderer hintArrowOffset.
		self addChild: each ].
	crossHairElement ifNotNil: [ :each |
		self removeChild: each.
		crossHairElement := nil ].
	self updateCrossHairElement
```

Three `ifNotNil:` in one method looks like a lot, and each one is a different question: is there an old arrow to take away, does this region offer a picture at all, and did we get one.

The middle one answers `nil` for the ignore margin, which has no hint, and the method flows through to leaving the cell with no arrow — no special case, no `ifTrue:` about which region we are in.

The arrow is a *child* of the cell, which is what makes the cleanup trivial.
Remove the child and the old arrow is gone; there is no painting over and no record of what was drawn where.
State that lives in the element tree is state you can delete.

And the colour comes from the renderer, so the arrow says whether the move it offers is legal:

```smalltalk
MirrorCellRenderer >> hintColorAt: aPoint
	"Answer the colour of the hint arrow at aPoint, in the coordinates of my cell. The arrow says
	whether the move it offers could actually be made. The region the point falls in knows — the
	outside region always allows a turn, and the inside region asks the push region whether the
	cell beside mine would let my cell through."

	^ ((CellClickRegion clickRegionForPoint: aPoint)
		   canActOnCellAtPoint: aPoint
		   cell: self cell
		   withinGrid: self grid)
		  ifTrue: [ LaserGameColors allowActionArrowColor ]
		  ifFalse: [ LaserGameColors denyActionArrowColor ]
```

## Two tests, at two levels

The first test we write checks the arithmetic, at three cell sizes, with the harness from the last chapter:

```smalltalk
CellRendererTestCase >> testTheHintArrowIsCentredInItsCellAtEveryCellSize
	"A hint arrow is a polygon scaled onto the rectangle it is given, so its ink is its extent and
	centring it is arithmetic on two constants. Both halves are checked here, at three cell sizes:
	the offset leaves the same margin on every side of the cell, and every arrow fills the
	rectangle it is asked for."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [
			| offset |
			offset := CellRenderer hintArrowOffset.
			self
				assert: (offset * 2) + CellRenderer hintArrowExtent
				equals: CellRenderer cellExtent.
			self assert: offset x equals: offset y.
			#( #northArrowElementOfExtent: #southArrowElementOfExtent:
			   #eastArrowElementOfExtent: #westArrowElementOfExtent:
			   #clockwiseArrowElementOfExtent:
			   #counterClockwiseArrowElementOfExtent: ) do: [ :selector |
				| element |
				element := LaserGameShapes
					           perform: selector
					           with: CellRenderer hintArrowExtent.
				self
					assert: (Rectangle encompassing: element geometry vertices)
					equals: (0 @ 0 corner: CellRenderer hintArrowExtent) ] ] ]
```

`(offset * 2) + hintArrowExtent equals: cellExtent` is the definition of centred stated backwards, which is why we assert it.
The method computes the offset from the two extents; the test puts the offset back together with the arrow and asks whether it fills the cell.
Neither side is a copy of the other.

The second test we write is the one that would catch a real mistake, because it measures the arrow where it actually sits:

```smalltalk
LaserGameCellElementTestCase >> testTheHintArrowSitsCentredInTheCellAtEveryCellSize
	"An arrow is a polygon scaled onto the rectangle it is given, and it has to end up centred in
	the cell whatever the cell measures. A mirror cell is hovered at three cell sizes, and the
	arrow it shows is measured where it really sits: the space it leaves on the left is the space
	it leaves on the right, and the space above is the space below."

	#( 30 40 80 ) do: [ :size |
		LaserGameTestCase withCellExtent: size @ size do: [
			| element arrow position margin |
			element := (LaserGameBoardElement on: GridExample demoGrid)
				           cellElementAt: 4 @ 1.
			element dispatchEvent: (BlMouseMoveEvent new
					 position: CellClickRegionInside regionRectangle center;
					 yourself).
			arrow := element hintElement.
			self deny: arrow isNil.
			position := arrow constraints position.
			margin := CellRenderer cellExtent
			          - CellRenderer hintArrowExtent - position.
			self assert: margin equals: position.
			self assert: position x equals: position y ] ]
```

This one goes through the whole chain: we hover a mirror with a real mouse event, find the arrow the cell added, and measure the space left on each side of it.

`margin` is what remains of the cell once the arrow and its offset are taken off, so `margin equals: position` says the space after is the space before.
Centred, measured on the thing the player sees.

`self deny: arrow isNil` is not padding.
Without it, a cell that showed no arrow at all would leave `position` as nil, the subtraction would fail with a `doesNotUnderstand`, and the test would report an error in the arithmetic rather than the actual fault, which is that there is no arrow.

Assert that the thing exists before measuring it, and the failure tells you which of the two went wrong.

> **Check the arithmetic and then check the result.** A test on the constants proves the formula; a test on the element proves the formula is the one being used.

Note the one asymmetry in these two tests: the renderer test writes `self withCellExtent:`, inherited from `LaserGameTestCase`, and the cell element test writes `LaserGameTestCase withCellExtent:`.

`LaserGameCellElementTestCase` has no reason to inherit from the cell-size test case — it has one test out of many that asks about sizes — so it asks the class directly.
That is what the class-side copy of the harness is for: needing one method is not a reason to move a class under a superclass.

## Checking it

Open the game and move the pointer slowly across a mirror.
You get a new arrow as the pointer crosses from one region into the next, and it stays in the middle of the cell the whole time — one pixel of clearance on every side, whatever the cell size.

Without a window:

```smalltalk
LaserGameTestCase withCellExtent: 80 @ 80 do: [
	{ CellRenderer hintArrowExtent.
	  CellRenderer hintArrowOffset } ]
```

You get `{78@78.
1@1}`: an arrow one pixel in from each side of an eighty pixel cell, which is the same one pixel it is in from a fifty pixel cell, because it is the arrow that grew and not the margin.

In the next chapter we make a handful of small visual repairs, the kind that only become visible once everything else is right.

# Minor cosmetic tweaks

Everything works.
In this chapter we change three things that only make a difference to the look of the game: a shadow under the board, a bar across the control panel above the buttons, and a board worth playing on when nobody said which board to play.

Small changes, each with a test, and the last of them changes what `LaserGameElement new` opens on.

They are small, and that is the point.
Each one is a change to a finished program, and each one has to be made without breaking the arithmetic the rest of the game is built on.
The tests are what say whether that happened.

## A shadow under the board

The board is a flat rectangle of cells.
A shadow under it, down and to the right, is enough to make you read it as a thing lying on the window rather than a pattern painted on it.

```smalltalk
LaserGameColors class >> boardShadowColor
	"Answer the colour of the shadow the board casts: a dark grey."

	^ Color r: 0.25 g: 0.25 b: 0.254
```

```smalltalk
LaserGameBoardElement class >> shadowOffset
	"Answer how far the board casts its shadow, in pixels: three down and three to the right."

	^ 3 @ 3
```

We write both as named numbers on the class side, like every other number in this game.
The shadow is then one more line in the board's `initialize`:

```smalltalk
LaserGameBoardElement >> initialize
	"A board lays its cells out in a grid, one column per grid column, and takes exactly the
	size of the cells it holds. It casts a shadow down and to the right, which is an element
	effect: Alexandrie draws it under the board, and it costs no layout space."

	super initialize.
	self background: LaserGameColors gameBoardBackgroundColor.
	self effect: (BlSimpleShadowEffect
			 color: LaserGameColors boardShadowColor
			 offset: self class shadowOffset).
	self layout: BlGridLayout horizontal.
	self constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ]
```

An *effect* in Bloc is something drawn around or behind an element without being part of it.
It is not a child, it is not a border, and it is not a bigger background: it has no extent of its own, so the layout never sees it.

Alexandrie, the drawing back end, paints the shadow under the board and then paints the board on top.

That is the whole reason the shadow is an effect here.
The board's size is the sum of its cells, and the game's geometry is written from that sum: the window's extent, the position of the control panel and the place the laser's home mark goes all count on it.

A shadow drawn as a child element, or as three pixels of extra padding, would have added three pixels to the board and moved every one of those.
An effect adds nothing.

So the test we write for the shadow asserts two things, and the second is the interesting one:

```smalltalk
LaserGameBoardElementTestCase >> testTheBoardCastsADropShadow
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
```

The first three assertions say the shadow is there and is the one we asked for.
The last says the board still measures what it measured before the shadow existed.
`measure:` is how an element is asked for its size without being laid out or opened: give it a measurement specification, here an unspecified one, and read `measuredExtent` back.

> **When a change is meant to be invisible to everything else, assert the invisibility.** Half of this test is about what the shadow looks like; the other half is about what it must not have touched.

## A bar across the panel

The control panel holds its counters at the top and its three rows of buttons at the bottom.
We put a thin bar between the two groups to separate them.

```smalltalk
LaserGameColors class >> panelDividerDarkColor
	"Answer the darker end of the bar drawn across the control panel above the buttons. The bar is
	a gradient between two near whites."

	^ Color r: 0.847 g: 0.847 b: 0.85
```

```smalltalk
LaserGameColors class >> panelDividerLightColor
	"Answer the lighter end of the bar drawn across the control panel above the buttons."

	^ Color r: 0.972 g: 0.972 b: 0.976
```

```smalltalk
LaserGameControlPanelElement class >> dividerHeight
	"Answer the height, in pixels, of the bar drawn across me above the buttons."

	^ 5
```

Two near whites, five pixels apart, darker at the top.
A bar that shallow with a gradient that slight reads as a groove pressed into the panel, which is what it is for.

We write the bar itself as an element with no children, a fixed height, and a fixed width:

```smalltalk
LaserGameControlPanelElement >> newPanelDivider
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
```

A `BlLinearGradientPaint` is a background that changes colour across the element.
`vertical` says which way, and `stops:` is a collection of associations from a position between zero and one to the colour at that position: `0` is the top, `1` is the bottom.
Two stops make the simplest gradient there is.

The width is `panelWidth - (2 * buttonGap)`: the panel's whole width, less one gap at each end, so the bar lines up with the buttons underneath it rather than running edge to edge.
Written that way it is still right if either number changes.

### Where the bar goes

Now the question we came for.
The bar belongs above the buttons.
Where is that?

The tempting answer is for you to measure it: the panel is so many pixels tall, three rows of buttons take so many from the bottom, so the bar goes at that many pixels up from the bottom edge.
That is a number found by eye, and it is a number that stops being right the moment a fourth row of buttons appears — the rows would move up through the bar.

The arrangement the panel already has gives a better answer.
The buttons are rows in a vertical column element, and a vertical layout draws its children in order from the top.
So we make the bar the column's first child:

```smalltalk
LaserGameControlPanelElement >> newButtonColumn
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
```

One added line, and no number anywhere.
The bar is above the buttons because it is in front of them in a column that reads downwards, and it stays above them however many rows are added later.

> **Position a thing against the things it belongs with, not against an edge it happens to be near.** An offset from an edge has to be found again every time anything between them changes.

### What the extra child cost

Two costs, and the suite found both.

The first is height.
The panel states its own height, because the board beside it can be shorter than the panel's contents — that was the bug in *Adding more game stats*, where a counter was drawn over a button.
A new child in the column means a new term in that sum:

```smalltalk
LaserGameControlPanelElement class >> contentHeight
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
```

Two changes: the bar's own five pixels, and one more gap.
The gap term was `buttonRowCount + 1`, which is the number of gaps around and between three rows; with the bar in the column there are four children, so there are five gaps, and `buttonRowCount + 2` says that.

Both terms are relations rather than measurements, so neither has to be touched when a row is added.

The panel's content height goes from 320 to 335, and the window of a game on the demo board from 380 by 340 to 380 by 355.
The eight by ten board is taller than the panel either way, so a standard game stays 530 by 520.

> **Note.** *Buttons of one width*, the last chapter, widens the buttons and the panel with them, so those two windows end the book twenty pixels wider: 400 by 355 and 550 by 520.
> The heights are this chapter's.

The second cost is the row accessors.
The panel does not keep its rows of buttons in instance variables; it reads them back out of the column by position, which keeps the column as the one place that knows the order.
A new first child shifts all three:

```smalltalk
LaserGameControlPanelElement >> panelDivider
	"Answer the bar drawn across me above the buttons. It is the first child of the button column,
	which reads from the top."

	^ self buttonColumn children first
```

```smalltalk
LaserGameControlPanelElement >> resetRow
	"Answer the top row of buttons, holding Reset alone. The column reads from the top and starts
	with the divider bar, so the top row of buttons is its second child."

	^ self buttonColumn children second
```

```smalltalk
LaserGameControlPanelElement >> newGameRow
	"Answer the middle row of buttons, holding New and Undo. The column reads from the top and
	starts with the divider bar, so the middle row is its third child."

	^ self buttonColumn children third
```

This is the price of reading children by position, and we should be honest about it: adding a child renumbered three methods.
The alternative — three instance variables — has a worse price, because then the column and the variables can disagree, and nothing would say which of them is wrong.

What makes the position version safe is that you cannot miss the renumbering.
`resetRow` answering the divider is not a subtle wrong answer; it is an element with no buttons in it, and every test that goes through that row fails at once.
A design where a mistake is loud is better than a design where a mistake is unlikely.

## The tests for the bar

We give the bar a test of its own, which says what it looks like and, first of all, where it is:

```smalltalk
LaserGameControlPanelElementTestCase >> testThePanelShowsADividerAboveItsButtons
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
```

The claim being tested is *first child of the button column*, not *five pixels from some edge*, and that is the claim the code makes.
The size assertions read the constraints back rather than the element's extent, because a constraint is what was asked for and an extent is what a layout produced; this test is about the asking.

And the test we wrote to read the whole column back gains the bar, as its note in *Reset* said it would:

```smalltalk
LaserGameControlPanelElementTestCase >> testResetButtonHasTheTopRowToItself
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
```

One test, in the whole suite, says how many children the column has and in what order.
That is the test that had to change, and it is the only one.
Everything else about the buttons goes through `resetRow`, `newGameRow` and `buttonRow`, which now answer the same rows they answered before.

> **Let one test own the shape of a structure, and let every other test ask that structure by name.** Then a change to the shape breaks one test, which is a change, instead of twenty, which is a day.

## A board worth playing on

Last of the three, and the only one that is not about looks.

A game is built on a grid: `LaserGameElement on: aGrid`.
But `LaserGameElement new` is also legal — it is legal for every object in the image — and until now it answered a game whose grid was nil and whose board was empty.
Anybody who met the class for the first time and sent it `new` would see nothing.

The board a new game should be dealt on already has a name, from the very first section: `GridFactory defaultGrid`, eight columns by ten rows, randomized.

The only question we have left is where the fallback goes.
Not in `initialize`, which would deal a board for every game, including the ones that are handed a grid a moment later and would throw the dealt one away.
It goes in the accessor:

```smalltalk
LaserGameElement >> grid
	"Answer the grid the game plays on. A game built with no grid at all plays the standard board
	of eight columns by ten rows, so that `LaserGameElement new` answers something worth looking
	at. The board is dealt when it is first asked for, so a game that is given a grid never deals
	one it would throw away."

	^ grid ifNil: [
		  self grid: GridFactory defaultGrid.
		  grid ]
```

This is *lazy initialization*, and the game has used it before — the counters in *Adding more game stats* were built the same way.
`ifNil:` takes a block that is evaluated only when the receiver is nil, and the block's value is the value of the whole expression.

Note that it stores the grid through `grid:` rather than assigning the variable directly: `grid:` is the setter that rebuilds the board for the new grid, so the lazy default goes through exactly the path a grid given from outside goes through.

```smalltalk
LaserGameElementTestCase >> testAGameMadeWithNoGridPlaysTheStandardBoard
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
```

Five assertions, and you should read them one at a time.
The first two say the default board is the eight by ten one.

The third says the board element is showing that same grid and not some other one, which is the part that would break if the lazy default assigned the variable instead of going through the setter.

The fourth says the window took the extent that grid calls for, so the game is not merely holding a board but is sized for it.
And the fifth says the default stayed a default: a game given the demo grid still plays the demo grid.

> **A test for a fallback has to check the case where the fallback must not fire.** Without the last assertion, a `grid` method that ignored its argument entirely would pass.

## Checking it

Open the standard board, which is what a player would see:

```smalltalk
LaserGameElement openStandardExample
```

You get eight columns by ten rows, a shadow under the board, and a groove across the panel above Reset.
Then the same thing from the other end, with no grid named at all:

```smalltalk
| game |
game := LaserGameElement new.
{ game grid numberOfColumns @ game grid numberOfRows.
  LaserGameControlPanelElement contentHeight }
```

You get `{8@10.
335}`: the standard board, and a panel fifteen pixels taller than it was before the bar.

The suite we have is still green, at 231 runs:

```text
231 run, 231 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

In the next chapter we go back to the counters and make them agree about how wide they are.

# Counters of one width

The game is finished and it works.
Then somebody looks at it properly, and says: the four counter boxes are not the same width, their right edges are ragged, and the words inside them sit against the left border.

In this chapter we find out what the panel had actually been measuring, states one counter width in one place, and centres the caption instead of leaving it against the left edge.

That is a bug report, and it is the kind this chapter is about.
Nothing is broken, no test is red, and nothing in the code is obviously wrong.
We have to find out which decision produced the picture, and then change the decision rather than the picture.

## What the panel actually measured

Start by measuring, not by guessing.
A counter is a frame around a column of two children, a display of digits and a caption, and it was never told how wide to be, so it takes the width of what it holds.
Ask each of the four to measure itself and you can see the cause in the numbers:

```text
Laser Path      counter 53   display 34   caption 43
Moves           counter 44   display 34   caption 26
Mirrors         counter 44   display 34   caption 27
Active Mirrors  counter 64   display 34   caption 54
```

The display is three digits in every counter, thirty four pixels, always the same.
The captions are four strings of four different lengths, and the widest of them decides the box.
Four boxes, three widths, all starting at the same left edge because they are children of one column, and none of them ending at the same right edge.

The second half of the report follows from the same cause.
A vertical linear layout places its children across its cross axis — here the horizontal one — wherever their own constraints say, and the default is the start of that axis, which is the left.

So the display and the caption both stand against the left border, and the slack is all on the right, and the slack is a different size in every box.

> **Measure before you change anything.** "The boxes are ragged" is a symptom; "a box takes the width of its own caption" is a cause, and only the second one tells you which method to open.

## One width, stated once

Who should decide how wide a counter is?
Not the counter: it has no idea how many others there are or what they are standing in.

The panel holds all four, so the panel states the width, and it states it from what it knows — its own width, less the gap the column of counters stands in on each side:

```smalltalk
LaserGameControlPanelElement class >> counterWidth
	"Answer the width, in pixels, of every counter: my own width, less the gap the column of
	counters stands in on each side. A counter left to take the size of its caption would leave
	the four of them four different widths; one width for all four lines their edges up under
	each other and fills the panel."

	^ LaserGameElement panelWidth - (2 * self counterGap)
```

An expression, not a number.
The four boxes fill the panel between its gaps, and they go on doing that if either the panel width or the gap is ever changed.

The width has to reach all four counters, and until now each one was built by its own call to `LaserGameCounterElement labelled:digits:`.
So we put one builder in front of those four calls:

```smalltalk
LaserGameControlPanelElement >> newCounterLabelled: aString digits: anInteger
	"Answer a counter of anInteger digits captioned aString, as wide as every other counter I
	hold. A counter takes the size of its caption when it is not told otherwise, which would leave
	my four counters four different widths; stating the width here is what lines their edges up,
	and the counter centres its display and its caption in whatever width it is given."

	| counter |
	counter := LaserGameCounterElement labelled: aString digits: anInteger.
	counter constraintsDo: [ :aConstraints |
		aConstraints horizontal exact: self class counterWidth ].
	^ counter
```

`horizontal exact:` is the constraint that says *be this wide*, as against `fitContent`, which says *be as wide as your children*.
A counter with an exact width stops asking its caption how wide it is.

We cut the four builders to one line each:

```smalltalk
LaserGameControlPanelElement >> newActiveMirrorsCounter
	"Answer the counter showing how many mirrors the beam lights: three digits, captioned 'Active
	Mirrors'. That caption is the longest of the four, but every counter is the width of the panel
	less its gaps, so the longest caption decides nothing."

	^ self newCounterLabelled: 'Active Mirrors' digits: 3
```

```smalltalk
LaserGameControlPanelElement >> newLaserPathCounter
	"Answer the counter showing how long the laser beam is: three digits. Three digits hold every
	path a board of this size can produce."

	^ self newCounterLabelled: 'Laser Path' digits: 3
```

`newMovesCounter` and `newMirrorsCounter` are the same line with their own captions.

> **When several objects have to agree about a number, the thing that holds them states it.** A rule that lives in one method cannot be half-applied.

## Centred, not left

A box wider than its caption is only an improvement if the caption moves to the middle of it.
Otherwise the raggedness simply moves inside the boxes.

A linear layout reads each child's own constraints to place it across the layout's cross axis, so the display and the caption each have to ask for the centre.
The counter does the asking where it builds them, which is also where either of them can be replaced later:

```smalltalk
LaserGameCounterElement >> digits: anInteger
	"Show anInteger digits. The display is narrower than I am, since my width is stated for all
	four counters of the panel and their captions, so it is centred rather than left against my
	border."

	led ifNotNil: [ :each | self removeChild: each ].
	led := LaserGameLedElement digits: anInteger.
	led constraintsDo: [ :aConstraints |
		aConstraints linear horizontal alignCenter ].
	self addChild: led
```

```smalltalk
LaserGameCounterElement >> labelText: aString
	"Caption me aString. The caption is added last, so it is drawn under the display, and it is
	centred like the display: every caption is a different length and my width is the same for
	all four counters of the panel."

	label ifNotNil: [ :each | self removeChild: each ].
	label := BlTextElement new text: (aString asRopedText
			         fontSize: self class labelFontSize;
			         foreground: LaserGameColors counterLabelColor;
			         yourself).
	label constraintsDo: [ :aConstraints |
		aConstraints linear horizontal alignCenter ].
	self addChild: label
```

Note `aConstraints linear horizontal alignCenter`, with `linear` in it.
A Bloc element's constraints have one part for its own size, which is the `horizontal exact:` of the last section, and one part per kind of layout it might find itself in.

`linear` is the part a `BlLinearLayout` reads; `frame`, which the panel uses elsewhere, is the part a frame layout reads.
An alignment is advice to whatever is laying the element out, so it has to be filed under the layout that will read it.

Both methods also begin by removing the child they are about to replace.
That line is not decoration: `digits:` and `labelText:` are setters that can be sent again at any time, and an element whose old display is still a child would draw two.

Nothing else about a counter changes.
It is still a transparent rounded frame with a two pixel border and a five pixel inset, it still fits its content vertically, and it still takes the width of its caption when nobody states one — which is what `LaserGameCounterElement labelled:digits:` answers on its own, and what `contentHeight` relies on when it builds one counter to ask how tall a counter is.

Laid out in the finished panel, the four boxes now read:

```text
Laser Path      (0.0@4.0) corner: (102.0@52.0)      display and caption centred on 51.0
Moves           (0.0@56.0) corner: (102.0@104.0)    display and caption centred on 51.0
Mirrors         (0.0@108.0) corner: (102.0@156.0)   display and caption centred on 51.0
Active Mirrors  (0.0@160.0) corner: (102.0@208.0)   display and caption centred on 51.0
```

You get one width, one left edge, one right edge, everything centred on the middle.
No size of the game changed: a counter's height is what it always was, and the panel's height counts heights.

> **Note.** *Buttons of one width*, the next chapter, widens the panel from a hundred and ten pixels to a hundred and thirty, so a counter ends the book a hundred and twenty two wide.
> It is the same expression answering a bigger number, which is the whole point of writing it as one.

## The tests

We write two tests, one on each side of the decision.
The panel's says that the four boxes are one width, and says where that width comes from:

```smalltalk
LaserGameControlPanelElementTestCase >> testEveryCounterIsAsWideAsThePanelLessAGapOnEachSide
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
```

The first assertion is the report, turned round.
We collect the width of every counter into a `Set`, which keeps one copy of each distinct value, and assert that the set has one element.

It does not matter which width they share; what the eye saw was that they did not share one.
A set of measured values with `size equals: 1` is the short way to write *all of these agree*.

The second assertion we write says they agree on the stated width, and the third says the stated width is the panel less its two gaps.
Three assertions, three separate claims, and a failure in any one of them points at a different method.

The test we write for the counter says that what a box holds is centred in it:

```smalltalk
LaserGameCounterElementTestCase >> testACounterCentresWhatItHolds
	"Every counter of the panel is given the same width, wider than any of the four captions, so
	what a counter holds has to be centred in it: left against the border, the display of one
	counter and the display of the next would line up but the captions would not, and every box
	would have a ragged margin on its right. Both children are aligned to the centre of the
	column, which is what a linear layout reads to place them across itself. Where they land is
	Bloc's arithmetic and is not repeated here: nothing is laid out, and no element is opened."

	| counter |
	counter := LaserGameCounterElement labelled: 'Moves' digits: 3.
	self assert: counter layout class equals: BlLinearLayout.
	self
		assert: counter led constraints linear horizontal alignment
		equals: BlElementAlignment horizontal center.
	self
		assert: counter label constraints linear horizontal alignment
		equals: BlElementAlignment horizontal center
```

This one asserts the constraint rather than the position, and that is a compromise you should understand, because the honest assertion would be the position: *the display's centre falls on the middle of the box*.

Getting a position out of an element means running a layout, and a layout runs when an element is in a space that draws it.
There is a method that forces one without a space, and the critics rule `ReBlocDoNotSendForceLayoutRule` reports every send of it, for the good reason that a forced layout is a layout run at a moment Bloc did not choose.

This package keeps the critics clean on what it writes, so the layout was run by hand in a playground instead, and the positions printed above are from that run.

What is left in the test is the part this package actually decided: both children ask for the centre, and the layout that will read that request is a linear one.
Bloc's arithmetic is Bloc's to test.

> **When the assertion you want costs more than it is worth, assert the decision you made.** Say in the comment what you checked by hand.
> A test that states a smaller claim honestly is better than one that states a big claim by cheating.

## Checking it

We ask the panel what its counters measure:

```smalltalk
| panel |
panel := (LaserGameElement on: GridExample demoGrid) controlPanel.
panel counterColumn measure: BlExtentMeasurementSpec unspecified.
(panel counterColumn children collect: [ :each | each measuredExtent ]) asArray
```

You get four extents, all the same width, that width being `LaserGameControlPanelElement counterWidth`.
Then open the game and look: you get four boxes in a column, left edges and right edges lined up, every word in the middle of its box.

In the next chapter we take the same report's second half, which is about the buttons.

# Buttons of one width

The same look at the finished game that found the ragged counters found something about the buttons: the words *Reset* and *Undo* run into the right edge of the buttons they are painted in.
A label should stand in the middle of its button, and it should fit inside it with room to spare.

This chapter measures the widest label the game has, derives one button width from it, and lets the panel take its own width from the buttons rather than the other way round.

Three complaints were made, and we start by finding out how many faults there are.

## What a button actually measured

The third complaint — that the buttons are not all the same width — turned out to be wrong.
Every button is built by one method, and that method gives every one of them the same extent, so they were already identical.
A report is evidence, not a diagnosis.

The other two are one fault, and it is in the label rather than the button.
A `ToButton` keeps its label in a container, and lays that container out with a linear layout.

A linear layout puts its children at the start of its axis unless it is told otherwise, and the start of the horizontal axis is the left.
So every label stood against the left border of its button with all of the slack on the right.

We measure the six labels the panel can show, against the forty pixels a button was then:

```text
Quit    25      Fire    22      Stop    28
New     26      Undo    33      Reset   33
```

Six labels for five buttons: the fire button shows *Fire* or *Stop* depending on what a click will do, so both of its labels have to fit.

Thirty three pixels of word in a forty pixel button, hard against the left border, leaves you seven pixels of nothing on the right and a word ending a hair before the edge it is painted against.

That is what the eye saw.
And it is fragile in a way that has nothing to do with alignment: a theme whose button font is a little wider would paint those two labels straight over the border.

> **A bug report describes a picture.** Count the faults behind it before fixing any of them: here three complaints were one fault, one non-fault, and one thing nobody had noticed.

## Centred, not left

The fix is one line, and we had to look for a while to find which line.
A `ToButton` has three things that sound as though they would centre a label, and two of them do nothing:

```text
button alignCenter                                   label container still at x 0
button label constraintsDo: [ :c | ... ]             label container still at x 0
button labelContainer constraintsDo: [ :c | ... ]    label container still at x 0
button layout alignCenter                            label container at 3.5 .. 36.5
```

The reason the first three do nothing is the rule from the counters chapter, seen from the other side: a child's alignment constraints are *read by the layout of whatever holds it*.

The label and its container already ask to be centred.
What holds the container is the button's own layout, and that layout had no alignment of its own, so nothing read the request.
Telling that layout to centre is what moves the label:

```smalltalk
LaserGameControlPanelElement >> newButton: aLabel action: aBlock
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
```

> **When a setting has no effect, the question is not whether it is spelled right but who was supposed to read it.** In a layout, a child states a wish and its parent's layout grants it.

## A width stated from its labels

Centring a label does not make it fit.
Forty pixels holds thirty three with three and a half on each side, and half the report was that a word is too close to its border, so the button has to grow.
The question is to what, and the answer should not be a number that happens to look right.

We say it in three methods instead.
First, what the labels are:

```smalltalk
LaserGameControlPanelElement class >> buttonLabels
	"Answer every label a button of mine can show: the five buttons, and the second label the
	fire button takes while the laser is firing. They are what my button width has to hold."

	^ #( 'Quit' 'Fire' 'Stop' 'New' 'Undo' 'Reset' )
```

Then we say how much room they are to have around them:

```smalltalk
LaserGameControlPanelElement class >> buttonLabelMargin
	"Answer the space, in pixels, my button width keeps on each side of its longest label. It is
	what makes the width a statement about the labels rather than a number that happens to fit."

	^ 6
```

And then we say the width itself:

```smalltalk
LaserGameControlPanelElement class >> buttonWidth
	"Answer the width, in pixels, of a control panel button. Fifty holds every label of
	#buttonLabels with #buttonLabelMargin to spare on each side, which
	#testEveryButtonLabelFitsInsideTheButton is what checks. The panel width follows from this
	number, so widening a button widens the panel and not the space the buttons stand in."

	^ 50
```

Fifty is still a literal.
What has changed is that it is now a literal with a stated meaning — the longest label plus two margins — and with a test that checks the meaning.
Thirty three and twelve make forty five, so fifty passes with five pixels to spare.

### Why not measure it

We could have computed the width: ask every label of `buttonLabels` how wide it is, take the widest, add two margins.
The measuring method exists anyway, because the test needs it:

```smalltalk
LaserGameControlPanelElement class >> widthOfButtonLabel: aString
	"Answer the width, in pixels, a button captioned aString needs for its label: a button is
	built and measured, and nothing is laid out and nothing is opened. Toplo measures the label
	with the font its theme gives a button, which is the only thing that knows how wide the text
	is going to be."

	| button |
	button := ToButton labelText: aString.
	button measure: BlExtentMeasurementSpec unspecified.
	^ button measuredExtent x
```

Only a button can answer this.
The width of a piece of text depends on the font, the font depends on the theme, and the theme is the button's business, so the honest way for you to measure a label is to build a button, measure it and throw it away.

That is also the reason not to do it inside `buttonWidth`.
Building and measuring six buttons costs about a millisecond and a half, and `panelWidth` — which is about to be stated from `buttonWidth` — has a dozen senders, several of them in the arithmetic that sizes a window.
A number read that often should not build anything.

> **A constant with a test that checks what it claims is as good as a computed value and cheaper.** The measurement belongs in the test, which runs when you change the code, rather than in the method, which runs whenever anything asks.

## The panel follows the buttons

One more thing has to move, and it is the interesting half of the chapter.

The panel was a hundred and ten pixels wide and a button was forty.
Those two numbers were never independent: two buttons and the three gaps a row of two stands in come to exactly a hundred and ten.

That identity is why a row of two buttons fills the panel and a row of three does not fit, and there is a test that says so:

```smalltalk
LaserGameControlPanelElementTestCase >> testARowOfTwoButtonsFitsInsideThePanel
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
```

Widening a button and leaving the panel alone would have broken that test, and rightly: the buttons would no longer fill the panel.
The repair is not to adjust the panel's number to match.
We stop the panel having a number of its own:

```smalltalk
LaserGameElement class >> panelWidth
	"Answer the width, in pixels, of the control panel beside the board: exactly two buttons and
	the three gaps a row of two stands in. That identity is what makes a row of two fill the panel
	and a row of three not fit, so the panel is stated from the buttons rather than beside them."

	^ (2 * LaserGameControlPanelElement buttonWidth)
	  + (3 * LaserGameControlPanelElement buttonGap)
```

The test and the method now say the same thing, which is a fair question to raise: does the test still test anything?
It does, but less than it did.

It was the only statement of the identity, and now it is a second copy of it.
What it still catches is a change to the panel width made anywhere else — and what it mainly does now is document, in the suite, a relation that two methods depend on.

Four numbers move, and all four are the window twenty pixels wider:

```text
panel width      110  ->  130
counter width    102  ->  122
demo game        380@355  ->  400@355
eight by ten     530@520  ->  550@520
```

The counters need no change at all.
Their width is the panel less a gap on each side, stated as that expression in the previous chapter, so they widened with the panel and stayed flush with each other.
That is what writing a number as the expression that produced it buys, and this is the chapter where it gets paid.

Measure afterwards and you get every button fifty wide with its label in the middle: the longest of them, *Reset*, lands at `(8.5@1.0) corner: (41.5@19.0)`, which is eight and a half pixels of margin on each side instead of three and a half.

## The tests

We wrote both tests before the fix, and both were red when written.
The first measures the labels against the width:

```smalltalk
LaserGameControlPanelElementTestCase >> testEveryButtonLabelFitsInsideTheButton
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
```

Two things for you to notice.
`assert:<=` is `assert:description:` with a comparison in it: the first argument is a boolean expression, not a value to compare, so any expression that answers true or false can be asserted.

And `description:` is what the suite prints when the assertion fails, which is why it names the label: a failure says *Reset does not fit inside a button*, and you do not have to work out which pass of the loop went wrong.

> **In a test that loops, put the loop variable in the failure description.** Six assertions that all read the same are six assertions you cannot tell apart from the report.

The second test we write says every button centres its label:

```smalltalk
LaserGameControlPanelElementTestCase >> testEveryButtonCentresItsLabel
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
```

It asserts the alignment and not the position, for the reason the counters chapter gave: getting a position without opening a space means forcing a layout, which the critics rule `ReBlocDoNotSendForceLayoutRule` reports, so the positions quoted above were read by hand in a playground.

The loop is worth your attention, because of what it does not say.
It walks every row of the button column and every button of every row, so it covers the five buttons without naming any of them, and it covers the sixth if a sixth is ever added.

Note that it also walks the divider bar, which has no children, so the inner loop simply does nothing for it — a row with nothing in it asserts nothing, and that is the right answer rather than a special case.

Finally, one older test knew the panel's width as a literal, and the literal changed:

```st
	self
		assert: (LaserGameElement extentForGrid: grid)
		equals: 5 * CellRenderer cellExtent x + 130
			@ (5 * CellRenderer cellExtent y
			~T> max: LaserGameControlPanelElement contentHeight) + 20
```

That is `testExtentIsTheBoardPlusThePanelPlusTheMargins`, from *A missed bug*, and the `110` in it became `130`.

A literal in a test is a decision to be told when something changes, and this is the telling: the test went red, the number was read, the new number was understood and written down.
A test that had used `panelWidth` there would have stayed green and said nothing.

> **Expressions in the code, literals in the tests.** The code says how the number is arrived at; the test says what the number was when somebody last looked.

## A tab that says which label chose the width

`testEveryButtonLabelFitsInsideTheButton` is green, and it tells us nothing we can read.
It says that six labels fit inside fifty pixels, and the question anybody who touches this chapter again will have is the one it does not answer: which label is the one that chose the fifty, and how little room is left over.

That question is asked of the class, not of a panel, because the labels and the width are both class-side:

```smalltalk
LaserGameControlPanelElement class >> inspectionLabelFacts
	"Answer each label a button of mine can show, with the width that label needs: the width Toplo
	measures for the text, with my label margin on each side of it. The width is rounded up,
	since a button takes whole pixels."

	^ self buttonLabels collect: [ :each |
		  each
		  -> ((self widthOfButtonLabel: each) ceiling + (2 * self buttonLabelMargin)) ]
```

```smalltalk
LaserGameControlPanelElement class >> inspectionLabels: aBuilder
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
```

```text
Label | Needs | Button holds | Spare | Fits
Quit  | 37    | 50           | 13    | yes
Fire  | 34    | 50           | 16    | yes
Stop  | 40    | 50           | 10    | yes
New   | 38    | 50           | 12    | yes
Undo  | 45    | 50           | 5     | yes
Reset | 45    | 50           | 5     | yes
```

*Undo* and *Reset* need 45 of the 50, and they are the two labels that chose the width.
*Fire* needs 34, and *Stop*, the label the fire button takes while the laser is firing, needs 40 — which is the pair this chapter was really about, because a button sized for one of them is too small for the other.
Five pixels of spare is not much, and that is a fact worth seeing rather than deducing.

The *Fits* column is the test, written as a word a reader can scan down.
It cannot disagree with the test, because both of them compare the same two numbers — and the test says so by checking the column rather than the rule:

```smalltalk
LaserGameControlPanelElementTestCase >> testTheLabelsTabSaysWhetherEveryLabelFitsInsideItsButton
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
```

> **A number that was once a bug is worth a standing view.** The table that would have found it in a minute costs one method, and it goes on finding it.

## A tab for the numbers the panel is laid out from

Two chapters have now been bugs in the control panel: four counters of four widths, and labels running off the right edge of their buttons.
Both were fixed by stating a number once and laying everything out from it.
We are left with eleven numbers spread over eleven methods, and no page that shows them together.

```smalltalk
LaserGameControlPanelElement class >> inspectionMeasureFacts
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
```

```smalltalk
LaserGameControlPanelElement class >> inspectionMeasures: aBuilder
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
```

```text
Measure             | Pixels
Panel width         | 130
Counters            | 4
Counter width       | 122
Counter gap         | 4
Rows of buttons     | 3
Button width        | 50
Button height       | 20
Button gap          | 10
Button label margin | 6
Divider height      | 5
Content height      | 335
```

Read down that column and the panel is there: 130 wide, four counters each 122 wide with 4 to spare on each side, three rows of buttons 50 by 20 with 10 between them, a 5 pixel divider, and 335 of content in all.
`Content height` is the only measured number in the list — it builds a counter and asks Toplo how tall it came out — and that is exactly why it is worth showing beside the ten stated ones.

The two methods are a pair worth copying.
`inspectionMeasureFacts` is the answer, and `inspectionMeasures:` is only the table that draws it, which is what lets a test read the facts without a presenter and read the table when it wants to:

```smalltalk
LaserGameControlPanelElementTestCase >> testTheMeasuresTabStatesEveryWidthAndHeightIKeep
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
```

Neither tab needs an example to open it on.
A class-side view is read by inspecting the class itself, and `LaserGameControlPanelElement` is as easy to get at as any example we could write for it.

## Checking it

We measure the labels against the button:

```smalltalk
LaserGameControlPanelElement buttonLabels collect: [ :each |
	each -> (LaserGameControlPanelElement widthOfButtonLabel: each) ]
```

You get `Quit` 25, `Fire` 22, `Stop` 28, `New` 26, `Undo` 33, `Reset` 33 — the widest of them thirty three, in a button of fifty, with a stated margin of six on each side.
Then the panel and the window:

```smalltalk
{ LaserGameElement panelWidth.
  LaserGameControlPanelElement counterWidth.
  LaserGameElement extentForGrid: GridExample demoGrid.
  LaserGameElement extentForGrid: GridFactory defaultGrid }
```

You get `{130.
122.
400@355.
550@520}`.

And then the whole suite:

```text
237 run, 237 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

# Looking at objects

Every tab this game has was written in the chapter that wanted it.
*Sides* and *Lean* came out of a red test in *Enhancing MirrorCell*, *Board* and *Beam* out of the two drawing chapters, *Regions* and *Map* out of the argument about where a click lands, *Segments* out of a counter that showed the wrong digit, and *Moves* out of the undo stack three chapters ago.
Not one of them was written because a chapter about the inspector had come round.

This chapter is the practice rather than the tabs.
It states the five lessons the nineteen tabs were written under, shows how a view is tested without a window, gives the finished versions of the two gates *Enhancing MirrorCell* promised, says when a view or an example is dead, and ends with the map of every tab and the object to open it on.

## Where each tab was written

```text
Tab        | Class                              | Chapter
Sides      | Cell                               | Enhancing MirrorCell
Lean       | MirrorCell                         | Enhancing MirrorCell
Cells      | Grid                               | Grid
Board      | Grid                               | The game board
Picture    | Cell                               | Drawing the mirror, finished in Laser on blank cell
Palette    | LaserGameColors class              | Management of colours
Beam       | Grid                               | Drawing the target
Shapes     | LaserGameShapes class              | Curved arrows for rotation
Regions    | CellClickRegion class              | Determine rotate regions
Map        | CellClickRegion class              | Determine rotate regions
Directions | GridDirection class                | Push a cell
Step       | LaserPathElement                   | Push a cell
Pushes     | Grid                               | Push cells with the mouse
Segments   | LaserGameLedElement                | Add a counter and window colours
Boards     | GridFactory class                  | A bigger game board
Counts     | GridFactory class                  | A bigger game board
Moves      | Grid                               | Undo
Labels     | LaserGameControlPanelElement class | Buttons of one width
Measures   | LaserGameControlPanelElement class | Buttons of one width
```

Nineteen tabs, eleven classes, five sections.
The question behind all of them is explainability.
A reader who wants to know how a mirror decides where a beam leaves has two ways in.
One is to read `rotate`, `leanLeft`, `leanRight` and `exitSideFor:` and hold four mappings in their head.
The other is to inspect a mirror and read the answer off a table.
The second way is better, and it costs one method per question.

## When a view gets written

A view is written on one of two signals and on nothing else.

The first is that you expanded the same path in the inspector a second time, or that `printOn:` was not enough while you were in the debugger.
The second is the one *Enhancing MirrorCell* calls diagnosis debt: a red test took more than about a minute to work out, and the minute went on reaching a fact the object could have shown you.
That is a missing view rather than a missing skill, and it is written while the gap is still fresh.

There are three kinds, and they do not arrive at the same time.
A structural tab shows what the object holds, like *Cells* and *Sides*, and it pays for itself the day it is written.
A derived tab answers a rule, like *Pushes*, *Lean* and *Counts*, and it is written at the end of a feature rather than in the middle of one.
A rendered tab draws the object through the real renderer, like *Board*, *Picture* and *Shapes*, and it is only worth it for objects whose whole point is visual.

Two tabs on one class is the most this book ever adds at once, and it is the ceiling to keep.
Ten tabs on one class are ten tabs nobody reads.
A third tab wanted in the middle of a feature is almost always derived work that can wait for the end of it.

## A view is a method, so it is tested like one

This is the lesson that makes the other four cheap.
A view carries no new dependency: it is one method with a pragma on it, in the class it describes, and the test that covers it is an ordinary `TestCase` method in the ordinary test class.
`MirrorCellTestCase` tests *Lean* and `GridTestCase` tests *Moves*, in the same suite as everything else, and nothing in the project knows that a UI exists.

The rule that makes it work is splitting the data from the presentation.

```text
inspectionLabelFacts        "data: a plain collection, with real assertions on it"
inspectionLabels: aBuilder  "presentation: one test, that it builds without error"
```

The data method answers a collection of associations or of arrays, and a test asserts on it exactly as it would on any other method.
The presentation method wraps that collection in a table, and its test says the table was built, that its columns are the ones named, and that the rows are the ones expected.
Where a view is too small to be worth two methods, as *Lean* is, the test reaches the data through the column instead: `matches evaluation value: aRow` runs the block the column was given on one row, which is the view's claim stated as an assertion.

A rendered tab is the one case where the assertion has to be chosen with care.

> **A test of a picture tests what the picture was asked for.** Pixels need a window; sizes and children do not.

So the *Picture* test asserts the class of the presenter and the state of the cell afterwards, the *Shapes* test asserts the extents the gallery asked for, and no test in this book opens a space to look at a colour.

## A view must not change what it shows

The *Picture* tab builds a grid of its own and puts a `copy` of the cell on it, because `Grid >> at:put:` tells the cell where it now stands.
Handing it `self` would move the inspected cell onto the scratch board and leave it there.

> **A view must not change what it shows.** Inspecting an object is a question, and a question that alters the answer is not one.

The rule has no exceptions worth taking: not a lazy initialisation, not a sort in place, not a cached derived value.
A view that breaks it is worse than no view, because the object you looked at is no longer the object you had.

## A view asks the rules instead of restating them

*Lean* does not hold its own copy of the four mappings a mirror leaning right makes; it calls `exitSideFor:` four times and compares the answer with what the lean says it should be.
*Map* paints the click geometry by asking `inspectionRegionAt:` for a grid of sample points rather than by drawing seven rectangles of its own.
*Counts* counts the cells of a board the factory dealt rather than repeating the proportions the dealer was given.

> **Compare against the rule, not against a copy of it.** A second statement of the same mapping is a second thing to keep right.

A view that restates a rule agrees with the code until the day the code changes, and then it lies with all the authority of a table.

## A question about a hierarchy belongs on the class

Nine of the nineteen tabs are on the class side, and each of them answers for a whole family: the four directions, the seven click regions, the seven shapes, the palette, the two boards the factory deals and the counts on them, and the labels and measurements the panel is laid out from.

> **A class-side tab belongs to the class that can answer for the whole hierarchy.** Where the answer would be partial, hide the tab rather than show half of one.

That is what `inspectionRegionsContext:` and `inspectionMapContext:` do when you inspect `CellClickRegionInside` instead of `CellClickRegion`: the tab does not appear, because one region cannot answer for all of them.
The same test applies from the other side.

> **A view on the instance has to say something about this instance.** Otherwise it is a class-side view in the wrong place, and it will be read by a reader who wanted to know what this object is doing.

And a tab with nothing to say at all hides itself, which is `inspectionMovesContext:` on an unplayed board.

## The list a view needs is read off the object

*Boards* draws the boards named by `inspectionBoardFacts`, and *Counts* counts the boards named by the same method, so the picture and the numbers cannot disagree about which boards exist.
*Labels* reads `buttonLabels`, and *Shapes* reads `inspectionShapeSelectors`.

> **Read the list off the object rather than into the view.** A list written into a view is a second place to remember, and the day it is forgotten the tab quietly stops showing the whole truth.

## The first gate, finished

*Enhancing MirrorCell* wrote both gates the day the example package was born, with one example in it, and promised the finished versions here.
They live in `LaserGameExamplesTestCase`, in `Laser-Game-Tests`, which is the one test class in this book that tests the project rather than the game.

Both gates start from the package and the examples in it:

```smalltalk
LaserGameExamplesTestCase >> examplePackage
	"Answer the package the examples live in."

	^ (self class environment at: #PackageOrganizer) default packageNamed: 'Laser-Game-Examples'
```

```smalltalk
LaserGameExamplesTestCase >> exampleMethods
	"Answer every example, sorted, so a failure always names the same one first."

	^ (self examplePackage methods select: [ :each |
		   each pragmas anySatisfy: [ :pragma | pragma selector = #sampleInstance ] ])
		  asSortedCollection: [ :one :other |
		  one methodClass name , one selector
		  <= (other methodClass name , other selector) ]
```

The sort is for whoever reads the red: the failures arrive in the same order on every run, so a list of them can be worked through from the top.

Five of the twenty-one examples put a window on screen on purpose, and the gates separate them from the rest by name:

```smalltalk
LaserGameExamplesTestCase >> quietExampleMethods
	"Answer the examples that answer an object without opening a window: everything but the openers."

	^ self exampleMethods reject: [ :each | each selector beginsWith: 'open' ]
```

The first gate runs every quiet example and asks two things of what comes back:

```smalltalk
LaserGameExamplesTestCase >> testEveryQuietExampleAnswersAnObjectWithATabOfOurOwn
	"An example that answers an object is worth one click because the inspector it opens has something of ours to show."

	self denyEmpty: self quietExampleMethods.
	self quietExampleMethods do: [ :each |
		| subject |
		subject := self runExample: each.
		self
			deny: subject isNil
			description: each selector , ' answers nil'.
		self
			deny: (self tabsShownFor: subject) isEmpty
			description: each selector , ' answers an object with no tab of ours' ]
```

```smalltalk
LaserGameExamplesTestCase >> runExample: aCompiledMethod
	"Answer what the example answers. An example is a class-side method, so it is the class itself that is asked."

	^ aCompiledMethod methodClass instanceSide perform: aCompiledMethod selector
```

That an example builds without error is the half *Enhancing MirrorCell* wrote.
That the object it answers has a tab of ours to show is the half the finished version adds, and it is what turns an example from a snippet into one useful click.

## The second gate, finished

The second gate goes the other way: from the tabs the game defines to the examples that reach them.

```smalltalk
LaserGameExamplesTestCase >> tabMethodsDefinedBy: aClassOrPackage
	"Answer the inspector tabs of our own packages among the methods of aClassOrPackage."

	^ aClassOrPackage methods select: [ :each |
		  (each pragmas anySatisfy: [ :pragma |
			   pragma selector = #inspectorPresentationOrder:title: ]) and: [
			  each package notNil and: [
				  each package name beginsWith: 'Laser-Game' ] ] ]
```

```smalltalk
LaserGameExamplesTestCase >> tabsShownFor: anObject
	"Answer the names of the tabs of our own that the inspector shows for anObject.
	Asking the class of anObject covers both sides: a cell answers the tabs its class and its superclasses define, and a class answers the ones defined on its metaclass."

	^ (anObject class withAllSuperclasses flatCollect: [ :each |
		   self tabMethodsDefinedBy: each ]) collect: [ :each |
		  each methodClass name , ' >> ' , each selector ]
```

`withAllSuperclasses` is what makes an inherited tab count: a `MirrorCell` shows *Sides* because `Cell` defines it, and asking the class of an object covers the class side too, because the class of a class is its metaclass.

```smalltalk
LaserGameExamplesTestCase >> instanceSideTabNames
	"Answer the name of every inspector tab the game defines on the instance side of a class.
	The class-side tabs are not here: inspecting the class itself shows them, which needs no example."

	| package |
	package := (self class environment at: #PackageOrganizer) default
		           packageNamed: 'Laser-Game'.
	^ (((self tabMethodsDefinedBy: package) reject: [ :each |
		    each methodClass isMeta ]) collect: [ :each |
		   each methodClass name , ' >> ' , each selector ]) asSet
```

```smalltalk
LaserGameExamplesTestCase >> testTheExamplesReachEveryInstanceSideTabTheGameDefines
	"Whatever tab the game grows on the instance side, one click of the examples opens an inspector that shows it.
	A tab on the class side is not asked for here: inspecting the class shows it, and demanding an example for it only breeds methods whose whole body answers a class."

	| reached |
	reached := Set new.
	self quietExampleMethods do: [ :each |
		reached addAll: (self tabsShownFor: (self runExample: each)) ].
	self assertEmpty:
		(self instanceSideTabNames difference: reached) asSortedCollection asArray
```

The exemption in that comment is the correction this book owes its own earlier self.
An honest reading of "every view needs an example" produced six methods whose whole body answered a class, one per class-side tab, written to satisfy a test rather than to be clicked.
They were deleted, and the gate was narrowed to the instance side, where an example is the only way in.

A class-side tab is not left unchecked, though.
It is checked by asking the inspector the question its reader will ask:

```smalltalk
LaserGameExamplesTestCase >> classSideTabMethods
	"Answer every inspector tab the game defines on the class side of a class, the tabs you see by inspecting the class."

	| package |
	package := (self class environment at: #PackageOrganizer) default
		           packageNamed: 'Laser-Game'.
	^ (self tabMethodsDefinedBy: package) select: [ :each |
		  each methodClass isMeta ]
```

```smalltalk
LaserGameExamplesTestCase >> testEveryClassSideTabIsShownByInspectingItsClass
	"A tab defined on the class side is reached by inspecting the class itself, so it needs no example of its own. I check that the inspector really shows it there."

	| tabs |
	tabs := self classSideTabMethods.
	self denyEmpty: tabs.
	tabs do: [ :each |
		| name |
		name := each methodClass name , ' >> ' , each selector.
		self
			assert: ((self tabsShownFor: each methodClass instanceSide) includes: name)
			description: name , ' is not shown by inspecting its class' ]
```

> **A gate that breeds methods is the wrong gate.** When a rule starts producing code that exists only to satisfy it, the rule has the wrong scope, not the code.

## Two gates the package grew later

The package holds examples and nothing else, so anything in it without the pragma is a method the browser will not offer and nobody will find:

```smalltalk
LaserGameExamplesTestCase >> testEveryMethodOfThePackageIsAnExample
	"The package holds examples and nothing else, so everything in it is one click the browser offers."

	| strays |
	strays := self examplePackage methods reject: [ :each |
		          each pragmas anySatisfy: [ :pragma |
			          pragma selector = #sampleInstance ] ].
	self assertEmpty: (strays collect: [ :each |
			 each methodClass name , ' >> ' , each selector ]) asArray.
	self denyEmpty: self exampleMethods
```

And the name of an example says what the click costs, which is worth a test because the cost is a window:

```smalltalk
LaserGameExamplesTestCase >> opensAWindow: aCompiledMethod
	"Answer whether aCompiledMethod puts a window on screen. It does if it sends openOn:, which opens a space on an element, or show, which opens a space it built itself. Read off the sends, so that asking puts up no window."

	^ aCompiledMethod messages anySatisfy: [ :each |
		  #( openOn: show ) includes: each ]
```

```smalltalk
LaserGameExamplesTestCase >> testOnlyAnExampleNamedOpenOpensAWindow
	"Reading the selector tells you what the click costs: an opener puts a window on screen, anything else only answers an object."

	self quietExampleMethods do: [ :each |
		self
			deny: (self opensAWindow: each)
			description: each selector , ' opens a window but is not named open...' ].
	(self exampleMethods select: [ :each | each selector beginsWith: 'open' ])
		do: [ :each |
			self
				assert: (self opensAWindow: each)
				description: each selector , ' is named open... but opens no window' ]
```

`messages` is the set of selectors the method sends, so the question is answered by reading the code rather than by running it.
A gate that had to run the openers to find out would put five windows on screen every time the suite ran.

## When a view or an example is dead

Examples and views accumulate unless something collects them, and all three rules are mechanical enough to run rather than discuss.

An example with no sender and no `<sampleInstance>` is dead, because nothing in the image and nobody in the browser can reach it.
A view nobody opened during a whole feature, and which says no more than the structural tab beside it already says, is dead.
A view that draws a thing the game no longer has goes the day the thing goes.

The honest place to run the collector is at a release, with the whole suite green, because a deletion that breaks a test is a deletion that tells you the view was load-bearing after all.

## Which object to inspect

We now have nineteen tabs across eleven classes, and the way to see them is to inspect something.
A grid that has been fired and played on shows all five of its tabs:

```smalltalk
| grid |
grid := GridExample demoGrid.
grid fireLaser.
grid rotateCellClockwiseAt: 1 @ 5.
grid pushCellEastFromLocation: 1 @ 2.
grid inspect
```

*Board* is the picture, *Beam* the path, *Cells* every cell and its state, *Moves* the undo stack and *Pushes* the four rules per mirror.
Drop the two moves and *Moves* is gone from your inspector, which is `inspectionMovesContext:` doing its work.

One cell shows *Sides* and *Picture*, and a mirror shows *Lean* as well:

```smalltalk
(GridExample demoGrid at: 2 @ 3) inspect
```

```smalltalk
(GridExample demoGrid at: 5 @ 1) inspect
```

```smalltalk
(GridExample demoGrid at: 2 @ 2) inspect
```

Those three are the mirror, the target and a blank cell, and the *Picture* tab draws each of them through its own renderer.
A mirror built by hand needs no board at all:

```smalltalk
MirrorCell leanLeft inspect
```

And one step of the beam shows *Step*:

```smalltalk
| grid |
grid := GridExample demoGrid.
grid fireLaser.
grid laserBeamPath last inspect
```

That last one is the target cell at the end of the beam, so its *Step* tab is the `nowhere` table above.
Inspect `grid laserBeamPath first` instead and you get the one before it.

The last two tabs are on classes rather than on instances, so what you inspect is the class itself:

```smalltalk
CellClickRegion inspect
```

```smalltalk
GridDirection inspect
```

*Regions* and *Map* on the first, *Directions* on the second.
Inspect `CellClickRegionInside` instead and neither tab appears, which is the two context methods refusing to answer for a hierarchy from the middle of it.

Four more classes answer for themselves, and we inspect each of them the same way:

```smalltalk
LaserGameShapes inspect
```

```smalltalk
LaserGameColors inspect
```

```smalltalk
LaserGameControlPanelElement inspect
```

```smalltalk
GridFactory inspect
```

*Shapes* on the first, *Palette* on the second, *Measures* and *Labels* on the third, *Boards* and *Counts* on the last.
The *Boards* tab deals a fresh random board each time you open it, so close the inspector and open it again and the third board has changed.

The one display tab is on an instance, and a display needs a value before it has anything to say:

```smalltalk
| led |
led := LaserGameLedElement digits: 3.
led value: 108.
led inspect
```

*Segments* is the ten digits against the seven segments, and the last column of it marks the three digits of 108.


## Checking it

This chapter adds five tests and the class they live in, and that is the suite complete:

```text
242 run, 242 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

That is the count for a suite built from the book.
The package in the repository answers a larger number, because it carries thirty-two tests the book never shows: more cases of tests the book does write, such as the remaining push directions, and a handful on the confirmation dialog and the digit display that no chapter had room for.
Loading `Laser-Game-Tests` and running it gives two hundred and seventy-four.

That is the game: a board of cells that knows nothing about how it is drawn, a beam that walks it, a window built out of named numbers, twenty-one examples that open any of it in one click, nineteen tabs that explain the lot without a method being read, and two hundred and forty-two tests that will say so again tomorrow.
