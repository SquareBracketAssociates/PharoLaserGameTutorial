# Interacting with cells

The board is on the screen and the laser fires, so the game can now be played with the mouse.
Only mirror cells react: a mirror can be rotated, and it can be pushed to the next square along.

That is two different actions on one cell, and the mouse has one button, so the cell has to decide from *where* it was clicked which of the two was meant.

In this chapter we build that decision as a hierarchy of regions — `CellClickRegionInside`, `CellClickRegionOutside` and `CellClickRegionIgnore` — let priority rather than geometry settle the overlaps, and give the cell element the job of answering which region a point falls in.
No test in it names a pixel.

We divide a cell into three areas, one inside the next:

- an **inside** region, a square around the centre. A click here pushes the cell.
- an **outside** region, the ring around it. A click here rotates the cell.
- an **ignore** region, the margin along the four edges. A click here does nothing: someone clicking
  that close to an edge is probably aiming at the cell next door, and guessing would be worse than
  dropping the click.

In this chapter we build that classification and its tests.
Nothing is wired to the mouse yet — that is the next chapter — but by the end of this one we can hand a cell element a point and it will say which region it fell in.

## The constants live with the cell size

We put the numbers on the class side of `CellRenderer`, which already holds the size of a cell, in a protocol called `constants`:

```smalltalk
CellRenderer class >> cellExtent
	"Answer the size, in pixels, of one cell. Every other size in the package is derived from
	this one, so a cell of another size needs no other change anywhere."

	^50@50
```

```smalltalk
CellRenderer class >> insideRegionExtent
	"Answer the size of the square in the middle of a cell where a click asks for a push: the
	cell less twenty pixels, so the ring around it keeps its width while the cell grows."

	^self cellExtent - 20
```

```smalltalk
CellRenderer class >> ignoreRegionOffset
	"Answer the width, in pixels, of the margin along the edges of a cell where a click does
	nothing. Four pixels is right at any cell size: the margin is there to keep a click aimed at
	the neighbouring cell from turning this one."

	^4
```

```smalltalk
CellRenderer class >> outsideRegionExtent
	"Answer the size of the square where a click asks for a rotation: the cell less the ignore
	margin on each side. The margin is what is written down, not the region."

	^self cellExtent - (2 * self ignoreRegionOffset)
```

Only two of those four are numbers.
`cellExtent` is the size of a cell and `ignoreRegionOffset` is the width of the dead margin; the other two are arithmetic on them.

With a cell of 50 by 50 you get an inside square of 30 by 30, an outside square of 42 by 42, and an ignore margin of 4 pixels all round.

That split is deliberate, and it is the reason a later chapter can make the cells bigger by changing one method.
Ask of every constant you write: *is this a decision, or a consequence?*
A decision gets a number.
A consequence gets an expression.

Writing `^30@30` for the inside region would have been two decisions pretending to be one, and they would have drifted apart the first time a cell changed size.

## A class per region

We make the three regions classes, and never instantiate one.
There is nothing for an instance to carry: the regions are the same three shapes for every cell in the game, so what the code needs is three *names* that can answer questions, and a class is a name that can answer questions.

`CellClickRegion` is the abstract root, and it declares what every region has to answer:

```smalltalk
CellClickRegion class >> regionRectangle
	"Answer the rectangle, in cell coordinates, that I claim. Every concrete region answers one."

	^ self subclassResponsibility
```

```smalltalk
CellClickRegion class >> sortIndex
	"Answer where I come in the order regions are asked in. The innermost region answers the
	smallest number, so that it claims a point the wider regions also contain."

	^ self subclassResponsibility
```

`subclassResponsibility` is the way a superclass says "I have no answer, and a subclass must".

It is not a comment: a subclass that forgets to implement the method gets an error naming it, which tells you more than a silent wrong answer.
Write it in the superclass for every message the subclasses are *required* to answer, and the hierarchy documents itself.

Each concrete region then derives its rectangle from the constants:

```smalltalk
CellClickRegionInside class >> regionRectangle
	"CellClickRegionInside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer insideRegionExtent.
	^outer insetBy: (delta // 2)
```

```smalltalk
CellClickRegionOutside class >> regionRectangle
	"CellClickRegionOutside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer outsideRegionExtent.
	^outer insetBy: (delta // 2)
```

```smalltalk
CellClickRegionIgnore class >> regionRectangle
	^0@0 extent: CellRenderer cellExtent
```

The first line of each of the first two is a comment that is really a snippet: select it in the browser, print it, and see the rectangle.
That is a habit worth picking up in your own code for any method whose answer is easier to look at than to describe.

`0@0 extent: CellRenderer cellExtent` is the whole cell, and `insetBy:` shrinks a rectangle equally on all four sides.
Half the difference on each side is what centres the smaller square in the larger.
And the ignore region's rectangle is the entire cell — not the margin.
That looks wrong until you read the next method.

## Priority decides, not geometry

The three rectangles are nested, so a point near the centre of a cell is inside all three of them, and "which rectangle contains this point" has three right answers.
Geometry alone cannot choose.
What chooses is an order: you ask the innermost region first and take the first match.

```smalltalk
CellClickRegion class >> sortedSubclasses
	^self subclasses asSortedCollection: [:a :b | a sortIndex < b sortIndex]
```

```smalltalk
CellClickRegion class >> clickRegionForPoint: aPoint
	"Answer the region of a cell aPoint falls in. My subclasses are tried innermost first, and the
	ignore region covers the whole cell, so any point within a cell finds one. A point outside the
	cell finds none, and is ignored: a click there can do nothing, which is what the ignore region
	already means. A mouse event carries such a point whenever the element under the pointer is
	larger than the cell the regions are computed from, and answering it here keeps the case out of
	every mouse handler."

	^self sortedSubclasses
		detect: [ :cls | cls regionRectangle containsPoint: aPoint ]
		ifNone: [ CellClickRegionIgnore ]
```

So `sortIndex` answers 1 for the inside region, 2 for the outside region and 3 for the ignore region — whose rectangle is the whole cell and therefore always matches.

A point no smaller region claimed lands there, which is exactly what "ignore" means.
The ignore region does not need to know it is a margin; being last and being everything is the same thing.

`self subclasses` is the other half of the trick.
Nothing lists the three regions anywhere: the hierarchy *is* the list.
A fourth region added later needs a `regionRectangle`, a `sortIndex` and nothing else, and the dispatcher above picks it up without you touching it.

## Tests that name no pixel

Now the tests, and there is a trap we have to avoid in them.
The obvious way to test a region is to pick a point that ought to be in it — 13 by 13, say — and assert the answer.

Do that and you have written down the cell size twice: once in `cellExtent` and once in your head.
Change the cell size and the test fails without anything being wrong.

So not one of the tests we write names a pixel.
They ask the rectangles where they are, and assert about the corners the rectangles answer:

```st
CellClickRegionTestCase >> testClicksInIgnoreRegion

	| ignoreRect outsideRect |
	ignoreRect := CellClickRegionIgnore regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	"The ignore region is the margin of the cell left over once the outside region is inset."
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
> **Note.** *A less brittle test design*, in Section 5, moves this body into `#assertIgnoreRegionBoundaries` so that a second test can run it at three cell sizes; the test itself becomes one call of that method.

Read the four assertions as a shape, because every boundary test in this book has it: the first pixel that *is* in the region, the last pixel that is in it, the pixel just outside it, and one point that must belong to somebody else.

`bottomRight - (1@1)` is the last pixel inside a rectangle, because a rectangle does not contain its bottom and right edges — a detail that bites you once and then never again.

The same shape covers the outside region, the ring between the ignore margin and the inside square:

```st
CellClickRegionTestCase >> testClicksInOutsideRegion

	| insideRect outsideRect |
	insideRect := CellClickRegionInside regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	"The outside region is the ring between the ignore margin and the inside region."
	self
		deny: (CellClickRegion clickRegionForPoint: outsideRect topLeft - (1 @ 1))
		equals: CellClickRegionOutside.
	self
		assert: (CellClickRegion clickRegionForPoint: outsideRect topLeft)
		equals: CellClickRegionOutside.
	self
		assert: (CellClickRegion clickRegionForPoint: insideRect topLeft - (1 @ 1))
		equals: CellClickRegionOutside.
	self
		assert: (CellClickRegion clickRegionForPoint: outsideRect bottomRight - (1 @ 1))
		equals: CellClickRegionOutside.
	self
		deny: (CellClickRegion clickRegionForPoint: insideRect center)
		equals: CellClickRegionOutside
```
> **Note.** *A less brittle test design*, in Section 5, moves this body into `#assertOutsideRegionBoundaries` and leaves the test as one call of it.

and `testClicksInInsideRegion` does the third, checking that the inside region owns its top left corner, its centre, and its last pixel, and owns nothing beyond them.

## The cell becomes the thing you click

A click arrives somewhere on the screen, and the game has to answer two questions about it: *which cell?*
and *where in that cell?*
Both are free here, because every cell is already an element of its own and Bloc hands an event handler the position in the coordinates of the element that received it.
There is no board-wide coordinate for you to convert.

What is missing is the other direction: given the element, which cell of the model is it?
So we give the cell element a class of its own, holding the renderer that built it:

```smalltalk
LaserGameCellElement >> cell
	"Answer the cell I show."

	^ self renderer cell
```

```smalltalk
LaserGameCellElement >> gridLocation
	"Answer where my cell sits in the grid, x being the column and y the row."

	^ self renderer cellLocation
```

```smalltalk
LaserGameCellElement >> clickRegionAt: aPoint
	"Answer the click region class aPoint falls in. aPoint is in my own coordinates, which is what
	Bloc hands to an event handler, so no board offset is subtracted first."

	^ CellClickRegion clickRegionForPoint: aPoint
```

The element holds the *renderer* and not the cell, which is worth a sentence.
The renderer already knows the grid and the location within it, and it is the thing that redraws the cell when the model changes.

Holding it is what lets a later chapter refresh a single cell in place instead of rebuilding the whole board — and it is why `cell` is a question the element passes on rather than a variable it keeps.
A variable would be a copy of something that is allowed to change.

The renderer builds that element instead of a plain one:

```st
CellRenderer >> newElement
	"Answer a new element rendering my cell. The element is square, keeps me as its renderer,
	carries the cell background and border, and holds whatever my subclass draws as children."

	| element |
	element := LaserGameCellElement new.
	element renderer: self.
	element extent: self class cellExtent.
	element geometry: BlRectangleGeometry new.
	self renderBackgroundOn: element.
	self renderBorderOn: element.
	self renderContentsOn: element.
	^ element
```
> **Note.** *Laser on blank cell*, in Section 4, adds one line to this method, so that a lit cell draws the beam, and *Laser on target cell* puts that line before the contents.

The board goes on building one per cell, in row order, and lets the grid layout place them:

```smalltalk
LaserGameBoardElement >> rebuildCells
	"Replace my children with one element per cell of my grid, row by row. The grid layout
	places them, so no cell has to work out where it is on a shared surface."

	self removeChildren.
	self layout columnCount: self grid numberOfColumns.
	1 to: self grid numberOfRows do: [ :row |
		1 to: self grid numberOfColumns do: [ :column |
			| location |
			location := column @ row.
			self addChild: (CellRenderer
					 rendererFor: (self grid at: location)
					 grid: self grid) newElement ] ]
```

```smalltalk
LaserGameBoardElement >> cellElementAt: aPoint
	"Answer the element showing the cell at aPoint, x being the column and y the row."

	| index |
	index := aPoint y - 1 * self grid numberOfColumns + aPoint x.
	^ self children at: index
```

## Tests

We write five tests, and they are about identity and coordinates rather than about drawing:

```smalltalk
LaserGameCellElementTestCase >> testACellElementKnowsTheCellItShows
	"A cell element carries its own cell, so nothing has to work back from a position on the
	board to a grid location."

	| element |
	element := board cellElementAt: 2 @ 3.
	self assert: element cell identicalTo: (board grid at: 2 @ 3).
	self assert: element gridLocation equals: 2 @ 3
```

```smalltalk
LaserGameCellElementTestCase >> testEveryChildOfTheBoardIsACellElement
	"The board holds one cell element per cell of its grid."

	grid := board grid.
	self
		assert: board children size
		equals: grid numberOfColumns * grid numberOfRows.
	board children do: [ :each |
		self assert: each class equals: LaserGameCellElement ]
```

```smalltalk
LaserGameCellElementTestCase >> testEachCellElementCarriesTheRendererOfItsCell
	"The element is built by a renderer, and it keeps it: that is what redraws the cell later."

	board children do: [ :each |
		self assert: each renderer class modelClass equals: each cell class ]
```

```smalltalk
LaserGameCellElementTestCase >> testACellElementClassifiesAPointOfItsOwn
	"A point is classified in the coordinates of the cell element itself: the top left corner is in
	the ignore margin, the first pixel of the outside rectangle is in the outside region, and the
	centre is in the inside region."

	| element |
	element := (LaserGameBoardElement on: GridExample demoGrid) cellElementAt: 1 @ 1.
	self
		assert: (element clickRegionAt: 0 @ 0)
		equals: CellClickRegionIgnore.
	self
		assert: (element clickRegionAt: CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionOutside.
	self
		assert: (element clickRegionAt: CellClickRegionInside regionRectangle center)
		equals: CellClickRegionInside
```

And the last one is the point of the whole step: the far corner of the board answers exactly what the origin answers.

```smalltalk
LaserGameCellElementTestCase >> testTheSameLocalPointMeansTheSameRegionInEveryCell
	"Every cell classifies points in its own coordinates, so the cell in the far corner answers
	exactly what the cell at the origin answers."

	| first last |
	first := board cellElementAt: 1 @ 1.
	last := board
		        cellElementAt: board grid numberOfColumns @ board grid numberOfRows.
	{ 0 @ 0.
	CellClickRegionOutside regionRectangle topLeft.
	CellClickRegionInside regionRectangle center } do: [ :point |
		self
			assert: (last clickRegionAt: point)
			equals: (first clickRegionAt: point) ]
```

That test asserts an *absence*: there is no position arithmetic anywhere in this chain, so there is nowhere for a position bug to live.
Tests that pin down what the design makes impossible are worth writing, because the next person to touch the code is told what they must not reintroduce.

## Checking it

```smalltalk
| board element |
board := LaserGameBoardElement on: GridExample demoGrid.
element := board cellElementAt: 5 @ 5.
element clickRegionAt: CellClickRegionInside regionRectangle center
```

answers `CellClickRegionInside`, and `0 @ 0` on the same element answers `CellClickRegionIgnore`.
You see the window exactly as it was at the end of the last section — in this chapter we changed what the cells *are*, not what they show.
The next one gives them mouse events.

# Handle mouse events

A cell can classify a point.
Now we have to give it one, which means the mouse.
In this chapter `LaserGameCellElement` listens for enter, leave, move and click, the board remembers which cell the pointer is over and which one was clicked last, and the tests send real Bloc events instead of calling the handlers by hand.

Think for a moment about what that would take if the board were a single picture.
The pointer would report a position on the screen; the position of the window, the margin around the board and the width of the control panel would all have to be subtracted; the remainder would be divided by the cell size to get a column and a row.

Every one of those terms is a chance for you to be wrong, and every change to the window layout breaks the arithmetic.

We need none of that here, and the reason is a decision we took two chapters ago: every cell is an element of its own.

Bloc delivers a mouse event to the element the pointer is over, and it hands the handler the position in that element's own coordinates.
So the cell that should react is the cell that gets told, and the point is already a point in a cell.

## A cell listens for itself

We need four events for this game: the pointer coming in, the pointer going out, the pointer moving inside, and a click.
The cell element installs a handler for each of them when it is created:

```smalltalk
LaserGameCellElement >> initialize
	"Listen to the mouse myself. Every cell is an element of its own, so Bloc delivers an event to
	the cell it happened in, and no cell has to be worked out from a position on the board."

	super initialize.
	self addEventHandlerOn: BlMouseEnterEvent do: [ :anEvent | self mouseEnter: anEvent ].
	self addEventHandlerOn: BlMouseLeaveEvent do: [ :anEvent | self mouseLeave: anEvent ].
	self addEventHandlerOn: BlMouseMoveEvent do: [ :anEvent | self mouseMove: anEvent ].
	self addEventHandlerOn: BlClickEvent do: [ :anEvent | self click: anEvent ]
```

`addEventHandlerOn:do:` takes an event class and a block.
The block gets the event, and all four of these blocks do the same thing with it: send one message to the element itself.

That is a habit worth keeping.
A handler block is hard to find, hard to name, and hard to test; a method is none of those.
Keep the block to one line and put the work in the method it calls.

The methods are one line each, because you have nothing left to work out:

```smalltalk
LaserGameCellElement >> mouseEnter: anEvent
	"The pointer came over me: my board now hovers me."

	self board ifNotNil: [ :board | board hoverCellElement: self ]
```

```st
LaserGameCellElement >> mouseLeave: anEvent
	"The pointer left me: my board hovers me no longer."

	self board ifNotNil: [ :board | board unhoverCellElement: self ]
```

```st
LaserGameCellElement >> mouseMove: anEvent
	"The pointer moved inside me, so I am the cell it is over."

	self board ifNotNil: [ :board | board hoverCellElement: self ]
```
> **Note.** The last two gain a second line in the next chapter, *Detecting mirror cell click regions*: `mouseMove:` records the hint the pointer position decides, and `mouseLeave:` takes it away again.

A cell reaches its board through its parent, and answers nil while it has none:

```smalltalk
LaserGameCellElement >> board
	"Answer the board element I am a cell of, or nil while I have no parent."

	^ self hasParent ifTrue: [ self parent ] ifFalse: [ nil ]
```

That nil is not an oversight to be tidied away later.
An element exists before it is added to anything, and you want a test that builds one on its own; `ifNotNil:` in the three handlers is what lets both happen without a special case.

Whenever a method can honestly answer "I have none", let it, and guard at the one place that cares.

## Click is a message Bloc already works out

`BlClickEvent` deserves a sentence of its own, because it is doing more than it looks.

A click is not a button press.
It is a press and a release *in the same place*.
If the player presses on one cell, drags the pointer off it and lets go somewhere else, that is not a click on either cell and must do nothing.

Tracking that by hand would mean we handle the press, store which cell it landed in, handle the release, and compare the two.

Bloc sends `BlClickEvent` only when the press and the release both land on the same element.
The rule is already written, so the game keeps the behaviour and we never write the bookkeeping:

```st
LaserGameCellElement >> click: anEvent
	"A click landed on me: a press and a release in the same cell, which Bloc decides."

	self board ifNotNil: [ :board | board clickCellElement: self ]
```
> **Note.** *Click and rotate a cell* replaces this body: once the click regions exist, the cell acts on the click itself rather than only reporting it.

Look for this before you write event code.
The press-and-release pair, the double click, the drag, the enter and leave of an element — those are events Bloc sends, not states to track.
Code that tracks a state the framework already tracks is code that can disagree with the framework.

## The board remembers what the mouse is doing

The cells report; the board holds the answer, because the board is where the rest of the game will read it from.
Two instance variables, `hoveredCellElement` and `clickedCell`, and three methods that set them:

```st
LaserGameBoardElement >> hoverCellElement: aCellElement
	"Remember that the pointer is over aCellElement. A cell tells me this when the pointer
	enters it and while it moves inside it."

	hoveredCellElement := aCellElement
```
> **Note.** *Clean up left-over hints* rewrites this method, so that the cell the pointer leaves behind loses its hint here.

```smalltalk
LaserGameBoardElement >> unhoverCellElement: aCellElement
	"Forget the pointer position, but only when aCellElement is the cell I hover. Moving from
	one cell to the next can deliver the enter of the new cell before the leave of the old one."

	hoveredCellElement == aCellElement ifTrue: [ hoveredCellElement := nil ]
```

```smalltalk
LaserGameBoardElement >> clickCellElement: aCellElement
	"Record the cell of aCellElement as the one just clicked. A cell tells me this when a click
	lands on it, that is when a press and a release fall in the same cell."

	clickedCell := aCellElement cell
```

The guard in `unhoverCellElement:` is the one piece of event handling in this chapter that needs care, and you should understand it rather than copy it.

Moving the pointer from one cell to the next produces two events: a leave on the old cell and an enter on the new one.
Nothing promises which arrives first.
Write the obvious version —

```st
	hoveredCellElement := nil
```

— and a leave arriving *after* the enter of the new cell throws away a hover that had just been set correctly.
The board would forget where the pointer is at every cell boundary, which on the screen looks like hints that flicker, and in a test looks like nothing at all, because a test that enters one cell and leaves it gets the right answer.

So the rule is: a cell may only clear the hover if it is the cell that holds it.
`==` asks for identity — the same object, not an equal one — which is exactly the question here.

Three accessors answer what the board knows:

```smalltalk
LaserGameBoardElement >> hoveredCellElement
	"Answer the cell element the pointer is over, or nil when the pointer is off the board."

	^ hoveredCellElement
```

```smalltalk
LaserGameBoardElement >> hoveredCell
	"Answer the cell the pointer is over, or nil when the pointer is off the board. No arithmetic
	is needed: the cell element under the pointer knows which cell it shows."

	^ hoveredCellElement ifNotNil: [ :element | element cell ]
```

```smalltalk
LaserGameBoardElement >> clickedCell
	"Answer the cell of the last click, or nil while no cell has been clicked. Nothing acts on the
	click yet: the click regions decide what a click does from *Determine Push Regions* on."

	^ clickedCell
```

Nothing acts on `clickedCell` yet, and that is deliberate.
In this chapter we deliver the events and record them, and stop there.
Deciding what a click *does* needs the push and rotate regions, which are the next few chapters.
Splitting the work that way means we can test every step of it on its own.

## Tests: send real events

Six tests, and they do not call `mouseEnter:` and friends directly.
We send the events instead:

```smalltalk
LaserGameCellElementTestCase >> testEnteringACellElementMakesItTheHoveredCell
	"The pointer entering a cell element is enough for the board to know which cell it is over."

	| element |
	element := board cellElementAt: 2 @ 3.
	element dispatchEvent: BlMouseEnterEvent new.
	self assert: board hoveredCellElement identicalTo: element.
	self assert: board hoveredCell identicalTo: (board grid at: 2 @ 3)
```

`dispatchEvent:` hands an element an event as though the mouse had produced it, and it works on an element that is not in any window.

That single message is what makes mouse handling testable: your test covers the handler, the block, the method it calls, and the board's reply, without a space, a window or a pointer.
Prefer it over calling the handler method yourself — a handler installed on the wrong event class is a real bug, and only the dispatch catches it.

```smalltalk
LaserGameCellElementTestCase >> testLeavingTheHoveredCellElementClearsTheHover
	"The pointer leaving the cell it hovers leaves the board hovering nothing."

	| element |
	element := board cellElementAt: 2 @ 3.
	element dispatchEvent: BlMouseEnterEvent new.
	element dispatchEvent: BlMouseLeaveEvent new.
	self assert: board hoveredCellElement isNil.
	self assert: board hoveredCell isNil
```

Then the awkward case, which gets a test of its own because it is the only thing here that you can write the obvious way and get wrong:

```smalltalk
LaserGameCellElementTestCase >> testLeavingACellElementThatIsNotHoveredKeepsTheHover
	"Moving from one cell to the next can deliver the enter of the new cell before the leave of
	the old one, so a leave only clears the hover when it comes from the cell that holds it."

	| left entered |
	left := board cellElementAt: 1 @ 1.
	entered := board cellElementAt: 2 @ 1.
	left dispatchEvent: BlMouseEnterEvent new.
	entered dispatchEvent: BlMouseEnterEvent new.
	left dispatchEvent: BlMouseLeaveEvent new.
	self assert: board hoveredCellElement identicalTo: entered
```

Read the three dispatches: enter the old cell, enter the new one, *then* leave the old one.
That order is the one the obvious version gets wrong, and writing it down in a test is how the guard survives the next person who reads `unhoverCellElement:` and thinks the `ifTrue:` is redundant.

Whenever you add a guard against an order of events, add the test that puts the events in that order.
A guard without such a test is a comment.

```smalltalk
LaserGameCellElementTestCase >> testMovingOverACellElementMakesItTheHoveredCell
	"A mouse move over a cell answers which cell the pointer is over. Bloc sends it to the cell
	itself, so the board learns it from the cell."

	| element |
	element := board cellElementAt: 4 @ 2.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 10 @ 10;
			 yourself).
	self assert: board hoveredCellElement identicalTo: element
```

```smalltalk
LaserGameCellElementTestCase >> testClickingACellElementRecordsItsCell
	"A click reaches the cell element under the pointer, and the board records the cell that was
	clicked. BlClickEvent is what checks that the press and the release fell in the same cell."

	| element |
	element := board cellElementAt: 3 @ 5.
	element dispatchEvent: (BlClickEvent new
			 position: 25 @ 25;
			 yourself).
	self assert: board clickedCell identicalTo: (board grid at: 3 @ 5)
```

The move and the click events carry a `position:`, because the handlers will read it in a later chapter; the enter and the leave do not need one.
And we write one test for the state before anything happens at all:

```smalltalk
LaserGameBoardElementTestCase >> testANewBoardHoversNothingAndHasNoClick
	"A board that no pointer has visited yet hovers no cell and holds no click."

	| board |
	board := LaserGameBoardElement on: GridExample demoGrid.
	self assert: board hoveredCellElement isNil.
	self assert: board hoveredCell isNil.
	self assert: board clickedCell isNil
```

A test of the initial state looks too easy to be worth writing.
Write it anyway: it is the test that fails when somebody gives an instance variable a default you did not want.

## Checking it

Open the game, move the pointer over the board, and ask the board what it sees:

```smalltalk
| element |
element := LaserGameElement openExample.
element board hoveredCell
```

Evaluate the second line again with the pointer in different places and you see the answer follow it — `a MirrorCell`, `a BlankCell`, `a TargetCell` — and it is nil as soon as the pointer leaves the board.
Click a cell and `element board clickedCell` is that cell.

Nothing on the screen moves yet.
In this chapter we delivered the events; the next one lets a cell work out what the pointer is asking for.

# Detecting mirror cell click regions

The events arrive, and the regions can classify a point.
In this chapter we join the two: while the pointer moves over the board, the cell under it works out which of its regions the pointer is in.

The renderer answers the region, the cell element keeps the answer, and only a mirror answers at all — which is the first time the drawing side of the game has an opinion about the model.

That answer will become the arrow the player sees, but not yet.
Here we only compute it and keep it, and the chapter is about *where* the question is asked.

## Ask the renderer, not the cell

A click only ever acts on a mirror.
Blank cells and the target do nothing, so only a mirror has a hint to offer.
The obvious way to say that is a test on the class of the cell:

```st
	cell class = MirrorCell ifTrue: [ ... ]
```

Resist it.
We ask every renderer the same question instead, and the answer differs because the renderers differ:

```smalltalk
CellRenderer >> hintRegionAt: aPoint
	"Answer the click region whose hint applies at aPoint, in the coordinates of my cell, or nil
	when my cell offers no hint at all. Every renderer is asked, and all but the mirror answer
	nothing: a click acts on mirrors only."

	^ nil
```

```st
MirrorCellRenderer >> hintRegionAt: aPoint
	"Answer the click region aPoint falls in: a mirror reacts to a click, and which of its two
	actions is meant depends on where in the cell the pointer is."

	^ CellClickRegion clickRegionForPoint: aPoint
```
> **Note.** *Determine push regions* rewrites the mirror's version: a region is asked what hint applies at the point, and the inside region answers one of its four push regions rather than itself.

That is the same move as the click regions two chapters ago, from the other side.
There, a question with three answers became three classes.
Here, a question with two answers becomes a method on the superclass and an override on the one subclass that has something to say.

Two things come out of writing it this way.
We have no list of cell kinds anywhere to keep in step with the cell hierarchy, and a renderer added later answers `nil` without being told to.

And the `nil` in the superclass is not a placeholder: "I offer no hint" is a real answer, and the caller already has to handle it, because the pointer is off the board most of the time anyway.

Note also what the renderer does *not* do.
It is asked a question and it answers a value.
It does not draw anything, it does not change the cell, and it does not remember being asked.

A method that answers you can test with one assertion; a method that acts has to be tested by looking at what it did.
Given the choice, write the question.

## The element keeps the answer

We have the cell element ask its renderer, and hold what comes back:

```st
LaserGameCellElement >> showPositionHintAt: aPoint
	"Keep the hint my renderer answers for aPoint, which is in my own coordinates. My renderer
	decides: a mirror answers the region the point falls in, every other cell answers nothing."

	hintRegion := self renderer hintRegionAt: aPoint
```

```st
LaserGameCellElement >> clearPositionHint
	"Forget my hint: the pointer is no longer in me."

	hintRegion := nil
```
> **Note.** Both grow in *Drawing push hints on the game board*, which is where the hint becomes an arrow on the screen: the first builds the arrow when the region changes, and the second takes it away again.

```smalltalk
LaserGameCellElement >> hintRegion
	"Answer the click region the pointer is in, or nil when the pointer is not in me or my cell
	offers no hint. The arrow the player sees is drawn from this."

	^ hintRegion
```

And we give the two handlers from the last chapter their second line:

```smalltalk
LaserGameCellElement >> mouseMove: anEvent
	"The pointer moved inside me, so I am the cell it is over, and the point it carries decides
	which hint I show."

	self board ifNotNil: [ :board | board hoverCellElement: self ].
	self showPositionHintAt: anEvent localPosition
```

```smalltalk
LaserGameCellElement >> mouseLeave: anEvent
	"The pointer left me: my board hovers me no longer, and my hint goes with it."

	self board ifNotNil: [ :board | board unhoverCellElement: self ].
	self clearPositionHint
```

`anEvent localPosition` is the point of the event in the coordinates of the element that is handling it.
Not the screen, not the window, not the board: this cell, with `0@0` at its own top left corner.
That is why `hintRegionAt:` can hand the point straight to the regions, which we defined against a rectangle starting at `0@0` as well.

Two things in the same coordinate system meet without arithmetic.
When a geometry calculation of yours starts collecting terms to subtract, the thing to question is not the arithmetic but the choice of coordinate system that made it necessary.

## Tests

We check that the mirror renderer answers a region for a point of its cell:

```st
MirrorCellRendererTestCase >> testAMirrorAnswersTheClickRegionOfAPoint
	"A mirror is the only cell a click acts on, so it is the only renderer that answers a hint
	region. The point is in cell coordinates, so the regions classify it directly."

	| renderer |
	renderer := self rendererLeaning: #left.
	self
		assert: (renderer hintRegionAt: CellClickRegionInside regionRectangle center)
		equals: CellClickRegionInside.
	self
		assert: (renderer hintRegionAt: CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionOutside.
	self assert: (renderer hintRegionAt: 0 @ 0) equals: CellClickRegionIgnore
```
> **Note.** *Determine push regions* replaces this test with `testAMirrorAnswersThePushRegionOfAPointInsideIt`, which expects a push region in the middle of the cell, because that is what a mirror answers once the inside region refines its hint.

Then we give the claim the design rests on a test of its own, which is worth doing whenever your design rests on a claim:

```st
CellRendererTestCase >> testOnlyAMirrorAnswersAHintRegion
	"Every renderer is asked for a hint region, and all but the mirror answer nothing: that is the
	whole of the design, and it lives in the hierarchy rather than in a conditional."

	| grid point |
	grid := GridExample demoGrid.
	point := CellClickRegionInside regionRectangle center.
	self
		assert: ((CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 4 @ 1) grid: grid)
				 hintRegionAt: point)
		equals: CellClickRegionInside
```
> **Note.** The last expectation becomes `CellClickRegionPushNorth` in *Determine push regions*.
> What the test claims does not change.

One point, three renderers, and the assertions say which ones are silent.
A test like this is cheap and it keeps the override honest: if the `nil` ever moved to a conditional in the caller, this test would still pass, and that is a sign it should be read alongside the next one.

Then we do the same thing through a real event, which is what ties the two halves of the chapter together:

```st
LaserGameCellElementTestCase >> testMovingInsideAMirrorCellRecordsItsHintRegion
	"A mouse move carries a point, and the cell keeps the region that point falls in."

	| board element |
	board := LaserGameBoardElement on: GridExample demoGrid.
	element := board cellElementAt: 4 @ 1.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionInside.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionIgnore
```
> **Note.** Here too *Determine push regions* moves the first expectation to `CellClickRegionPushNorth`.

Notice that the test sets `position:` and reads `hintRegion`, with the handler, the renderer, and the regions all in between.
With that we cover the whole chain in one test.
The unit tests above pin down each link, and this one pins down that they are actually connected — which is the bug the per-link tests cannot catch.

```st
LaserGameCellElementTestCase >> testMovingOverACellThatIsNotAMirrorRecordsNoHint
	"Blank and target cells answer no hint region, so moving over them records nothing."

	| board |
	board := LaserGameBoardElement on: GridExample demoGrid.
	#( 1 5 ) do: [ :column |
		| element |
		element := board cellElementAt: column @ 1.
		element dispatchEvent: (BlMouseMoveEvent new
				 position: CellClickRegionInside regionRectangle center;
				 yourself).
		self assert: element hintRegion isNil ]
```
> **Note.** *Drawing push hints on the game board* adds two assertions here, for the arrow those cells must not draw.

```smalltalk
LaserGameCellElementTestCase >> testLeavingACellClearsItsHintRegion
	"The pointer leaving a cell takes its hint with it, so no cell keeps a hint the pointer is
	no longer in."

	| element |
	element := board cellElementAt: 4 @ 1.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	element dispatchEvent: BlMouseLeaveEvent new.
	self assert: element hintRegion isNil
```

That last test is the one that matters most, and it is about cleaning up.
A hint is state, and state that is set on the way in has to be unset on the way out.

Every time you add a variable that a mouse event sets, write the test that the opposite event clears it; left-over hints are the subject of a whole chapter later on, and this is the first guard against them.

## Checking it

Open the game and ask the hovered cell what it has:

```smalltalk
| element |
element := LaserGameElement openExample.
element board hoveredCellElement hintRegion
```

Evaluate the last line with the pointer near the middle of a mirror and you get `CellClickRegionInside`; near the edge of the same cell, `CellClickRegionOutside`; in the four-pixel margin, `CellClickRegionIgnore`.
Over a blank or target cell it answers nil, and `hoveredCellElement` itself is nil as soon as the pointer leaves the board.

We have drawn nothing yet.
The arrow that will make this hint visible needs shapes to draw it with, which is the next chapter.

# Creating custom shapes

A cell can say which of its regions the pointer is in.
To turn that answer into something the player can see, the game needs pictures: an arrow per push direction, and a cross hair to mark the point the pointer is at.

We write each shape as a class-side list of points, scale it from one set of numbers to any cell size, and meet the Bloc trap that catches everybody once: a fresh element has no extent yet.

In this chapter we build them.
It is the first place in the book where we draw something that is not a rectangle, and the lesson is how a shape is described in Bloc — as numbers, not as pixels.

## An arrow is seven points

Draw an arrow on squared paper and you need seven corners: the tip, the two barbs, and the four corners of the shaft.
Write them down in the order you would walk them, and that list is the shape:

```smalltalk
LaserGameShapes class >> northArrowPoints
	"Answer the outline of an arrow that points north, as seven vertices of a closed polygon. The
	numbers are written at the size the arrow was drawn at, a little over 260 pixels; every caller
	scales them to the size it needs."

	^ { 100 @ 0. 200 @ 110. 120 @ 110. 120 @ 260. 80 @ 260. 80 @ 110. 0 @ 110 }
```

```smalltalk
LaserGameShapes class >> eastArrowPoints
	"Answer the outline of an arrow that points east, as seven vertices of a closed polygon."

	^ { 0 @ 80. 150 @ 80. 150 @ 0. 260 @ 100. 150 @ 200. 150 @ 120. 0 @ 120 }
```

```smalltalk
LaserGameShapes class >> southArrowPoints
	"Answer the outline of an arrow that points south, as seven vertices of a closed polygon."

	^ { 100 @ 260. 0 @ 150. 80 @ 150. 80 @ 0. 120 @ 0. 120 @ 150. 200 @ 150 }
```

```smalltalk
LaserGameShapes class >> westArrowPoints
	"Answer the outline of an arrow that points west, as seven vertices of a closed polygon."

	^ { 260 @ 80. 110 @ 80. 110 @ 0. 0 @ 100. 110 @ 200. 110 @ 120. 260 @ 120 }
```

Read the north one against a sheet of paper: start at the tip `100@0`, down to the right barb `200@110`, in to the shoulder `120@110`, down the right side of the shaft to `120@260`, across the foot to `80@260`, back up the left side to `80@110`, out to the left barb `0@110`, and the polygon closes itself back to the tip.

In Bloc, `y` grows downwards, so `0` is the top of the shape and `260` the bottom — which is why a north arrow has its tip at `y = 0`.

`{ ...
}` with full stops between the items is an array built when the method runs — a brace array.
It is the right notation here because `100 @ 0` is an expression, not a literal; `#( ...
)` would only accept literals.

These four methods are the whole of the drawing, and we need no picture file anywhere in this game.

## Why these are class-side methods

`LaserGameShapes` has no instance variables and is never instantiated.
Every method on it is on the class side, and we use it by name: `LaserGameShapes northArrowPoints`.

A class used this way is the Pharo answer to a library of functions.
It gives the numbers a name, a place, a protocol in the browser, and a test case of their own, and it costs nothing — no object to create, no state to keep consistent.

Reach for it whenever you have a family of related answers and nothing for an instance to remember.
(`CellClickRegion` and its subclasses, two chapters ago, are the same idea put to a different use: there the classes are *names that answer questions*, here one class is a *place where answers live*.)

## Any size, from one set of numbers

We write the arrays at around 260 pixels.
The hint arrow inside a cell is about a dozen pixels, and the checking snippet at the end of this chapter wants one of 120.
So the points have to be moved to the origin and stretched onto the rectangle the caller asks for:

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

Three lines, and each does one thing.
`Rectangle encompassing:` is the smallest rectangle containing all the points — the box the drawing actually fills.

`scale` is a point, one factor per axis, because the caller may ask for a rectangle of different proportions.
Then each point moves by the box origin so that the drawing starts at `0@0`, and multiplies by the scale.

Multiplying a point by a point multiplies the two axes separately, which is what makes this fit in one expression.
`asFloatPoint` keeps the result exact rather than rounding each vertex to a whole pixel; the renderer draws between pixels happily, and rounding here is what makes small shapes look lumpy.

The shape itself is an element whose *geometry* is that polygon:

```smalltalk
LaserGameShapes class >> arrowElementFromPoints: anArrayOfPoints ofExtent: anExtent
	"Answer an element of anExtent whose geometry is the outline anArrayOfPoints describes. The
	outline is a polygon, so Alexandrie fills it at whatever size it is given: the shape is a list
	of vertices and a colour, not a picture of pixels."

	^ BlElement new
		  geometry: (BlPolygonGeometry vertices:
					   (self pointsOf: anArrayOfPoints scaledToExtent: anExtent));
		  extent: anExtent;
		  background: self arrowColor;
		  yourself
```

This is worth dwelling on, because it is how all drawing in Bloc works.
An element has a *geometry*, which is its shape, and a *background*, which is what fills that shape.
Up to now every element we built has had the default geometry, a rectangle, so a background looked like a coloured box.

Give the same element a polygon geometry and the same background fills an arrow instead.
The border follows the geometry too, and so does hit testing: a click lands on the element only where the shape actually is.

So we write no drawing code in this game.
No "draw this shape" method, no pen, no canvas.
A shape is a value you hand to an element, and the renderer fills it — at any size, as sharply as the screen allows.

We write one accessor per direction, each naming its own array:

```smalltalk
LaserGameShapes class >> northArrowElementOfExtent: anExtent
	"Answer an arrow of anExtent that points north."

	^ self arrowElementFromPoints: self northArrowPoints ofExtent: anExtent
```

```smalltalk
LaserGameShapes class >> eastArrowElementOfExtent: anExtent
	"Answer an arrow of anExtent that points east."

	^ self arrowElementFromPoints: self eastArrowPoints ofExtent: anExtent
```

```smalltalk
LaserGameShapes class >> southArrowElementOfExtent: anExtent
	"Answer an arrow of anExtent that points south."

	^ self arrowElementFromPoints: self southArrowPoints ofExtent: anExtent
```

```smalltalk
LaserGameShapes class >> westArrowElementOfExtent: anExtent
	"Answer an arrow of anExtent that points west."

	^ self arrowElementFromPoints: self westArrowPoints ofExtent: anExtent
```

Two more of the same line, each naming its own array.
Four methods that differ by one word read worse than a loop over a dictionary, and they are far easier to live with: the browser finds `southArrowElementOfExtent:` by name, and a dictionary key is findable by nothing.

We make the colour a default, not a decision:

```smalltalk
LaserGameShapes class >> arrowColor
	"Answer the colour an arrow is painted in when nobody says otherwise. A caller that knows
	whether the move it hints at is allowed sets its own colour instead."

	^ Color gray
```

An arrow here does not know whether the move it hints at is legal — that is the board's business, two chapters on.
So the shape answers grey, and the caller that knows better overwrites the background of the element it was given.

Giving a value a sensible default and letting the informed caller override it keeps the knowledge in one place without making every caller pass an argument it may not have.

## Two things Bloc could have done, and why it does not

If you know Bloc you will object twice here.
Both objections are good, and the answer is the same both times.

**Why scale the points?
An element can be scaled.**
`anElement transformation` takes a matrix and `scaleBy:` is one line.

Because a polygon geometry does not follow the extent of its element.
Some geometries are written in normalized coordinates and stretch to whatever element they are given; `BlPolygonGeometry` is not one of them.
Its vertices are element-local and absolute.
One evaluation proves it to you:

```smalltalk
| element |
element := BlElement new
	geometry: (BlPolygonGeometry vertices: { 0@0. 100@0. 100@100 });
	extent: 10@10;
	yourself.
element geometryBounds   "(0.0@0.0) corner: (100.0@100.0)"
```

The element was asked for ten pixels and draws a hundred.
Somebody has to bring the numbers down to the size the caller wants, and for a polygon that somebody is you.

**Why four arrays?
One would do.**
Rotating the north arrow a quarter turn gives the east one exactly: map each `x @ y` to `260 - y @ x` and the seven points come out in the same cycle.

Because a transformation is a matrix applied when the element is *painted* and when a point is hit-tested against it.
It does not change the element's `extent`.

That is exactly what makes it the right tool for the whole game — a later chapter scales the entire finished window with one matrix, and none of the click code needs adjusting, because Bloc hit-tests through the same transformation it draws through.
And it is exactly what makes it the wrong tool for one arrow.

An arrow is a child of a cell, placed by the cell, and placement reads `extent`: an arrow authored at `200@260` and squeezed into a thirty-pixel cell by a matrix still reports itself as 200 by 260, and every method that positions it would have to divide the matrix back out.

Rotation is worse, because a quarter turn swaps the two numbers while the element keeps the extent it started with.

So the rule the game follows is: **a transformation scales a finished tree; arithmetic on vertices builds a shape at the size it was asked for.**
Inside `LaserGameShapes`, an element's extent is always the ink it actually covers.

That is what lets a cell place an arrow by asking for a rectangle, and it is a claim a test can check directly — `testEveryArrowFillsTheRectangleItIsGiven` takes all six arrows at three sizes and compares the bounds of the vertices with the extent asked for.

Keeping four arrays rather than deriving three of them is a smaller decision, and it is about reading.
Seven points per direction, written out, you can check against a sketch on paper.
A `rotatedBy:` would save twenty-one numbers and cost that check.

Where the game does derive one shape from another, it is because the shapes genuinely are each other: the clockwise rotate arrow, in *Using "Halt Once"*, is the anticlockwise one flipped, and writing it as a flip says so.

## The cross hair

The cross hair is two bars crossing at the centre.
That is not a polygon, so we build an element with two children:

```smalltalk
LaserGameShapes class >> crossHairElementOfExtent: anExtent
	"Answer a cross hair of anExtent: two bars crossing at the centre. The arms are a third of the
	shape and the bars a fifth of that, so the figure holds its proportions at any size. A cell
	puts one under the pointer while the pointer is over a hint of a mirror."

	| span thickness |
	span := (anExtent x min: anExtent y) // 3.
	thickness := (span // 5) max: 1.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: (self crossHairBarOfExtent: span @ thickness within: anExtent);
		  addChild: (self crossHairBarOfExtent: thickness @ span within: anExtent);
		  yourself
```

```smalltalk
LaserGameShapes class >> crossHairBarOfExtent: aBarExtent within: anExtent
	"Answer one bar of a cross hair, centred in a shape of anExtent."

	^ BlElement new
		  extent: aBarExtent;
		  position: (anExtent - aBarExtent) / 2;
		  background: self crossHairColor;
		  yourself
```

```smalltalk
LaserGameShapes class >> crossHairColor
	"Answer the colour of a cross hair."

	^ Color black
```

The two bars come from the same method we call twice, with its arguments the other way round: `span @ thickness` is the horizontal bar, `thickness @ span` the vertical one.

`position:` places a child at an offset inside its parent, and `(anExtent - aBarExtent) / 2` is the offset that centres anything in anything — half the space left over.

Note `(span // 5) max: 1`.
Integer division truncates, so a cross hair asked for at a tiny size would compute a thickness of zero and draw nothing at all.

`max: 1` is the floor that keeps the shape visible.
Any size you compute by dividing deserves that guard; a shape that silently disappears below some size is a bug that only shows up on somebody else's screen.

We make the holder itself transparent, which matters: it is a box the size of a cell with two visible bars in it, and anything behind it must show through.

## Tests

We test the two things that can be wrong about a shape: the numbers, and the size.

First, we check that the numbers are an arrow at all:

```smalltalk
LaserGameShapesTestCase >> testEachArrowIsSevenVerticesWideEnoughToBeAnArrow
	"Each of the four vertex arrays is seven points, an outline drawn as a closed polygon."

	{ LaserGameShapes northArrowPoints.
	LaserGameShapes eastArrowPoints.
	LaserGameShapes southArrowPoints.
	LaserGameShapes westArrowPoints } do: [ :points |
		self assert: points size equals: 7.
		points do: [ :each | self assert: each isPoint ] ]
```

Then we check that each arrow points where its name says, which is the mistake worth guarding against — two of twenty-eight numbers swapped gives an arrow pointing the wrong way, and the code still runs:

```smalltalk
LaserGameShapesTestCase >> testEachArrowHasOneTipAndItIsCentredOnTheOtherAxis
	"An arrow points where its name says: exactly one vertex reaches the far edge, and it sits in
	the middle of the other axis."

	| bounds |
	{ LaserGameShapes northArrowPoints -> [ :point :box | point y = box top and: [ point x = box center x ] ].
	LaserGameShapes southArrowPoints -> [ :point :box | point y = box bottom and: [ point x = box center x ] ].
	LaserGameShapes eastArrowPoints -> [ :point :box | point x = box right and: [ point y = box center y ] ].
	LaserGameShapes westArrowPoints -> [ :point :box | point x = box left and: [ point y = box center y ] ] }
		do: [ :each |
			bounds := Rectangle encompassing: each key.
			self
				assert: (each key select: [ :point | each value value: point value: bounds ]) size
				equals: 1 ]
```

That one is worth reading twice, because it shows a technique.
Each entry pairs an array with a block that says what "the tip" means for that direction, and the loop then runs the same three lines four times.

The alternative is four nearly identical tests.
When several of your cases differ only in one predicate, make the predicate the data.

Then we test the scaling, which is the only method here with arithmetic in it:

```smalltalk
LaserGameShapesTestCase >> testPointsScaleToFillTheRequestedExtent
	"Scaling maps the vertex array onto the rectangle the caller asks for, so the same array
	serves a 12 pixel hint and a 200 pixel drawing."

	{ 12 @ 12. 48 @ 48. 200 @ 120 } do: [ :extent |
		| scaled |
		scaled := LaserGameShapes
			          pointsOf: LaserGameShapes northArrowPoints
			          scaledToExtent: extent.
		self assert: scaled size equals: 7.
		self
			assert: (Rectangle encompassing: scaled)
			equals: (0 @ 0 corner: extent) ]
```

One assertion says it all: the box around the scaled points *is* the rectangle you asked for.
Not approximately, not a bit smaller — exactly.
The third size, `200 @ 120`, is not square on purpose: it is the one that catches a scale computed from one axis only.

```smalltalk
LaserGameShapesTestCase >> testAnArrowElementIsAPolygonOfTheSizeAsked
	"An arrow is an element with a polygon geometry, not a bitmap: its vertices are the scaled
	points, and it asks for the extent the caller named. The size is read from the resizer, since
	an element measures itself only in a layout pass."

	| extent element |
	extent := 40 @ 40.
	element := LaserGameShapes eastArrowElementOfExtent: extent.
	self assert: element geometry class equals: BlPolygonGeometry.
	self assert: (self requestedExtentOf: element) equals: extent.
	self
		assert: element geometry vertices asArray
		equals:
			(LaserGameShapes
				 pointsOf: LaserGameShapes eastArrowPoints
				 scaledToExtent: extent) asArray
```

```smalltalk
LaserGameShapesTestCase >> testEveryArrowElementUsesTheVerticesOfItsDirection
	"Each of the four accessors builds from its own vertex array."

	| extent |
	extent := 30 @ 30.
	{ (LaserGameShapes northArrowElementOfExtent: extent) -> LaserGameShapes northArrowPoints.
	(LaserGameShapes eastArrowElementOfExtent: extent) -> LaserGameShapes eastArrowPoints.
	(LaserGameShapes southArrowElementOfExtent: extent) -> LaserGameShapes southArrowPoints.
	(LaserGameShapes westArrowElementOfExtent: extent) -> LaserGameShapes westArrowPoints }
		do: [ :each |
			self
				assert: each key geometry vertices asArray
				equals: (LaserGameShapes pointsOf: each value scaledToExtent: extent) asArray ]
```

That second test looks pedantic until you consider the bug it catches: four accessors, each a copy of the last with two words changed, and one of them still naming the array it was copied from.

Nothing would fail, the cells would just hint the wrong way.
Whenever code is written by copying, write the test that the copies were finished.

```smalltalk
LaserGameShapesTestCase >> testACrossHairIsTwoBarsCrossingAtTheCentre
	"A cross hair is an element holding two bars, one wide and one tall, both centred in it."

	| extent element horizontal vertical |
	extent := 60 @ 60.
	element := LaserGameShapes crossHairElementOfExtent: extent.
	self assert: (self requestedExtentOf: element) equals: extent.
	self assert: element children size equals: 2.
	horizontal := element children detect: [ :each |
		              (self requestedExtentOf: each) x
		              > (self requestedExtentOf: each) y ].
	vertical := element children detect: [ :each |
		            (self requestedExtentOf: each) y
		            > (self requestedExtentOf: each) x ].
	element children do: [ :each |
		self
			assert:
				each constraints position + ((self requestedExtentOf: each) / 2)
			equals: extent / 2 ].
	self
		assert: (self requestedExtentOf: horizontal) x
		equals: (self requestedExtentOf: vertical) y
```

The last assertion is the "crossing" part: the long side of the horizontal bar equals the long side of the vertical one, so the figure is a cross and not a T.

```smalltalk
LaserGameShapesTestCase >> testShapesAreBuiltAtWhateverSizeIsAsked
	"Vertices scale, so no shape has a size of its own: every shape is built at the size the
	caller asks for, and a small one is as clean as a large one."

	{ 12 @ 12. 50 @ 50. 200 @ 200 } do: [ :extent |
		{ LaserGameShapes northArrowElementOfExtent: extent.
		LaserGameShapes crossHairElementOfExtent: extent } do: [ :element |
			self assert: (self requestedExtentOf: element) equals: extent ] ]
```

## The Bloc trap: a fresh element has no extent

Every one of those tests reads the size through a helper, and it is time we said why:

```smalltalk
LaserGameShapesTestCase >> requestedExtentOf: anElement
	"Answer the extent anElement was built with, read from its resizers. An element measures
	itself only in a layout pass, so its extent is zero until it is laid out."

	^ anElement constraints horizontal resizer size
	  @ anElement constraints vertical resizer size
```

`element extent: 40 @ 40` does not set a size.
It records a *request*.
The actual `extent` is computed when the element is laid out, which happens inside a space, and until then `element extent` answers `0 @ 0`.

So a test that builds an element and asserts `element extent equals: 40 @ 40` fails, and the failure reads as though the code were wrong when it is your test that asked the wrong object.
What was asked for lives in the constraints, as the resizer size, and that is what the helper reads.

This will come up again in every chapter where we test an element without opening a window.
Remember the shape of it: **before a layout pass, ask the constraints what was requested, not the element what it is.**

## Checking it

We open a space with every shape in it, at three sizes:

```smalltalk
| row space |
row := BlElement new
	layout: (BlLinearLayout horizontal cellSpacing: 10);
	constraintsDo: [ :c | c horizontal fitContent. c vertical fitContent ];
	padding: (BlInsets all: 10);
	background: Color white;
	yourself.
#( #northArrowElementOfExtent: #eastArrowElementOfExtent: #southArrowElementOfExtent: #westArrowElementOfExtent: ) do: [ :selector |
	#( 24 60 120 ) do: [ :size |
		row addChild: (LaserGameShapes perform: selector with: size @ size) ] ].
#( 24 60 120 ) do: [ :size |
	row addChild: (LaserGameShapes crossHairElementOfExtent: size @ size) ].
space := BlSpace new.
space root addChild: row.
space extent: 1500 @ 200.
space title: 'LaserGameShapes'.
space show
```

`perform: selector with:` sends a message whose name is held in a variable — handy in a checking snippet, and best avoided in the game itself, where a plain send can be found by the browser.

You get twelve arrows and three cross hairs, and the small ones are as clean as the large ones.
That is the payoff of describing a shape as numbers instead of pixels.

## Which arrow should a hint show?

We have one question left, and it is a game design question rather than a Bloc one.
A cell has an outside ring and an inside square.

A click in the ring rotates a mirror; a click near the middle pushes it.
But a push needs a *direction* — north, east, south, or west — and so far the inside region is one undivided square.

The answer is to divide it along its two diagonals, into four triangles, one per direction.
And we use the technique the click regions already gave us: a subclass per case, and a selector that asks them.

```smalltalk
CellClickRegionInside class >> pushRegionForPoint: aPoint
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
```

`CellClickRegionPushNorth`, `CellClickRegionPushEast`, `CellClickRegionPushSouth` and `CellClickRegionPushWest` are those four subclasses.
The next chapter gives each of them the geometry of its triangle, the arrow it hints with — one of the shapes this chapter just built — and the tests that no point of the inside region belongs to two of them or to none.

# Determine push regions

The inside region of a cell is divided into four push regions, and so far every one of them answers `true` to `containsPoint:`.
The hierarchy is in place; the geometry is not.

In this chapter we work out which of the four triangles a point falls in, check the answer with tests, and then put it to use: a mirror asked what hint applies at a point answers a push region.

One of our tests turns out to be wrong before the code is, and the detour that finds it is worth the two pages it takes.

The whole chapter is arithmetic with two straight lines in it, so we are careful about one thing before we start.
On the screen *x* grows to the right, as on paper, but *y* grows **downwards**.
A point with a smaller *y* is higher up.
Every "above" and "below" you read below means that.

## The rectangle the region occupies

The inside region is the cell inset by a margin on each side:

```smalltalk
CellClickRegionInside class >> regionRectangle
	"CellClickRegionInside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer insideRegionExtent.
	^outer insetBy: (delta // 2)
```

With the cell at 50 by 50 and the inside region 20 pixels smaller, the rectangle runs from `10@10` to `40@40`.
Those are the numbers *today*.
We write none of them down in this chapter, and that is deliberate: the two sizes in `CellRenderer` are the only place a number lives, and everything else asks.

That rule is easy to state and easy to break, because the first thing you want to do when working out a diagonal is to draw the rectangle on paper and read coordinates off it.
Draw it — then write what you learn as `rect left`, `rect center`, `rect bottomRight`, never as `10`, `25`, `40`.

## Two lines

Cut the region with its two diagonals and you get four triangles, one touching each edge.
Each triangle is one push direction, and the direction is *away from the edge the triangle touches*: a click near the left edge pushes the cell east, a click near the top edge pushes it south.

That is the one piece of game design in this chapter, and it is the reason the region names read the way they do.

Now the lines.
We take the diagonal from the top left corner of the cell to the bottom right one.
With `y = mx + b` and two of its points, `(0,0)` and `(50,50)`:

```text
m = (50 - 0) / (50 - 0) = 1
0 = 1(0) + b, so b = 0
y = x
```

and the other diagonal, from the top right corner to the bottom left one, through `(50,0)` and `(0,50)`:

```text
m = (0 - 50) / (50 - 0) = -1
0 = -1(50) + b, so b = 50
y = 50 - x
```

The first line is named for the direction it takes on the screen with *y* downwards: it heads *down* to the right.
The second heads *up*.
We make each one a method, which answers the *y* of its line at a given *x*:

```smalltalk
CellClickRegionInside class >> yForHeadingUpLineWith: x
	"Answer the y of the diagonal running from the top left corner of the cell to the bottom
	right one, at abscissa x. This one needs no cell size: the diagonal of a square is y = x."

	^x
```

```smalltalk
CellClickRegionInside class >> yForHeadingDownLineWith: x
	"Answer the y of the diagonal running from the top right corner of the cell to the bottom left
	one, at abscissa x. It is written against the cell rather than against the push region, so the
	diagonal passes through the corners at any cell size."

	^CellRenderer cellExtent x - x
```

Look at the second body: we send `CellRenderer cellExtent x - x`, not `50 - x`.
The `50` was true while the cell was 50 wide.
The send stays true.

This is the same `b` of the equation, asked for instead of remembered, and it is why a later chapter can double the cell size and these two lines still arrive exactly at its corners.

We add two more methods to place a point against a line:

```smalltalk
CellClickRegionInside class >> pointIsUnderHeadingUpLine: aPoint
	| realX realY lineY |
	realX := aPoint x.
	realY := aPoint y.
	lineY := self yForHeadingUpLineWith: realX.
	^realY < lineY
```

```smalltalk
CellClickRegionInside class >> pointIsUnderHeadingDownLine: aPoint

	| realX realY lineY |
	realX := aPoint x.
	realY := aPoint y.
	lineY := self yForHeadingDownLineWith: realX.
	^ realY < lineY
```

We compute where the line is at the *x* of the point, then compare the two *y* values.
Both ask `<`, never `<=`.
A point that sits exactly *on* a line is therefore not under it.

That looks like a detail.
It costs us a failing test two sections down, and it is worth remembering now: every comparison in a geometry method is also a decision about its boundary.

## The truth table

A point is over or under each of the two lines.
Two questions with two answers each make four combinations, and there are exactly four push regions.
So we give each region one row of a table:

| Line | Push North | Push East | Push South | Push West |
| --- | --- | --- | --- | --- |
| heading-up | Over | Over | Under | Under |
| heading-down | Over | Under | Under | Over |

Read a column and you get a class.
Push North is over both lines; with *y* growing downwards, "over both" is the triangle at the bottom of the cell, and a click at the bottom pushes the cell north, away from the edge it is nearest.

We ask the four with a `detect:`, the same shape as the three regions themselves:

```smalltalk
CellClickRegionInside class >> pushRegionForPoint: aPoint
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
```

and each class states its own row:

```smalltalk
CellClickRegionPushNorth class >> containsPoint: aPoint
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^(underHeadingDown not) and: [underHeadingUp not]
```

```smalltalk
CellClickRegionPushEast class >> containsPoint: aPoint
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown and: [underHeadingUp not]
```

```smalltalk
CellClickRegionPushSouth class >> containsPoint: aPoint
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown and: [underHeadingUp]
```

```smalltalk
CellClickRegionPushWest class >> containsPoint: aPoint
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown not and: [underHeadingUp]
```

Four methods, same two lines of setup, one differing expression.
You can hold the table and the code in view at the same time, and there is no `ifTrue:` anywhere deciding a direction.

That matters more than the four duplicated lines: a conditional that picks a class is a place a fifth case has to be added by hand, and these four are a place a fifth case adds itself.

The superclass answers the question by saying who should have answered it:

```smalltalk
CellClickRegionInside class >> containsPoint: aPoint
	"Answer whether aPoint falls in me. Each of my four push subclasses answers one line of the
	truth table of the two diagonals I hold, so none of them has a conditional in it."

	^ self subclassResponsibility
```

`subclassResponsibility` raises an error that names the class and the selector.
Compare that with the doesNotUnderstand you get from leaving the method out: both stop, but one of them tells the next reader that an abstract class was used where a concrete one was meant.

## When the test is the thing that is wrong

Here is the first test we write for the table — the obvious one.
We pick points of the region, say what each should answer, and assert it.
We pick the corners and the centre, because corners are where geometry goes wrong.

Run it, and you get a failure on the top right corner of the inside region, `40@10`: the test expects Push South, the code answers Push West.

Stop.
Something is wrong, and it is one of two things.
Either the code computes the wrong region, or your test expects the wrong one.
A failing test is not proof that the code is broken.
It is proof that the code and the test disagree.

So we work it out by hand, which we can do because all four methods are three lines.
At `x = 40`:

- the heading-up line is at `y = 40`. The point has `y = 10`, and `10 < 40`, so the point *is*
  under the heading-up line.
- the heading-down line is at `y = 50 - 40 = 10`. The point has `y = 10`, and `10 < 10` is false,
  so the point is *not* under the heading-down line.

Under the up line, over the down line: we read the table, and that column is Push West.
The code is right.
The expectation was a guess, made while looking at a drawing, about a point that sits exactly on one of the two lines — and the `<` in `pointIsUnderHeadingDownLine:` already decided that case.

Fix the test.
Then notice what your corrected expectation now records: not a measurement, but a decision.
A point on both lines, like the centre of the region, is under neither, so it pushes north.

Nothing in the game cares which way that one pixel goes; what matters is that the code and the test agree on it, and that the agreement is written down where the next reader will see it.

This happens often enough that we make it a habit.
When a test fails on a boundary value, suspect the test first.
When you then decide what the boundary should do, put *that* in the test, with a name that says it is a decision.

## Tests that hold at any cell size

A table of hand-picked points is a weak test, for two reasons.
Its numbers are the numbers of one cell size, so when you raise the cell size you break the test rather than the code.
And a handful of points leaves every pixel between them unchecked.

So the tests we write below derive the points they need from `regionRectangle`, and the first one checks every point there is.
The property it asserts is the one the four triangles exist for: they cover the inside region and they do not overlap.

```smalltalk
CellClickInsideRegionPushTestCase >> testEveryPointOfTheInsideRegionIsInExactlyOnePushRegion
	"The two diagonals cut the inside region into four triangles that cover it and do not
	overlap, so every point of it belongs to one push region and to no other. Checking a
	handful of points by hand would prove less: this walks the whole region, which is what
	makes the test hold at any cell size."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	rect left to: rect right do: [ :x |
		rect top to: rect bottom do: [ :y |
			| point matching |
			point := x @ y.
			matching := CellClickRegionInside subclasses select: [ :each |
				            each containsPoint: point ].
			self assert: matching size equals: 1 ] ]
```

`select:` keeps the regions that claim the point and `size equals: 1` is the whole assertion.
Exactly one claimant means both halves at once: at least one, so the four cover the region; at most one, so they do not overlap.
You get nine hundred assertions out of six lines, and not a coordinate among them.

We write that test for a rule rather than for a case, because the loop is what makes it possible.

"Every point belongs to one region" is a sentence about the design.
Asserting it over the whole region is a `to:do:` away, and it will catch a bad `<` in a line method that no table of nine points would meet.

Our second test states the game design decision, which no assertion on a corner can say plainly:

```smalltalk
CellClickInsideRegionPushTestCase >> testThePushRegionIsTheOneOfTheEdgeThePointIsNearest
	"A point near an edge of the inside region pushes away from that edge: near the left edge the
	cell is pushed east, near the top edge it is pushed south. That is why the region names read
	the way they do."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	{ (rect leftCenter + (1 @ 0) -> CellClickRegionPushEast).
	(rect rightCenter - (1 @ 0) -> CellClickRegionPushWest).
	(rect topCenter + (0 @ 1) -> CellClickRegionPushSouth).
	(rect bottomCenter - (0 @ 1) -> CellClickRegionPushNorth) } do: [ :each |
		self
			assert: (CellClickRegionInside pushRegionForPoint: each key)
			equals: each value ]
```

A brace array of associations, walked with `do:`, is the right shape for a table of cases: you read the rows as rows, and adding one is adding a line.
Each point is the centre of an edge moved one pixel inwards, so each is unambiguously inside its triangle and nowhere near a line.

The third keeps the boundary decision we made in the last section:

```smalltalk
CellClickInsideRegionPushTestCase >> testAPointOnALineIsNotUnderIt
	"The first run of this test failed on a point that sits exactly on a line, and the fault was
	in the test, not in the code. Both line tests ask <, so a point on a line is not under it,
	and the truth table then sends the corner points the way the region names say."

	| rect onBoth onHeadingDown |
	rect := CellClickRegionInside regionRectangle.
	onBoth := rect center.
	onHeadingDown := rect topRight.
	self deny:
		(CellClickRegionInside pointIsUnderHeadingUpLine: onBoth).
	self deny:
		(CellClickRegionInside pointIsUnderHeadingDownLine: onBoth).
	self
		assert: (CellClickRegionInside pushRegionForPoint: onBoth)
		equals: CellClickRegionPushNorth.
	self deny:
		(CellClickRegionInside pointIsUnderHeadingDownLine: onHeadingDown).
	self assert:
		(CellClickRegionInside pointIsUnderHeadingUpLine: onHeadingDown).
	self
		assert: (CellClickRegionInside pushRegionForPoint: onHeadingDown)
		equals: CellClickRegionPushWest
```

It asserts the two line questions *and* the region they produce.
That is on purpose.
A test that only asserted the region would pass again if somebody changed both `<` signs to `<=` and the table along with them; this one says where the boundary is and what follows from it.

The fourth is the reason we can write the first three without numbers:

```smalltalk
CellClickInsideRegionPushTestCase >> testTheLinesRunThroughTheCornersOfTheInsideRegion
	"The two diagonals are written as equations of the cell, y = x and y = cellExtent x - x, and
	no number of the inside region appears in them. They still meet its corners, which is what
	makes the arithmetic hold at any cell size."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (CellClickRegionInside yForHeadingUpLineWith: rect left)
		equals: rect top.
	self
		assert: (CellClickRegionInside yForHeadingUpLineWith: rect right)
		equals: rect bottom.
	self
		assert: (CellClickRegionInside yForHeadingDownLineWith: rect left)
		equals: rect bottom.
	self
		assert: (CellClickRegionInside yForHeadingDownLineWith: rect right)
		equals: rect top
```

The two lines are equations of the *cell*; the region they cut is a different rectangle.
That they meet its four corners is a claim, and a claim your design rests on should be a test.

If the inside margin ever stopped being equal on all four sides, this is the test that would go red, and it would go red with a message about corners rather than about a hint arrow pointing the wrong way.

We keep the table of cases as well, in a method of its own so that we can run it at more than one size:

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

```smalltalk
CellClickInsideRegionPushTestCase >> testClicksInPushRegions
	"Run the table at the cell size of the package. The table lives in a method of its own, so the
	test that runs it at three other sizes can share it."

	self assertPushRegionTable
```

```smalltalk
CellClickInsideRegionPushTestCase >> testThePushRegionTableHoldsAtEveryCellSize
	"Run the same table at three cell sizes. Every row names a point of the rectangle a region
	answers, so no row goes stale when the cell grows. A table of pixel numbers would."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [ self assertPushRegionTable ] ]
```

A test method whose body is one send to an `assert...`
method is a pattern you should copy.

The assertion method is not a test — it has no `test` prefix, so the framework never runs it on its own — and that lets two tests share it: one at the real cell size, one inside the `withCellExtent:do:` helper that changes the size and puts it back.
The claim is written once and checked four times.

## Asking a region for its hint

Now we use it.
A mirror already answers `hintRegionAt:` with the region a point falls in, and the cell element keeps the answer.
What it does not do yet is refine it: `CellClickRegionInside` is not a hint, because there are four hints inside it.

The fix is the same move we made with the renderers two chapters ago.
We add a message every region answers, and let one subclass override it:

```smalltalk
CellClickRegion class >> hintRegionForPoint: aPoint
	"Answer the region whose hint applies at aPoint, which I already contain. I have nothing
	finer to say than my own name, so I answer myself; the inside region answers one of its four
	push regions."

	^ self
```

```smalltalk
CellClickRegionInside class >> hintRegionForPoint: aPoint
	"Answer the push region aPoint falls in. A click here pushes a cell, and which way it pushes
	is what the hint has to show, so the inside region is the one region that refines its answer."

	^ self pushRegionForPoint: aPoint
```

`^ self` in the superclass is the whole trick, and it is worth a second look because you can easily misread it as a stub.
A class answering itself says "my own name is the finest answer I have".

The ignore region means it permanently.
The inside region does not, so it says something better.
The caller asks one question and never finds out which kind of region it got.

The mirror renderer then reads as two questions in a row:

```smalltalk
MirrorCellRenderer >> hintRegionAt: aPoint
	"Answer the region whose hint applies at aPoint: a mirror reacts to a click, and which of its
	actions is meant depends on where in the cell the pointer is. The region that contains the
	point has the last word, so a point near the middle answers one of the four push regions.
	The point is already in the coordinates of my cell, since the click is delivered to the
	element of the cell it landed on."

	^ (CellClickRegion clickRegionForPoint: aPoint) hintRegionForPoint: aPoint
```

Which region contains the point, and what that region makes of the point.
Nothing else in the game changes — not the handlers, not the cell element, not the board.

A method that answered a coarse value now answers a fine one, and because every caller was already asking rather than testing the class of the answer, you have nothing to update.

The first test is the polymorphism itself: one message, every region answers, one of them refines.

```st
CellClickRegionTestCase >> testOnlyTheInsideRegionRefinesTheHintItAnswers
	"Every region is asked for its hint, and the inside region alone does something with it: it
	answers the push region of the point. The others answer themselves, having nothing finer to
	say yet."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (CellClickRegionOutside hintRegionForPoint: 
				 CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionOutside.
	self
		assert: (CellClickRegionIgnore hintRegionForPoint: 0 @ 0)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegionInside hintRegionForPoint: rect leftCenter + (1 @ 0))
		equals: CellClickRegionPushEast
```
> **Note.** *Determine rotate regions* gives the outside region a refinement of its own, and rewrites this test as `testTheInsideAndOutsideRegionsRefineTheHintTheyAnswer`.

The second asks a mirror about points of its cell, which is the path your mouse will take:

```st
MirrorCellRendererTestCase >> testAMirrorAnswersThePushRegionOfAPointInsideIt
	"A mirror asks the region of a point what hint applies there, so a point in the inside region
	answers a push region rather than the inside region itself."

	| renderer rect |
	renderer := self rendererLeaning: #left.
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (renderer hintRegionAt: rect leftCenter + (1 @ 0))
		equals: CellClickRegionPushEast.
	self
		assert: (renderer hintRegionAt: rect topCenter + (0 @ 1))
		equals: CellClickRegionPushSouth.
	self
		assert: (renderer hintRegionAt: CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionOutside.
	self assert: (renderer hintRegionAt: 0 @ 0) equals: CellClickRegionIgnore
```
> **Note.** Its third expectation becomes `CellClickRegionRotateClockwise` in *Determine rotate regions*, where a point of the outside region answers the direction the mirror turns.

It replaces `testAMirrorAnswersTheClickRegionOfAPoint`, which asserted the coarse answer.
Two tests of earlier chapters move with it, because the answer for a point in the middle of a mirror cell is now a push region:

```smalltalk
CellRendererTestCase >> testOnlyAMirrorAnswersAHintRegion
	"Every renderer is asked for a hint region, and all but the mirror answer nothing: that is the
	whole of the design, and it lives in the hierarchy rather than in a conditional. The mirror
	answers the push region of the point, since the middle of a cell is where a push is asked for."

	| point |
	point := CellClickRegionInside regionRectangle center.
	self
		assert: ((CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 4 @ 1) grid: grid)
				 hintRegionAt: point)
		equals: CellClickRegionPushNorth
```

```smalltalk
LaserGameCellElementTestCase >> testMovingInsideAMirrorCellRecordsItsHintRegion
	"A mouse move carries a point, and the cell keeps the region that point falls in. In the
	middle of the cell that is a push region, since the push regions divide the inside region
	between them."

	| element |
	element := board cellElementAt: 4 @ 1.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushNorth.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionIgnore
```

Two tests changed their expectation, and neither changed what it claims.
That is the sign of a test that was written about behaviour rather than about a value: "the mirror answers a hint and the others do not" is still the sentence, and only the hint got finer.

When a refinement forces you to rewrite what a test *claims*, the refinement has changed the design, and that is worth noticing before carrying on.

## Checking it

We need no window to watch a hint follow the pointer, because the renderer answers a value:

```smalltalk
| grid renderer rect |
grid := GridExample demoGrid.
renderer := CellRenderer rendererFor: (grid at: 4 @ 1) grid: grid.
rect := CellClickRegionInside regionRectangle.
{ rect leftCenter + (1 @ 0). rect topCenter + (0 @ 1). rect rightCenter - (1 @ 0).
  rect bottomCenter - (0 @ 1). rect center. 0 @ 0 } collect: [ :each |
	each -> (renderer hintRegionAt: each) ]
```

You get east, south, west, north, north, and the ignore region.
The same expression on the blank cell at `1@1` or the target at `5@1` answers `nil` six times.

The hint is still only a class.
The next chapter gives it a picture: the arrows we built two chapters ago, drawn inside the cell the pointer is over.

# Drawing push hints on the game board

The pointer moves inside a mirror cell, and the game knows which way that cell would be pushed.
In this chapter we show the player: the arrow of the push region appears in the cell under the pointer, and goes when the pointer does.

The region answers its own picture, the cell element places it from `hintArrowExtent` and `hintArrowOffset`, and the board shows at most one arrow at a time.

We have four things to settle before we draw a hint on a board:

- the arrow has to be the right size for a cell;
- the exact place in the cell it sits at has to be known;
- it has to appear over the correct cell;
- and an old arrow must not be left behind when a new one is shown.

Two of them we have already answered, with decisions we took for other reasons.
The arrows are polygons built at the size they are asked for, so size is a number to pass, not a problem to solve.
And "the correct cell" is the element the pointer is in, because Bloc delivered the event to it.

That is worth pausing on, because it is the return on the two design decisions we made in this section.
One element per cell, and shapes that scale to their extent.
We made neither with this chapter in mind, and between them they cross two items off the list.

## Asking the region for its picture

A region is asked for its picture the same way it is asked for anything else: one message, answered by every class, overridden by the ones that have something to show.

```st
CellClickRegion class >> hintElementOfExtent: anExtent
	"Answer an element drawing my hint at anExtent, or nil when I have no picture to show. Only
	the four push regions have one here; the inside and outside regions never answer this
	themselves, since each refines itself first, and the ignore region shows nothing."

	^ nil
```
> **Note.** The comment is rewritten in *Determine rotate regions*, where the two rotate regions answer a picture of their own.

```smalltalk
CellClickRegionPushNorth class >> hintElementOfExtent: anExtent
	"Answer the north arrow at anExtent. It is a polygon, so it is drawn at the size it is given."

	^ LaserGameShapes northArrowElementOfExtent: anExtent
```

```smalltalk
CellClickRegionPushEast class >> hintElementOfExtent: anExtent
	"Answer the east arrow at anExtent."

	^ LaserGameShapes eastArrowElementOfExtent: anExtent
```

```smalltalk
CellClickRegionPushSouth class >> hintElementOfExtent: anExtent
	"Answer the south arrow at anExtent."

	^ LaserGameShapes southArrowElementOfExtent: anExtent
```

```smalltalk
CellClickRegionPushWest class >> hintElementOfExtent: anExtent
	"Answer the west arrow at anExtent."

	^ LaserGameShapes westArrowElementOfExtent: anExtent
```

Four one-line methods, each naming a direction twice: once in the class and once in the shape.
That is not duplication to be factored out.

If we derived the shape from the class name — taking the last word of the class and building a selector out of it — we would turn a readable method into a trick, and the compiler would stop checking that the selector exists.

Notice also what the push region answers: an element, not a drawing.
No region in this game has a line of painting code in it.
A region is asked a question and hands back an object that knows how to appear.

## How big, and where

Two numbers, and we keep them with the other cell measurements rather than in the method that uses them:

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

The second one is the whole of "centre it": the cell has two pixels over the arrow, so one goes on each side.
Written as `^ 1` it would be the same answer today and wrong the moment the first method changed.
Written this way, `hintArrowExtent` is the only decision and the offset follows it.

We put both as class methods of `CellRenderer`, next to `cellExtent` and `insideRegionExtent`.
Keeping every measurement of a cell in one class is worth more than keeping each one near its use: when a later chapter raises the cell size, you have one place to look and nothing to search for.

## One arrow at a time

The last item on our list is the one that takes care.
A cell element holds the picture of the hint it holds, and we show a new one by taking the old one away:

```st
LaserGameCellElement >> updateHintElement
	"Show the picture of the hint I hold, and no other. The arrow is a child of mine, so the
	previous one goes when it is removed and no arrow is ever left behind. A region without a
	picture, such as the ignore margin, answers nothing and leaves me with no hint at all."

	hintElement ifNotNil: [ :each | self removeChild: each ].
	hintElement := hintRegion ifNotNil: [ :region |
		               region hintElementOfExtent: CellRenderer hintArrowExtent ].
	hintElement ifNotNil: [ :each |
		each position: CellRenderer hintArrowOffset.
		self addChild: each ]
```
> **Note.** This method grows twice later.
> *Communicate with arrow colours* gives the arrow a background, and *Better cursor management* adds the cross hair that is shown with it.

Read the three statements as remove, build, add.
The removal is unconditional and the build may answer nothing, so every case comes out right: no hint before and none now, a hint replaced by another, a hint replaced by nothing.

This is where the element tree earns its keep.
If we painted the arrow into a picture of the board, showing a new one would mean repainting the cell underneath first, and *that* is a whole class of bug: an arrow left on the board, a cell repainted a frame late, two arrows visible at once.

Here the arrow is a child.
Removing a child removes what it drew, because what it drew was never anywhere else.

Our two methods from *Detecting mirror cell click regions* now each end in `updateHintElement`:

```st
LaserGameCellElement >> showPositionHintAt: aPoint
	"Keep the hint my renderer answers for aPoint, which is in my own coordinates, and show it.
	My renderer decides: a mirror answers the region the point falls in, every other cell answers
	nothing. A move within the same region changes nothing, so the arrow is built once."

	| region |
	region := self renderer hintRegionAt: aPoint.
	region = hintRegion ifTrue: [ ^ self ].
	hintRegion := region.
	self updateHintElement
```
> **Note.** *Better cursor management* makes the early return update the cross hair, and *Push cells with the mouse* adds the line that keeps the point the hint was read at.

```st
LaserGameCellElement >> clearPositionHint
	"Forget my hint: the pointer is no longer in me, so the arrow goes too."

	hintRegion ifNil: [ ^ self ].
	hintRegion := nil.
	self updateHintElement
```
> **Note.** *Push cells with the mouse* adds the line that forgets that point as well.

Both start by comparing, and that guard is the one piece of performance thinking in the section.
A mouse move arrives for every pixel the pointer crosses — dozens of events while a player drifts across one triangle.

Without the comparison, each of them would remove a polygon and build an identical one.
With it, the work happens when the *answer* changes, which is what the player can see.

Write that guard as `region = hintRegion ifTrue: [ ^ self ]`, at the top, before you touch any state.
A method that begins by asking whether it has anything to do is easy to read and easy to trust.
The same method with the comparison buried in the middle, around the part that rebuilds, is neither.

```smalltalk
LaserGameCellElement >> hintElement
	"Answer the element drawing my hint, or nil when I show none."

	^ hintElement
```

`mouseLeave:` needs no change at all.
It already clears the hint, and clearing the hint now takes the arrow with it:

```smalltalk
LaserGameCellElement >> mouseLeave: anEvent
	"The pointer left me: my board hovers me no longer, and my hint goes with it."

	self board ifNotNil: [ :board | board unhoverCellElement: self ].
	self clearPositionHint
```

A chapter that adds a visible feature and changes no event handler is a sign the split we made earlier was right.
The handlers say what happened; `clearPositionHint` says what that means; `updateHintElement` says what it looks like.
Only the last one had to learn anything new.

## Tests

Our first test asks each region for a picture, and checks the arrow it gets by its vertices:

```st
CellClickRegionTestCase >> testOnlyAPushRegionAnswersAHintElement
	"Each push region answers an element built at the size asked for, and every other region
	answers nothing: the inside and outside regions refine themselves first, and the ignore
	region never has a picture."

	| extent |
	extent := 48 @ 48.
	self assert: (CellClickRegionOutside hintElementOfExtent: extent) isNil.
	self assert: (CellClickRegionIgnore hintElementOfExtent: extent) isNil.
	self assert: (CellClickRegionInside hintElementOfExtent: extent) isNil.
	{ (CellClickRegionPushNorth -> LaserGameShapes northArrowPoints).
	(CellClickRegionPushEast -> LaserGameShapes eastArrowPoints).
	(CellClickRegionPushSouth -> LaserGameShapes southArrowPoints).
	(CellClickRegionPushWest -> LaserGameShapes westArrowPoints) } do: [ :each |
		| element |
		element := each key hintElementOfExtent: extent.
		self
			assert: element geometry vertices
			equals: (LaserGameShapes pointsOf: each value scaledToExtent: extent) ]
```
> **Note.** *Determine rotate regions* adds the two rotate regions to the table and renames the test `testEachRegionWithAPictureAnswersTheArrowOfItsDirection`.

Asserting on `geometry vertices` is the move you copy whenever a test has to recognise a shape.
The alternative is to assert that the element is a `BlElement`, which proves nothing, or to compare pictures, which is slow and brittle.

The vertices are the shape, exactly, and the expected value is the same expression the production code used — which sounds circular but is not: the test is checking that the *north* region answers the *north* points, and that is the mistake worth catching.

Then we do the same thing through an event, which is how a player will reach it:

```smalltalk
LaserGameCellElementTestCase >> testMovingInsideAMirrorCellShowsTheArrowOfItsPushRegion
	"The cell adds the arrow of the hint as a child, a few pixels smaller than the cell and
	centred in it, and its vertices are the ones of the direction the pointer asks for."

	| element |
	element := board cellElementAt: 4 @ 1.
	self assert: element hintElement isNil.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: (element children includes: element hintElement).
	self
		assert: element hintElement geometry vertices
		equals: (LaserGameShapes
				 pointsOf: LaserGameShapes northArrowPoints
				 scaledToExtent: CellRenderer hintArrowExtent).
	self
		assert: element hintElement constraints position
		equals: CellRenderer hintArrowOffset
```

Three assertions, and they are the three items of the list we made at the top of the chapter: the arrow is a child of the right cell, it has the vertices of the right direction at the right size, and it sits at the right offset.

Note `constraints position` rather than `position`: the element has not been laid out, so what the test can read is what we asked for, exactly as in *Creating custom shapes*.

The fourth item needs a test of its own, and what we assert is a count:

```st
LaserGameCellElementTestCase >> testAMirrorCellShowsOneArrowAtATime
	"Old arrows must not clutter the board. The cell has one hint child, and moving to another
	push region replaces it."

	| board element rect childCount |
	board := LaserGameBoardElement on: GridExample demoGrid.
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	rect := CellClickRegionInside regionRectangle.
	{ (rect leftCenter + (1 @ 0) -> LaserGameShapes eastArrowPoints).
	(rect topCenter + (0 @ 1) -> LaserGameShapes southArrowPoints).
	(rect rightCenter - (1 @ 0) -> LaserGameShapes westArrowPoints) } do: [ :each |
		element dispatchEvent: (BlMouseMoveEvent new
				 position: each key;
				 yourself).
		self assert: element children size equals: childCount + 1.
		self
			assert: element hintElement geometry vertices
			equals: (LaserGameShapes
					 pointsOf: each value
					 scaledToExtent: CellRenderer hintArrowExtent) ]
```
> **Note.** *Better cursor management* counts two children per hint, since the cross hair comes with the arrow.

We read `childCount` before anything happens rather than writing a number.
A cell element already has children — the cell is drawn with them — and how many is not this test's business.
What this test claims is that a hint costs *one more*, three moves in a row.

That is the shape for any "it must not accumulate" test: take the count, do the thing repeatedly, assert the count went up by what one of them costs.
A test that asserted `equals: 1` would be asserting something it does not care about, and it would fail for a reason that has nothing to do with left-over arrows.

And the arrow has to go when the hint does, in both ways you can make that happen:

```smalltalk
LaserGameCellElementTestCase >> testTheArrowGoesWhenThePointerLeavesOrReachesARegionWithoutOne
	"A hint lasts as long as the pointer is in a region that has one. Leaving the cell takes the
	arrow with it, and so does moving out to the margin, where the ignore region has no picture."

	| element childCount |
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: element hintElement isNil.
	self assert: element children size equals: childCount.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	element dispatchEvent: BlMouseLeaveEvent new.
	self assert: element hintElement isNil.
	self assert: element children size equals: childCount
```

Two endings in one test, because they are one claim: a hint that is gone has no picture and no child.
Asserting the variable *and* the count matters — a method that sets `hintElement` to nil without removing the child would pass the first assertion and leave an arrow on the board.

Finally, we give the test for cells that are not mirrors the same two assertions:

```smalltalk
LaserGameCellElementTestCase >> testMovingOverACellThatIsNotAMirrorRecordsNoHint
	"Blank and target cells answer no hint region, so moving over them records nothing and draws
	nothing."

	#( 1 5 ) do: [ :column |
		| element childCount |
		element := board cellElementAt: column @ 1.
		childCount := element children size.
		element dispatchEvent: (BlMouseMoveEvent new
				 position: CellClickRegionInside regionRectangle center;
				 yourself).
		self assert: element hintRegion isNil.
		self assert: element hintElement isNil.
		self assert: element children size equals: childCount ]
```

"Nothing happens" is a claim too, and it is the one that quietly stops being true when a later chapter gives every cell a hint it should not have had.

## Checking it

```smalltalk
LaserGameElement openExample
```

Move the pointer around inside a mirror cell.
You get a grey arrow in it, pointing the way that cell would be pushed, and it changes as the pointer crosses a diagonal.
Move out to the rim of the cell, or off the cell entirely, and the arrow goes.
Blank cells and the target show nothing.

The arrow is grey because nothing has told it otherwise yet.
Whether the push it offers is even legal — a mirror cannot be pushed off the board, or into another mirror — is a question no part of the game asks so far.

The next chapter is about finding out *when* a method runs, which is the tool you need for that question.

# Stopping code that runs too often

The hint drawing we wrote in the last chapter works, and it is also the first code in this game that is hard to watch.
A mouse move arrives for every pixel the pointer crosses, so `showPositionHintAt:` and `updateHintElement` run dozens of times a second.

This chapter is a short detour about the tools we use for that, because sooner or later a hint will appear in the wrong place and you will want to stand inside the method while it happens.

It is three short sections: why `self halt` is no help here, what `haltOnce` does instead, and the better answer, which is to ask the objects rather than watch them run.

## Why `self halt` is no help here

`self halt` is the usual way to stop in a method.
Put it anywhere, run the code, and you get a debugger on that line with the whole stack and every variable in reach.

Put it in `updateHintElement` and the game becomes unusable.
The debugger opens; closing it lets the pointer move; the pointer moving runs the method again; the debugger opens again.
You cannot read a stack while it is being rebuilt under you, and a handful of pixels of pointer drift is enough to queue more halts than you can dismiss.

This is worth recognising as a category, not as a nuisance.
Code called by the framework — a mouse handler, a layout pass, a drawing pass, anything on a timer — runs at a rate you do not control.
A breakpoint in it does not stop the program once; it stops it continuously.

## `haltOnce`

Pharo has the answer on `Object`, beside `halt`:

```smalltalk
self haltOnce
```

It halts the first time it is reached, and then disarms itself.
The method runs at full speed afterwards, the game stays usable, and the debugger that opened is the only one you have to read.

Re-arm it when you want another look:

```smalltalk
Halt resetOnce
```

Three more are worth knowing, and you find all of them on `Object`:

```smalltalk
self haltOnCount: 20
```

stops when the line has been reached twenty times, which is how you reach the twentieth mouse move rather than the first one.
The first move of a drag is often the uninteresting one.

```smalltalk
self haltIf: [ hintRegion isNil ]
```

stops only when the condition holds.
This is the one that finds "it goes wrong when the pointer comes in from the left": you state the case as a block and ignore every other pass through the method.

```smalltalk
self halt: 'hint region changed to ', hintRegion printString
```

stops with a message in the title of the debugger, which is enough for you to tell apart two halts in the same method.

Each of them is one line, which you type into the method, use, and delete.
That last step is the one to be careful about.

A `halt` left in a method is not caught by the tests — the tests do not drive the screen, and a halt that is never reached changes nothing — so it survives until a player finds it.
Search the package for `halt` before you call a session finished.

## The better answer: ask instead of watch

Now compare that with how we actually checked the last four chapters.

`hintRegionAt:` answers a region.
`hintElementOfExtent:` answers an element.
`pushRegionForPoint:` answers a class.
Not one of them needed a debugger, because you can send a method that answers a value in a playground, or in a test, and look at its answer:

```smalltalk
| grid renderer |
grid := GridExample demoGrid.
renderer := CellRenderer rendererFor: (grid at: 4 @ 1) grid: grid.
renderer hintRegionAt: CellClickRegionInside regionRectangle center
```

That is the whole of "see what it does", and it runs when you ask it to rather than when the pointer moves.
We needed the debugger for exactly one method in this chain, `updateHintElement`, and that is the one method that acts instead of answering.

So the habit the chapter is really about is the one from *Detecting mirror cell click regions*, seen from the other end: **given the choice, write the question**.

Split a step that acts into a method that works out the answer and a method that applies it.
The first one you test; the second one is three lines and rarely wrong.
The alternative is a single long method that can only be inspected while it runs, and that is where `haltOnce` and an afternoon go.

Keep the tools anyway.
They are the right ones for a bug in code the framework calls, and this game has one of those waiting in *Clean up left-over hints*.

# Curved arrows for rotation

A click near the rim of a mirror cell will turn the mirror rather than push it, and a turn needs a picture of its own: an arrow bent round a circle, one for each direction.

In this chapter we build it, and it is the last shape work in the section.
The arrow is an arc built from a fixed number of corners, closed into a single outline, and the test asks a curve the kind of question a curve can answer.

The four straight arrows were seven points in an array.
A curve is not, and that is the whole problem of the chapter: `BlPolygonGeometry` joins points with straight lines, so we have to turn a circle into a list of corners before we can draw it.
Everything below follows from that one fact.

## The shape, in pieces

The arrow is a ring with a head on it.
Three decisions describe the ring — where its centre is, and the two radii it runs between — and we write each one as a method:

```smalltalk
LaserGameShapes class >> rotateArrowCenter
	"Answer the centre both arcs of the curved arrow turn about."

	^ 282 @ 240
```

```smalltalk
LaserGameShapes class >> rotateArrowOuterRadius
	"Answer the radius of the outer arc of the curved arrow."

	^ 200
```

```smalltalk
LaserGameShapes class >> rotateArrowInnerRadius
	"Answer the radius of the inner arc of the curved arrow."

	^ 160
```

The head is the south arrow we built in *Creating custom shapes* with its stem cut down to almost nothing, because the ring is the stem:

```smalltalk
LaserGameShapes class >> rotateArrowHeadPoints
	"Answer the arrow head of the curved arrow: the south arrow with almost no stem, since the ring
	is the stem, moved to where the ring ends. The two points in the middle, at the top of the
	stem, are where the ring begins, so the outline replaces them with the ends of the two arcs."

	^ { 100 @ 260. 40 @ 150. 80 @ 150. 80 @ 141. 120 @ 141. 120 @ 150. 160 @ 150 }
		  collect: [ :each | each + (2 @ 100) ]
```

Those numbers are in the 450 by 450 square all the shapes of this class are drawn in.
We never use them at that size — `pointsOf:scaledToExtent:` shrinks them to whatever a cell is — so think of the square as graph paper, not as a size.

The ring does not go all the way round.
It stops where the head sits, and the angle it stops at is not a number to type:

```smalltalk
LaserGameShapes class >> rotateArrowCutAngle
	"Answer where the ring of the curved arrow stops, in degrees measured anticlockwise from east:
	the angle of the line from the centre of the arcs to the top right corner of the 450 pixel
	square the arrow is drawn in. The ring is open there, which is where the head sits."

	| corner |
	corner := 450 @ 0 - self rotateArrowCenter.
	^ (corner y negated arcTan: corner x) radiansToDegrees
```

Read that method as a sentence: the ring is cut along the line from its centre to the top right corner of the square.
The angle is what the code needs, so the method computes the angle from the sentence rather than asking you to trust a number like `51.6`.

`arcTan:` with two arguments gives the angle of a vector, and the `y negated` is there because *y* grows downwards on the screen while angles are measured the ordinary way, anticlockwise from east.

That mismatch is worth writing down in a comment every single time it appears.
It is the single most common cause of a shape that comes out upside down.

## An arc made of corners

Now the one real decision of the chapter: how many corners do we give a quarter circle?

```smalltalk
LaserGameShapes class >> rotateArrowArcSteps
	"Answer how many segments an arc of the curved arrow is drawn with. A polygon has as many
	corners as it is given, and two dozen are enough for the largest cell the game uses."

	^ 24
```

There is no right answer, only a trade: more corners look rounder and cost more to draw.
Twenty-four is smooth at 120 pixels, which is larger than this game ever draws a cell, and we write it as a method rather than a literal so that the next person can try `48` in a playground and see.

With the count settled, we build an arc with a `collect:` over the steps:

```smalltalk
LaserGameShapes class >> arcPointsFromAngle: startDegrees toAngle: stopDegrees radius: aRadius
	"Answer the points of an arc of aRadius about my rotate arrow centre, running from
	startDegrees to stopDegrees. Angles are measured anticlockwise from east, and the sine is
	subtracted because y grows downwards."

	| center step |
	center := self rotateArrowCenter.
	step := stopDegrees - startDegrees / self rotateArrowArcSteps.
	^ (0 to: self rotateArrowArcSteps) collect: [ :each |
		  | angle |
		  angle := (startDegrees + (each * step)) degreesToRadians.
		  (center x + (aRadius * angle cos))
		  @ (center y - (aRadius * angle sin)) ]
```

`0 to: steps` is twenty-five points for twenty-four segments, which is what you want: both ends of the arc are included.
An off-by-one here shows up as a gap in the ring, so count the fence posts rather than the panels.

The method takes its start and stop as arguments and does not care which way round they are.
Pass the larger angle first and the step is negative and the arc runs backwards.

We use that in the next method, and it is the reason this one has no `abs` and no sorting in it: a general method that runs either way is simpler than a method that normalises its arguments.

## One closed outline

A polygon is a single loop of points.
So we walk the ring, the cut, and the head *once*, in order, ending where we started:

```smalltalk
LaserGameShapes class >> counterClockwiseArrowPoints
	"Answer the outline of the arrow that turns a mirror anticlockwise: the head, then the outer
	arc from the head round to the cut, the cut itself, and the inner arc back. The result is one
	closed outline, so it draws as a single polygon."

	| head |
	head := self rotateArrowHeadPoints.
	^ { head first. head second. head third }
	  , (self
			   arcPointsFromAngle: 180
			   toAngle: self rotateArrowCutAngle
			   radius: self rotateArrowOuterRadius)
	  , (self
			   arcPointsFromAngle: self rotateArrowCutAngle
			   toAngle: 180
			   radius: self rotateArrowInnerRadius)
	  , { head sixth. head seventh }
```

Trace it with a finger.
Three points down the tip of the head and out to its left corner; the outer arc from due west round to the cut; then straight back along the inner arc, from the cut to due west, which is the second arc with its angles swapped; and two points to climb the other side of the head.

We leave the two middle points of the head — the top of its stem — out deliberately, because the arcs arrive exactly where they were.

That last claim is what makes the shape closed rather than two separate drawings, and it holds because of one piece of arithmetic: the two radii are 200 and 160, and the stem of the head is 40 wide and sits where the ring ends.
A test below checks exactly that, and it is the test that would catch a change to any one of the three numbers.

The other direction costs one line:

```smalltalk
LaserGameShapes class >> clockwiseArrowPoints
	"Answer the outline of the arrow that turns a mirror clockwise: the other one flipped
	horizontally."

	^ self counterClockwiseArrowPoints collect: [ :each |
		  each x negated @ each y ]
```

Negate every *x* and you have the shape mirrored.
The points now have negative coordinates, and nothing cares: `pointsOf:scaledToExtent:` takes the bounding rectangle of whatever it is given and scales *that* into the extent asked for.
A shape in this class may be drawn anywhere in the plane, which is why mirroring is allowed to be this careless.

We build the two elements with the same method as the four straight arrows:

```smalltalk
LaserGameShapes class >> counterClockwiseArrowElementOfExtent: anExtent
	"Answer an element drawing the anticlockwise rotate arrow at anExtent."

	^ self
		  arrowElementFromPoints: self counterClockwiseArrowPoints
		  ofExtent: anExtent
```

```smalltalk
LaserGameShapes class >> clockwiseArrowElementOfExtent: anExtent
	"Answer an element drawing the clockwise rotate arrow at anExtent."

	^ self
		  arrowElementFromPoints: self clockwiseArrowPoints
		  ofExtent: anExtent
```

Six shapes now go through `arrowElementFromPoints:ofExtent:`, and the two hardest of them needed no new drawing code at all.
A shape in this game is an array of points, and everything that turns points into something on the screen we wrote once.

## Testing a curve

Here is the question this section of the chapter is really about: how do you unit-test a shape you can only recognise by eye?

Not by comparing pictures.
A test that renders the arrow and compares pixels fails when a font changes, when antialiasing changes, when the colour changes — it fails for every reason except the one you care about, and when it fails it tells you nothing about why.

We test the *properties* the shape is built from instead.
Every point of the outline is either a point of the head or a point of one of the two circles, and nothing else is allowed:

```smalltalk
LaserGameShapesTestCase >> testTheRotateArrowIsARingBetweenTwoCirclesWithAHeadOnIt
	"The curved arrow is two arcs about one centre, cut off by a line, with a straight arrow head
	on the end. Every point of the outline is therefore either a point of that head or a point of
	one of the two circles."

	| center head |
	center := LaserGameShapes rotateArrowCenter.
	head := LaserGameShapes rotateArrowHeadPoints.
	LaserGameShapes counterClockwiseArrowPoints do: [ :each |
		| radius |
		radius := (each - center) r.
		self assert: ((head includes: each) or: [
				 (radius closeTo: LaserGameShapes rotateArrowInnerRadius) or: [
					 radius closeTo: LaserGameShapes rotateArrowOuterRadius ] ]) ]
```

`(each - center) r` is the distance from the centre to the point — `r` is the length of a point read as a vector — and `closeTo:` compares floating point numbers with a tolerance instead of asking for exact equality.
Never write `=` between two computed floats: `cos` and `sin` of a round number of degrees are not round numbers, and the assertion would fail on the last decimal place.

Read what that test accepts and what it refuses.
A corner that drifts off both circles fails it.
A wrong angle, a wrong step count, a point left in from the stem of the head: all fail.

And it says nothing at all about how round the arrow looks, which is a property of the step count and belongs to your eyes.

The second test is the arithmetic that closes the outline:

```smalltalk
LaserGameShapesTestCase >> testTheRingOfTheRotateArrowIsAsWideAsTheStemOfItsHead
	"The ring between the two radii is exactly as wide as the stem of the arrow head, and the stem
	sits at the left end of the ring. That is what keeps the outline of the shape closed."

	| head ring |
	head := LaserGameShapes rotateArrowHeadPoints.
	ring := LaserGameShapes rotateArrowOuterRadius
	        - LaserGameShapes rotateArrowInnerRadius.
	self assert: ring equals: (head sixth x - head third x).
	self
		assert: LaserGameShapes rotateArrowCenter x
		        - LaserGameShapes rotateArrowOuterRadius
		equals: head third x.
	self
		assert: LaserGameShapes rotateArrowCenter x
		        - LaserGameShapes rotateArrowInnerRadius
		equals: head sixth x
```

Three assertions: the ring is as wide as the stem, and each of the two radii lands on the side of the stem it should.
Those are the relations that make four unrelated-looking numbers into one shape.

Write a test like this whenever one of your shapes depends on two numbers agreeing — it is the difference between "someone changed 160 and the arrow broke" and "someone changed 160 and a test said which other number had to change with it".

We test the mirror with one assertion per point:

```smalltalk
LaserGameShapesTestCase >> testTheClockwiseArrowIsTheCounterClockwiseOneMirrored
	"The clockwise arrow is the other one flipped horizontally, which is one line of code."

	| left right |
	left := LaserGameShapes counterClockwiseArrowPoints.
	right := LaserGameShapes clockwiseArrowPoints.
	self assert: right size equals: left size.
	left with: right do: [ :each :mirrored |
		self assert: mirrored x equals: each x negated.
		self assert: mirrored y equals: each y ]
```

`with:do:` walks two collections in step and fails loudly if they are not the same length, which the assertion above it has already checked for a better message.

And the arrows scale like every other shape in the class:

```smalltalk
LaserGameShapesTestCase >> testTheRotateArrowElementsArePolygonsOfTheSizeAsked
	"Like the four straight arrows, a rotate arrow is a polygon scaled into the extent asked for."

	{ (#counterClockwiseArrowElementOfExtent:
	 -> LaserGameShapes counterClockwiseArrowPoints).
	(#clockwiseArrowElementOfExtent: -> LaserGameShapes clockwiseArrowPoints) }
		do: [ :each |
			#( 30 48 120 ) do: [ :size |
				| element extent |
				extent := size @ size.
				element := LaserGameShapes perform: each key with: extent.
				self assert: (self requestedExtentOf: element) equals: extent.
				self
					assert: element geometry vertices
					equals:
					(LaserGameShapes pointsOf: each value scaledToExtent: extent) ] ]
```

`requestedExtentOf:` is the helper we wrote in *Creating custom shapes*, reading the size an element was asked for rather than the extent it has not been given yet.
Three sizes, two arrows, and the same two claims as the straight arrows: the element is the size it was asked for, and its vertices are the shape scaled into that size.

## Checking it

Four green tests are a good reason to believe the shape is built correctly, and no reason at all to believe it looks like an arrow.
For that, we put six of them in a window:

```smalltalk
| row space |
row := BlElement new
	       layout: (BlLinearLayout horizontal cellSpacing: 10);
	       constraintsDo: [ :c | c horizontal fitContent. c vertical fitContent ];
	       padding: (BlInsets all: 10);
	       background: Color white;
	       yourself.
#( #counterClockwiseArrowElementOfExtent: #clockwiseArrowElementOfExtent: ) do: [ :selector |
	#( 30 60 120 ) do: [ :size |
		row addChild: (LaserGameShapes perform: selector with: size @ size) ] ].
space := BlSpace new.
space root addChild: row.
space extent: 700 @ 200.
space title: 'Rotate arrows'.
space show
```

You get six curved arrows, three turning each way, every one clean at its own size.
Raise `rotateArrowArcSteps` to `48` and run it again, then drop it to `6`, and you can see what the number buys — which is the only way to choose it, and exactly why it is a method.

## The gallery wants to be a method

Read the snippet above beside the one at the end of *Creating custom shapes*.
They are the same loop twice: a row element, a list of selectors, a list of sizes, and `perform:with:`.

That is the second typing, and the second typing of a snippet is the moment to make it a method.
A playground script nobody can find again is worth less than a tab on the class that holds the shapes, and it costs one method either way.

Both lists become methods first, so that the gallery is nothing but a loop over them:

```smalltalk
LaserGameShapes class >> inspectionShapeExtents
	"Answer the sizes the Shapes tab draws every shape at. Three sizes are enough to show that a
	vertex array holds its proportions: the size of a hint, the size of a cell, and larger."

	^ #( 30 50 80 )
```

```smalltalk
LaserGameShapes class >> inspectionShapeSelectors
	"Answer the selectors the Shapes tab asks for one shape each, in the order it draws them: the
	four arrows a hint shows, the two rotate arrows, and the cross hair."

	^ #( #northArrowElementOfExtent: #eastArrowElementOfExtent:
	     #southArrowElementOfExtent: #westArrowElementOfExtent:
	     #clockwiseArrowElementOfExtent: #counterClockwiseArrowElementOfExtent:
	     #crossHairElementOfExtent: )
```

We list selectors rather than shapes, and that is what keeps the gallery honest.
The tab asks the class for its shapes the way a cell asks for them, through the same seven selectors, so a shape that is wrong in the game is wrong in the tab as well.

Both rotate arrows are on that list, which is why the gallery belongs to this chapter rather than to *Creating custom shapes*: the two shapes that most need looking at did not exist yet.

The gallery itself is one loop inside another, laying out a row per size:

```smalltalk
LaserGameShapes class >> inspectionGalleryElement
	"Answer one element holding every shape I can make, drawn once at each of
	#inspectionShapeExtents: one row per size, the shapes of #inspectionShapeSelectors left to
	right. Each shape is asked for the square it is given, so a row that holds its proportions is
	the proof that one vertex array serves every size."

	| gap canvas top width |
	gap := 10.
	canvas := BlElement new
		          background: Color white;
		          yourself.
	top := gap.
	width := gap.
	self inspectionShapeExtents do: [ :size |
			| left |
			left := gap.
			self inspectionShapeSelectors do: [ :selector |
					canvas addChild: ((self perform: selector with: size @ size)
							 position: left @ top;
							 yourself).
					left := left + size + gap ].
			width := width max: left.
			top := top + size + gap ].
	canvas extent: width @ top.
	^ canvas
```

`width max: left` is there because the rows are not the same length in pixels, and the canvas has to be as wide as the widest of them.
An element given no extent is not given a size by its children either, so a canvas that lays its children out by position has to state its own extent at the end.

The view is then two lines, because every decision was taken in the three methods above it:

```smalltalk
LaserGameShapes class >> inspectionShapes: aBuilder
	"Show every shape I can make, each one drawn at three sizes. I hold vertex arrays written at
	around 260 pixels and a scaling step, and nothing says whether that step is right until the
	same arrow is seen small and large side by side."

	<inspectorPresentationOrder: 1 title: 'Shapes'>
	^ aBuilder newMorph
		  morph: self inspectionGalleryElement asPreviewMorph;
		  yourself
```

`asPreviewMorph` wraps a Bloc element so that a Spec presenter can show it, and `aBuilder newMorph` is the presenter that takes it.
Those two sends are the whole of the glue between the two toolkits, and they are the reason the gallery is a separate method: everything above the glue can be tested without it.

Inspect `LaserGameShapes` — the class, not an instance, since the shapes are all class-side — and the *Shapes* tab holds twenty-one elements on a canvas 640 by 200: three sizes by seven shapes.

A view is a method, so it gets a test:

```smalltalk
LaserGameShapesTestCase >> testTheShapesTabDrawsEveryShapeAtEverySize
	"The Shapes tab is the claim of pointsOf:scaledToExtent: put on screen: one row per size, one
	shape per column, and every shape fills the square it was asked for. A vertex array written at
	260 pixels has to serve a 12 pixel hint and a 200 pixel drawing, and this is where a reader
	sees that it does."

	| gallery builder presenter |
	gallery := LaserGameShapes inspectionGalleryElement.
	self
		assert: gallery children size
		equals:
			LaserGameShapes inspectionShapeExtents size
			* LaserGameShapes inspectionShapeSelectors size.
	LaserGameShapes inspectionShapeExtents do: [ :size |
			self
				assert: (gallery children select: [ :each |
						 (self requestedExtentOf: each) = (size @ size) ]) size
				equals: LaserGameShapes inspectionShapeSelectors size ].
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	presenter := LaserGameShapes inspectionShapes: builder.
	self assert: presenter class equals: SpMorphPresenter
```

`requestedExtentOf:` is the helper of *The Bloc trap*, reading the size an element was asked for rather than the extent it has not been given yet.
The test counts the children, checks that each row got the square it asked for, and then says the one thing a headless test can say about a picture: that it was built.

> **A test of a picture tests what the picture was asked for.** Pixels need a window; sizes and children do not.

You still have to look at the tab to know the arrows are round.
What the test buys is that a shape dropped from the list, or a size that stopped being honoured, fails before you look.

Our shapes are finished.
The next chapter divides the rim of a cell between them.

# Determine rotate regions

A click in the inside region pushes a cell.
A click in the outside region turns a mirror, one way or the other, and in this chapter we decide which.

It is the same walk as the last three chapters, one ring further out: we divide the region, name the halves, and give each one a hint.
By the end of it a click anywhere on a mirror cell has a meaning, and a hint to go with it.

Doing the same walk twice is the point.
By the end of the chapter the whole of the rotate behaviour will be four short methods and a handful of tests, because we built every piece of machinery it needs for the push regions and had to tell none of it about this one.

## One line, two halves

We keep the division as simple as it is allowed to be: a horizontal line across the middle of the cell.
Above it the mirror turns clockwise, below it anticlockwise.
Which way the mirror leans makes no difference, exactly as it made none for the pushes.

```smalltalk
CellClickRegionRotateClockwise class >> containsPoint: aPoint
	"Answer whether aPoint is in the upper half of the cell. The line is half the height of the
	cell rather than a number of pixels, so it follows the cell size. A point exactly on the line
	is mine."

	^aPoint y <= (CellRenderer cellExtent y // 2)
```

```smalltalk
CellClickRegionRotateCounterClockwise class >> containsPoint: aPoint
	"Answer whether aPoint is in the lower half of the cell. My sister takes the line itself, so
	I ask for a strictly greater y, and the two of us cover the region without overlapping."

	^aPoint y > (CellRenderer cellExtent y // 2)
```

Two methods, one line each, and read them together: `<=` on one side and `>` on the other.
That is the boundary decision of *Determine push regions*, which we make deliberately this time — a point exactly on the line belongs to the upper half — and the pair of comparisons is what makes the two halves cover the region without overlapping.

Get into the habit of reading a pair of range checks as a pair.
`<=` with `>=` leaves a point in both halves; `<` with `>` leaves it in neither, and `detect:` then fails with an error rather than answering a region.

Exactly one of the two comparisons takes the boundary, and you state which one it is in a comment, because nothing in the code can say it.

The line is `CellRenderer cellExtent y // 2`, not `25`.
Half the height of the cell is the decision; 25 is what it happens to be today.

We ask which half a point is in with the counterpart of `pushRegionForPoint:`:

```smalltalk
CellClickRegionOutside class >> rotateRegionForPoint: aPoint
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
```

and the superclass says whose question `containsPoint:` is:

```smalltalk
CellClickRegionOutside class >> containsPoint: aPoint
	"Answer whether aPoint falls in me. My two subclasses split the region between them, so each
	of them answers it; I only say that the question belongs to them."

	^ self subclassResponsibility
```

## The hint

A region that can be clicked needs a picture, and a region that refines itself needs to say so.
Both messages already exist, so we write two one-line overrides.

```smalltalk
CellClickRegionOutside class >> hintRegionForPoint: aPoint
	"Answer the rotate region aPoint falls in. A click here turns a mirror, and which way it turns
	is what the hint has to show, so the outside region refines its answer just as the inside one
	does."

	^ self rotateRegionForPoint: aPoint
```

```smalltalk
CellClickRegionRotateClockwise class >> hintElementOfExtent: anExtent
	"Answer an element drawing the clockwise curved arrow at anExtent, at whatever size it is
	given."

	^ LaserGameShapes clockwiseArrowElementOfExtent: anExtent
```

```smalltalk
CellClickRegionRotateCounterClockwise class >> hintElementOfExtent: anExtent
	"Answer an element drawing the anticlockwise curved arrow at anExtent, at whatever size it is
	given."

	^ LaserGameShapes counterClockwiseArrowElementOfExtent: anExtent
```

And that is our chapter's feature finished.
Nothing else changes.
`updateHintElement` asks whatever region it holds for an element of the arrow size, and it has never known or cared which kind of region that is; the cell element, the handlers, and the board are untouched.

Curved arrows now appear on the rim of a mirror cell because two classes learned to answer a message the rest of the game was already sending.

That is what our two chapters of groundwork bought, and it is worth naming the property that did it: every one of those methods answers a value and none of them asks what it is talking to.
A design made of questions grows by adding answers.

The only existing method we change is a comment, on the superclass, now that six regions can answer a picture instead of four:

```smalltalk
CellClickRegion class >> hintElementOfExtent: anExtent
	"Answer an element drawing my hint at anExtent, or nil when I have no picture to show. The four
	push regions answer a straight arrow and the two rotate regions a curved one; the inside and
	outside regions never answer this themselves, since each refines itself first, and the ignore
	region shows nothing."

	^ nil
```

## Tests

We give the rotate regions the same four tests as the push regions, for the same reasons, and they are worth comparing side by side with *Determine push regions* — the shape of a test follows the shape of the thing it checks.

Every point of the region turns the mirror one way and not both:

```smalltalk
CellClickOutsideRegionRotateTestCase >> testEveryPointOfTheOutsideRegionIsInExactlyOneRotateRegion
	"The dividing line cuts the outside region into an upper and a lower half that cover it and do
	not overlap, so every point of it turns the mirror one way and not the other. This walks the
	whole region rather than sampling points of one cell size."

	| rect |
	rect := CellClickRegionOutside regionRectangle.
	rect left to: rect right do: [ :x |
		rect top to: rect bottom do: [ :y |
			| point matching |
			point := x @ y.
			matching := CellClickRegionOutside subclasses select: [ :each |
				            each containsPoint: point ].
			self assert: matching size equals: 1 ] ]
```

The boundary belongs to the upper half, and the test says so twice over — once on each class, and once through the method that picks between them:

```smalltalk
CellClickOutsideRegionRotateTestCase >> testAPointOnTheDividingLineTurnsTheMirrorClockwise
	"The dividing line sits at half the height of the cell, and a point on it counts as belonging
	to the upper half. The line is the cell's, not the region's, so it is written here as the
	cell says it."

	| onTheLine |
	onTheLine := CellClickRegionOutside regionRectangle left
	             @ (CellRenderer cellExtent y // 2).
	self assert: (CellClickRegionRotateClockwise containsPoint: onTheLine).
	self deny:
		(CellClickRegionRotateCounterClockwise containsPoint: onTheLine).
	self
		assert: (CellClickRegionOutside rotateRegionForPoint: onTheLine)
		equals: CellClickRegionRotateClockwise.
	self
		assert:
		(CellClickRegionOutside rotateRegionForPoint: onTheLine + (0 @ 1))
		equals: CellClickRegionRotateCounterClockwise
```

Note the point one pixel below the line, asserted to belong to the other half.
A boundary test that only checks the boundary itself passes just as happily when *both* comparisons take the line.
Check the pixel on each side of it; that is two assertions and it pins the decision down completely.

We keep the table of cases in its own method, so that we can run it at more than one cell size:

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

Fifteen rows, and they are not there for coverage — the walk over every point already has that.

They are there because the rim of a cell is a ring, and a ring has places you will want to look up: the four corners, the four edge centres, the inner rectangle, and the outer one.
A table of named points is documentation that fails when it stops being true.

Then the hint, which is two tests.
The outside region refines what it answers:

```smalltalk
CellClickOutsideRegionRotateTestCase >> testTheOutsideRegionRefinesTheHintToARotateRegion
	"The outside region has a hint of its own, and answers it the way the inside region does: not
	itself, but the region of the point, which here is the direction the mirror turns."

	| rect |
	rect := CellClickRegionOutside regionRectangle.
	self
		assert: (CellClickRegionOutside hintRegionForPoint: rect topLeft)
		equals: CellClickRegionRotateClockwise.
	self
		assert: (CellClickRegionOutside hintRegionForPoint: rect bottomLeft)
		equals: CellClickRegionRotateCounterClockwise
```

and the renderer answers a direction where it used to answer the outside region itself:

```smalltalk
MirrorCellRendererTestCase >> testAMirrorAnswersThePushRegionOfAPointInsideIt
	"A mirror asks the region of a point what hint applies there, so a point in the inside region
	answers a push region rather than the inside region itself, and a point in the outside region
	answers a rotate region."

	| renderer rect |
	renderer := self rendererLeaning: #left.
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (renderer hintRegionAt: rect leftCenter + (1 @ 0))
		equals: CellClickRegionPushEast.
	self
		assert: (renderer hintRegionAt: rect topCenter + (0 @ 1))
		equals: CellClickRegionPushSouth.
	self
		assert: (renderer hintRegionAt: CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionRotateClockwise.
	self assert: (renderer hintRegionAt: 0 @ 0) equals: CellClickRegionIgnore
```

Two tests of the last two chapters were written while the outside region had nothing to say, and said so in their names.
We rewrite both here, and the rewrite is worth watching: the claims do not change, only the expectations and the names.

```smalltalk
CellClickRegionTestCase >> testEachRegionWithAPictureAnswersTheArrowOfItsDirection
	"Each region that has a picture answers an element built at the size asked for, and the regions
	that have no picture answer nothing: the inside and outside regions always refine themselves
	first, and the ignore region never shows anything."

	| extent |
	extent := 48 @ 48.
	self assert: (CellClickRegionOutside hintElementOfExtent: extent) isNil.
	self assert: (CellClickRegionIgnore hintElementOfExtent: extent) isNil.
	self assert: (CellClickRegionInside hintElementOfExtent: extent) isNil.
	{ (CellClickRegionPushNorth -> LaserGameShapes northArrowPoints).
	(CellClickRegionPushEast -> LaserGameShapes eastArrowPoints).
	(CellClickRegionPushSouth -> LaserGameShapes southArrowPoints).
	(CellClickRegionPushWest -> LaserGameShapes westArrowPoints).
	(CellClickRegionRotateClockwise
	 -> LaserGameShapes clockwiseArrowPoints).
	(CellClickRegionRotateCounterClockwise
	 -> LaserGameShapes counterClockwiseArrowPoints) } do: [ :each |
		| element |
		element := each key hintElementOfExtent: extent.
		self
			assert: element geometry vertices
			equals: (LaserGameShapes pointsOf: each value scaledToExtent: extent) ]
```

We added two rows to a table, and the name went from "only a push region" to "each region with a picture".
A test whose name states a count — *only one*, *the four of them* — makes you rename it every time the count changes.
A name that states the rule does not.

```smalltalk
CellClickRegionTestCase >> testTheInsideAndOutsideRegionsRefineTheHintTheyAnswer
	"Every region is asked for its hint. The inside region answers the push region of the point,
	and the outside region answers the rotate region of the point. The ignore region answers
	itself, having nothing finer to say and no picture to show."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (CellClickRegionOutside hintRegionForPoint: 
				 CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionRotateClockwise.
	self
		assert: (CellClickRegionIgnore hintRegionForPoint: 0 @ 0)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegionInside hintRegionForPoint: rect leftCenter + (1 @ 0))
		equals: CellClickRegionPushEast
```

Last, we check that the cell element draws the curved arrow when the pointer is on the rim:

```smalltalk
LaserGameCellElementTestCase >> testMovingInTheOutsideRegionOfAMirrorCellShowsARotateArrow
	"Hovering the outside region shows the curved arrows. The cell adds one as a child exactly as
	it adds a push arrow, and the upper half of the region shows the clockwise one. The last row
	of the region belongs to the ignore margin, as `Rectangle >> containsPoint:` leaves its
	bottom edge out, so the lower point is taken one pixel above it."

	| element rect |
	element := board cellElementAt: 4 @ 1.
	rect := CellClickRegionOutside regionRectangle.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: rect topLeft;
			 yourself).
	self assert: (element children includes: element hintElement).
	self
		assert: element hintElement geometry vertices
		equals: (LaserGameShapes
				 pointsOf: LaserGameShapes clockwiseArrowPoints
				 scaledToExtent: CellRenderer hintArrowExtent).
	element dispatchEvent: (BlMouseMoveEvent new
			 position: rect bottomLeft - (0 @ 1);
			 yourself).
	self
		assert: element hintElement geometry vertices
		equals: (LaserGameShapes
				 pointsOf: LaserGameShapes counterClockwiseArrowPoints
				 scaledToExtent: CellRenderer hintArrowExtent)
```

The comment earns its length.
`rect bottomLeft` is *not* in the rectangle, because `Rectangle >> containsPoint:` includes the top and left edges and excludes the bottom and right ones.

Written without the `- (0 @ 1)` the test would ask about a point in the ignore margin, get no arrow, and fail for a reason that has nothing to do with rotation.
## The click geometry, painted

Seven regions now exist, and nobody has ever seen them together.
Ten classes answer `containsPoint:`, two of them with a diagonal written as arithmetic, and between them they decide what a click on a cell does.
*Determine push regions* spent a chapter on them and a table of named points on proving them; this chapter added two more and a horizontal line.

A picture would settle all of it at once, and we can paint one without stating a single boundary ourselves.
Ask the rules about every point of a cell, and colour the point by the answer.

The points come first, because the picture and the table after it are built from the same ones:

```smalltalk
CellClickRegion class >> inspectionSampleStep
	"Answer the distance, in cell pixels, between two points the Regions picture and the Map table
	are built from. Two is fine enough to put every boundary of a fifty pixel cell on the screen,
	and it leaves a picture of six hundred and twenty five squares."

	^ 2
```

```smalltalk
CellClickRegion class >> inspectionSamplePoints
	"Answer every point of a cell the Regions picture and the Map table are built from, one per
	inspectionSampleStep in each direction, read in the order a picture is painted."

	| extent points |
	extent := CellRenderer cellExtent.
	points := OrderedCollection new.
	0 to: extent y - 1 by: self inspectionSampleStep do: [ :y |
		0 to: extent x - 1 by: self inspectionSampleStep do: [ :x |
			points add: x @ y ] ].
	^ points
```

Then the one question we ask of each of them:

```smalltalk
CellClickRegion class >> inspectionRegionAt: aPoint
	"Answer the region a click at aPoint really lands in. The point is claimed by one of my three
	subclasses and then refined, since the inside region answers one of its four push regions and
	the outside region one of its two rotate regions."

	^ (self clickRegionForPoint: aPoint) hintRegionForPoint: aPoint
```

Those two messages are the pair a mouse handler sends, in the order it sends them.
`clickRegionForPoint:` finds the region whose rectangle claims the point, innermost first.
`hintRegionForPoint:` is how the inside and the outside regions hand the point on to the subclass that really owns it.

A view that asked only the first would paint three regions where the game sees seven, and would be wrong in exactly the way the chapter is about.

Seven regions need seven colours, and none of the game's own will do:

```smalltalk
CellClickRegion class >> inspectionColorFor: aRegionClass
	"Answer the colour the Regions picture paints aRegionClass in. None of these is a colour of the
	game: the picture has to tell seven regions apart, which the board itself never has to do, and
	two regions of one colour would hide the boundary between them."

	| colors |
	colors := Dictionary new.
	colors
		at: CellClickRegionPushNorth put: (Color r: 0.55 g: 0.75 b: 1.0);
		at: CellClickRegionPushEast put: (Color r: 0.55 g: 0.9 b: 0.6);
		at: CellClickRegionPushSouth put: (Color r: 1.0 g: 0.8 b: 0.5);
		at: CellClickRegionPushWest put: (Color r: 0.8 g: 0.65 b: 1.0);
		at: CellClickRegionRotateClockwise put: (Color r: 1.0 g: 1.0 b: 0.6);
		at: CellClickRegionRotateCounterClockwise put: (Color r: 1.0 g: 0.7 b: 0.75);
		at: CellClickRegionIgnore put: (Color r: 0.85 g: 0.85 b: 0.85).
	^ colors at: aRegionClass ifAbsent: [ Color transparent ]
```

Two regions painted alike would hide the boundary between them, which is the one thing the picture exists to show.
So the dictionary gets a test of its own, and it is the shortest test in the chapter:

```smalltalk
CellClickRegionTestCase >> testEveryRegionAClickCanLandInHasAColourOfItsOwnInThePicture
	"Two regions painted the same colour would make the picture lie about where the boundary
	between them runs, so each of the seven regions a click can land in answers a colour no other
	one answers."

	| regions colours |
	regions := CellClickRegion withAllSubclasses select: [ :each |
		           each subclasses isEmpty ].
	colours := regions collect: [ :each |
		           CellClickRegion inspectionColorFor: each ].
	self assert: regions size equals: 7.
	self assert: colours asSet size equals: regions size
```

`withAllSubclasses select: [ :each | each subclasses isEmpty ]` is "every region a click can land in": the leaves of the hierarchy, which are the only classes `inspectionRegionAt:` ever answers.
Written that way the test does not list the seven, so a region added later is counted without the test being touched — and if its colour is a copy of another, the set of colours comes out one short.

The view itself is a square for every sampled point, at six times the size so a fifty pixel cell is worth looking at:

```smalltalk
CellClickRegion class >> inspectionRegions: aBuilder
	"Show one cell painted by region: every sampled point asked of clickRegionForPoint: and
	coloured by the answer. This is the picture the ten containsPoint: methods and the two
	diagonals add up to, and it is drawn by asking them rather than by restating them."

	<inspectorPresentationOrder: 1 title: 'Regions'>
	| zoom step canvas |
	zoom := 6.
	step := self inspectionSampleStep.
	canvas := BlElement new
		          extent: CellRenderer cellExtent * zoom;
		          background: Color white;
		          yourself.
	self inspectionSamplePoints do: [ :point |
			canvas addChild: (BlElement new
					 extent: step @ step * zoom;
					 position: point * zoom;
					 background:
						 (self inspectionColorFor: (self inspectionRegionAt: point));
					 yourself) ].
	^ aBuilder newMorph
		  morph: canvas asPreviewMorph;
		  yourself
```

Six hundred and twenty five elements is nothing to Bloc, and the picture is exact by construction.
There is no polygon in this method, no triangle, no `y = x`: every square asks the rules where it belongs.

> **Paint the picture by asking the rules.** A diagram drawn from a second copy of the geometry agrees with the code only until one of the two is changed.

The tab is on the class, not on an instance, which is where a question about a whole hierarchy belongs.
`Color class >> inspectionColors:` does the same in Pharo itself, so there is a precedent in the image to read.

It needs one more method, because a hierarchy can be inspected from the middle:

```smalltalk
CellClickRegion class >> inspectionRegionsContext: aContext
	"Show the Regions picture on the root of the hierarchy only. It is the one class that can ask
	every region in turn, since clickRegionForPoint: tries the subclasses of whichever class is
	asked, and a region asked for a picture of itself would paint a cell it does not own."

	aContext active: self superclass = Object
```

`clickRegionForPoint:` asks `self sortedSubclasses`, so inspecting `CellClickRegionInside` would paint a cell out of its four push regions alone, with the rotate regions and the ignore margin missing.
The condition hides the tab everywhere but the root, and it reads the hierarchy rather than naming a class.

> **A class-side tab belongs to the class that can answer for the whole hierarchy.** Where the answer would be partial, hide the tab rather than show half of one.

All a test can say about a picture is that it was built, and that is still worth one method:

```smalltalk
CellClickRegionTestCase >> testTheRegionsTabDrawsThePictureFromTheRulesThemselves
	"The Regions tab paints a cell by asking clickRegionForPoint: for every sampled point, so the
	picture cannot disagree with the rules it is drawn from. All a test can say about a picture is
	that it was built."

	| builder |
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	self
		assert: (CellClickRegion inspectionRegions: builder) class
		equals: SpMorphPresenter
```

## The same geometry as a table

A picture shows you where the boundaries are.
It does not say which rectangle was tried first, or how much of the cell each region ends up with, and those are the two things *Determine push regions* had to argue about on paper.

We count the sampled points instead:

```smalltalk
CellClickRegion class >> inspectionRegionCounts
	"Answer one association per region a click can land in, the region to the number of sampled
	points that fall in it, in the order the rectangles are tried."

	| counts |
	counts := Dictionary new.
	self inspectionSamplePoints do: [ :point |
		| region |
		region := self inspectionRegionAt: point.
		counts at: region put: (counts at: region ifAbsent: [ 0 ]) + 1 ].
	^ counts associations asSortedCollection: [ :a :b |
		  a key sortIndex = b key sortIndex
			  ifTrue: [ a key name <= b key name ]
			  ifFalse: [ a key sortIndex < b key sortIndex ] ]
```

```smalltalk
CellClickRegion class >> inspectionMap: aBuilder
	"Show one row per region a click can land in: the order its rectangle is tried in, the
	rectangle itself, how many sampled points fall in it, and whether it draws a hint. The inside
	and the outside regions have no row, because each of them refines itself to one of its own
	subclasses."

	<inspectorPresentationOrder: 2 title: 'Map'>
	^ aBuilder newTable
		  items: self inspectionRegionCounts;
		  addColumn: (SpStringTableColumn title: 'Region' evaluated: [ :each | each key name ]);
		  addColumn: (SpStringTableColumn title: 'Tried' evaluated: [ :each |
					   each key sortIndex printString ]);
		  addColumn: (SpStringTableColumn title: 'Rectangle' evaluated: [ :each |
					   each key regionRectangle printString ]);
		  addColumn: (SpStringTableColumn title: 'Points' evaluated: [ :each |
					   each value printString ]);
		  addColumn: (SpStringTableColumn title: 'Hint' evaluated: [ :each |
					   (each key hintElementOfExtent: CellRenderer cellExtent)
						   ifNil: [ '' ]
						   ifNotNil: [ 'arrow' ] ]);
		  yourself
```

The counting is a method of its own because the table should be a table and nothing else, and because the test can then read the counts without a presenter.

On a fifty pixel cell the tab reads:

```text
CellClickRegionPushEast                1  (10@10) corner: (40@40)   64  arrow
CellClickRegionPushNorth               1  (10@10) corner: (40@40)   56  arrow
CellClickRegionPushSouth               1  (10@10) corner: (40@40)   56  arrow
CellClickRegionPushWest                1  (10@10) corner: (40@40)   49  arrow
CellClickRegionRotateClockwise         2  (4@4) corner: (46@46)    111  arrow
CellClickRegionRotateCounterClockwise  2  (4@4) corner: (46@46)    105  arrow
CellClickRegionIgnore                  3  (0@0) corner: (50@50)    184
```

Four things in that table are worth your attention.

The inside and the outside regions have no row at all, although they are the two classes whose rectangles are tried: a point they claim is always handed on to a subclass, and the table says so by leaving them out.
The four push regions share one rectangle, the thirty by thirty square in the middle, and the two diagonals divide it between them — which is why one rectangle appears four times.
The two rotate regions share the ring between the two rectangles, split by the horizontal line this chapter drew.
And the ignore margin is the largest region of the cell at a hundred and eighty four points of six hundred and twenty five, which is the four pixel border where a click does nothing.

The four push counts are not equal, and that is not a fault.
A sampled point that lands exactly on a diagonal belongs to whichever side the strict comparison in `pointIsUnderHeadingUpLine:` gives it, and with a step of two pixels the diagonals carry sampled points.
Fifteen of them sit on `y = x`, and they all go east.

> **Count the answers, not the geometry.** A boundary rule and a picture of it can both be right while the share of the cell each region gets is a surprise.

The table hides from the middle of the hierarchy for the same reason the picture does:

```smalltalk
CellClickRegion class >> inspectionMapContext: aContext
	"Show the Map table on the root of the hierarchy only, for the reason the picture is shown
	there only: a region can answer for its own points, not for every region's."

	aContext active: self superclass = Object
```

```smalltalk
CellClickRegionTestCase >> testTheMapTabListsEveryRegionAClickCanLandIn
	"The Map tab counts the sampled points of each region a click can land in. The inside and the
	outside regions never appear, since each of them refines itself to a push or a rotate region,
	and that is the fact the table is there to show."

	| builder table regions |
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := CellClickRegion inspectionMap: builder.
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals: #( 'Region' 'Tried' 'Rectangle' 'Points' 'Hint' ).
	regions := table items collect: [ :each | each key ].
	self assert: (regions includes: CellClickRegionPushNorth).
	self assert: (regions includes: CellClickRegionRotateClockwise).
	self assert: (regions includes: CellClickRegionIgnore).
	self deny: (regions includes: CellClickRegionInside).
	self deny: (regions includes: CellClickRegionOutside).
	self
		assert: (table items inject: 0 into: [ :sum :each | sum + each value ])
		equals: CellClickRegion inspectionSamplePoints size
```

Three claims, and the middle one is the interesting one.
The two `deny:` lines assert an absence: the inside and the outside regions are the classes whose rectangles are tried, and neither of them ever appears as an answer.
The last assertion is a total — every sampled point is counted exactly once — which is the walk over every point of *Tests that hold at any cell size*, asked of the table rather than of the classes.

The two tabs cost eight methods between them, and between them they replace three chapters of argument with a picture and a count.
Keep them: *Click and rotate a cell* is where a click first means something, and the first question anyone asks of a click that did the wrong thing is which region it landed in.

Half-open rectangles catch everybody once; when a boundary point surprises you, print `rect` and ask it `containsPoint:` directly before changing any production code.

## Checking it

```smalltalk
| row space rect |
rect := CellClickRegionOutside regionRectangle.
row := BlElement new
	       layout: (BlLinearLayout horizontal cellSpacing: 20);
	       constraintsDo: [ :c | c horizontal fitContent. c vertical fitContent ];
	       padding: (BlInsets all: 20);
	       background: Color white;
	       yourself.
{ rect topLeft. rect bottomLeft - (0 @ 1). CellClickRegionInside regionRectangle center } do: [ :point |
	| board element |
	board := LaserGameBoardElement on: GridExample demoGrid.
	element := board cellElementAt: 4 @ 1.
	element showPositionHintAt: point.
	row addChild: board ].
space := BlSpace new.
space root addChild: row.
space extent: 900 @ 160.
space title: 'Rotate hints'.
space show
```

Three copies of the demo board, each with its mirror hinted at a different point: the clockwise arrow, the anticlockwise one, and a push arrow for comparison.

We build three boards and hint them by hand, rather than opening the game and moving the pointer, so that all three states are on the screen at once — which is the only way to compare them.

Then open the game and hover a mirror for real.
You now get every hint the game can show, and not one of them does anything yet.
The next chapter makes a mirror turn.

# Rotate a mirror cell

The board can tell which region a click falls in.
The next thing is a mirror that turns — and in this chapter we never touch an element or an event.

We work on the model first and the interface after.
A mirror that turns correctly is something you can test in three lines; a mirror that turns when clicked is something you have to test with a mouse.

On the way the cells learn to print themselves properly, because the quickest way through a bug like this one is to make the objects say more, and the tabs that say the rest of it were written in Section 1 and Section 2 and are waiting for us.

It is also the chapter where we introduce a bug on purpose, because the bug is a good one: a mirror that turns its picture and forgets to turn its behaviour.
Finding it is most of the work here, and the method for finding it is the part worth keeping.

## A message every cell understands

We start with the message, before we decide what it does.
The rotate methods go on `Cell`, where they do nothing at all:

```smalltalk
Cell >> rotateClockwise
	"Turn me clockwise, which for a cell in general is nothing at all. Both rotate messages live
	here so that a click can send one without asking what kind of cell it hit; only a mirror has
	anything to turn."
```

```smalltalk
Cell >> rotateCounterClockwise
	"Turn me counter clockwise, which for a cell in general is nothing at all. See
	`rotateClockwise`."
```

A method with a comment and no code.
It answers the receiver and does nothing, which is exactly the behaviour we want, and it is worth being clear that this is a decision and not a stub left behind.

The reason is the caller.
The outside region of *any* cell answers a rotate region — the regions know about rectangles, not about mirrors — so the click handler will send `rotateClockwise` to whatever cell was under the pointer.
Either the cell quietly ignores it, or every caller has to ask first:

```st
	cell class = MirrorCell ifTrue: [ cell rotateClockwise ]
```

One empty method, or a test in every caller for ever.
This pattern has a name — *null behaviour* — and it is the same move as `CellRenderer >> hintRegionAt:` answering nil: put the harmless answer on the superclass and let the one subclass that cares override it.

Doing nothing is a behaviour, so we test it:

```smalltalk
BlankCellTestCase >> testRotatingACellThatIsNotAMirrorDoesNothing
	"The two rotate messages live on Cell, where they do nothing, so a click in the outside region
	of any cell can send them without asking what kind of cell it is. Only a mirror has anything
	to turn."

	| cell |
	cell := BlankCell new.
	cell gridLocation: 2 @ 3.
	cell laserEntersFrom: #north.
	cell rotateClockwise.
	cell rotateCounterClockwise.
	self assert: cell gridLocation equals: 2 @ 3.
	self assert: cell isOn.
	self assert: (cell exitSideFor: #north) equals: #south
```

Read what it asserts: not that the message was understood — a test that only sends the message and checks nothing passes even when the method starts changing things — but that nothing *moved*.

Where the cell is, whether it is lit, where a beam leaving it goes.
"Does nothing" can only be tested by naming the things that must not change.

## Two directions, one turn

A mirror sits on one of two diagonals, and a quarter turn either way lands it on the other one.
So both directions do the same thing to a mirror.
We keep the two methods apart anyway, and one method underneath does the work:

```smalltalk
MirrorCell >> rotateClockwise
	"Turn me clockwise. A quarter of a turn either way leaves my mirror on the same diagonal, so
	both directions do the same thing to me. The two stay apart all the same, so that a caller can
	say which way it means, and one method does the work."

	self rotate
```

```smalltalk
MirrorCell >> rotateCounterClockwise
	"Turn me counter clockwise, which does the same to me as turning me clockwise. See
	`rotateClockwise`."

	self rotate
```

Two methods that are identical today, which we keep separate because they mean different things.
The caller says which way the player asked for; whether the mirror can tell the difference is the mirror's business.

If the turn is ever animated, or if a cell ever has four positions instead of two, the change is inside `MirrorCell` and no caller moves.

The judgement here is worth naming, because it cuts the other way just as often.
Two methods with the same body are usually one method too many.

They are two when the *names* carry information the body does not — here, a direction a player chose.
Keep them apart then, and keep the shared body in one place so that they cannot drift.

And we write the obvious body:

```st
rotate
	self leansLeft: self isLeft not
```
> **Note.** That is the version with the bug of this chapter in it.
> The end of the chapter replaces it.

We write a test to go with it, asking the mirror which way it leans:

```st
testCellRotate
	| cell |
	cell := MirrorCell new.
	cell leanLeft.
	self assert: cell isLeft.
	cell rotateClockwise.
	self assert: cell isRight.
	cell rotateCounterClockwise.
	self assert: cell isLeft
```
> **Note.** This test grows three assertions at the end of the chapter, and they are the ones that matter.

Green.
And wrong — not the test, the pair.
The test asks the mirror the one question `rotate` sets the answer to, and never asks it the question the rest of the game asks: *where does a beam go?*

That is the most common way a test suite goes quiet while the code is broken.
A method writes a fact, and the test reads back the same fact.
It cannot fail.
A test earns its place by reading something the method under test did not write directly.

## Where it actually breaks

The demo grid sends its beam east along the top row into the mirror at `4@1`, which leans right and turns the beam south into the target at `5@1`.
Turn that mirror and the beam should go west instead, leaving the target dark.

Our two tests say so, and both of them read the cells rather than the mirror:

```smalltalk
GridTestCase >> testFireLaserAfterMirrorRotation

	| cell |
	grid fireLaser.
	self assert: grid laserIsActive.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	grid stopLaser.
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 4 @ 1.
	self assert: cell isOff.
	grid rotateCellClockwiseAt: cell gridLocation.
	grid fireLaser.
	cell := grid at: 4 @ 1.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

```smalltalk
GridTestCase >> testFireLaserDuringMirrorRotation

	| cell |
	grid fireLaser.
	self assert: grid laserIsActive.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	cell := grid at: 4 @ 1.
	grid rotateCellCounterClockwiseAt: cell gridLocation.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

The first turns the mirror with the laser off and fires again; the second turns it while the laser is on.
Both end with the same assertion, `self assert: cell isOff` on the target, and against the one line version of `rotate` both of them fail there.
The target stays lit.

So we have a symptom: the mirror reports the new lean, the beam behaves as though it had the old one.
That is the whole of the information we have, and it is two objects away from the fault.
In the rest of the chapter we close that distance.

## Make the objects say more before stepping through them

Your first instinct on a failing test is to open the debugger and step.
Do that, and the bottom pane shows `a MirrorCell`.
Which mirror?
Leaning which way?
Lit or not?
None of that is on the screen, and you spend the next twenty minutes inspecting variables one at a time to find out.

So we fix the tools first.
It takes two short methods and it pays for itself inside one bug.

`printOn:` is the method every object uses to describe itself — in a list, in an inspector header, in the result of a code pane, in the failure message of a test.
All of those have room for one line, so the cell says its facts on one line:

```smalltalk
Cell >> printOn: aStream
	"Say where I am and whether the laser lights me, on one line, since an object is printed in
	many places where only one line fits: a list, an inspector header, a code pane. A subclass
	adds its own detail by overriding printDetailsOn:. For the state of my four sides, inspect me
	and read the Sides tab."

	super printOn: aStream.
	aStream nextPut: $(.
	self printDetailsOn: aStream.
	aStream
		nextPutAll: ', ';
		nextPutAll: (self isOn ifTrue: [ 'on' ] ifFalse: [ 'off' ]);
		nextPut: $)
```

`super printOn: aStream` writes `a MirrorCell` — the default every object has.
The rest adds the brackets and the state, and in the middle it sends `printDetailsOn:`, which is where a subclass gets its say:

```smalltalk
Cell >> printDetailsOn: aStream
	"Print what distinguishes me from another cell of my kind at the same place. There is nothing
	but my location, so a mirror adds the way it leans. `Point >> printOn:` puts brackets round
	itself, which would read badly inside my own, so the two coordinates are printed by hand."

	aStream
		print: self gridLocation x;
		nextPut: $@;
		print: self gridLocation y
```

```smalltalk
MirrorCell >> printDetailsOn: aStream
	"Add the way I lean, which is the one fact that tells two mirrors at the same place apart."

	super printDetailsOn: aStream.
	aStream nextPutAll:
		(self isLeft ifTrue: [ ' leans left' ] ifFalse: [ ' leans right' ])
```

Two methods instead of one, and the split is the point.
`printOn:` owns the frame — the class name, the brackets, the lit state, the punctuation — and every subclass inherits it.
`printDetailsOn:` owns the one detail that varies, and a subclass adds to it with `super` and one line.

Had `MirrorCell` overridden `printOn:` instead, it would have had to repeat the brackets and the lit state, and a change to the frame would then have to be made twice.

That is a pattern you reach for whenever subclasses need to vary *part* of a method: write the whole thing on the superclass and send one message out to the part that differs.
The superclass keeps control of the shape; the subclass fills in a hole.

Now a blank cell prints `a BlankCell(2@3, off)` and the mirror this chapter is about prints `a MirrorCell(4@1 leans right, off)` — which states, on one line, the lean the bug is about.

```smalltalk
BlankCellTestCase >> testPrintStringSaysWhereTheCellIsAndWhetherItIsOn
	"A cell that is not a mirror has no lean to report, so it prints its location and its state."

	| cell |
	cell := BlankCell new.
	cell gridLocation: 2 @ 3.
	self assert: cell printString equals: 'a BlankCell(2@3, off)'.
	cell laserEntersFrom: #north.
	self assert: cell printString equals: 'a BlankCell(2@3, on)'
```

```smalltalk
MirrorCellTestCase >> testPrintStringSaysWhereTheCellIsHowItLeansAndWhetherItIsOn
	"A mirror prints the three facts that tell it apart from any other cell: where it is, which way
	it leans and whether the laser lights it. One line, since that is what a list, an inspector
	header and a code pane have room for; the state of the four sides is in the Sides tab."

	| cell |
	cell := MirrorCell leanLeft.
	cell gridLocation: 4 @ 1.
	self assert: cell printString equals: 'a MirrorCell(4@1 leans left, off)'.
	cell rotate.
	self assert: cell printString equals: 'a MirrorCell(4@1 leans right, off)'.
	cell laserEntersFrom: #north.
	self assert: cell printString equals: 'a MirrorCell(4@1 leans right, on)'
```

Yes, test the print string.
You read it in every debugger, every inspector, and every failure message from here to the end of the book, and a print method that stops saying the lean is a quiet loss.
Two assertions on a string is a cheap guard on something a lot of later work leans on.

We give a step of the beam the same treatment, and it names its cell rather than describing it, so the cell's own print method does that part:

```smalltalk
LaserPathElement >> printOn: aStream
	"Name the cell this step of the beam is about and the side the beam enters it from. One line,
	since that is what a list, an inspector header and a code pane have room for."

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: self cell;
		nextPutAll: ' from ';
		nextPutAll: self entrySide asString;
		nextPut: $)
```

```smalltalk
LaserPathElementTestCase >> testPrintStringNamesTheCellAndTheSideTheBeamEntersFrom
	"A path element prints which cell the step is about and the side the beam enters it by, which
	is what makes a list of path elements readable."

	| element |
	element := LaserPathElement
		           cell: (MirrorCell leanRight gridLocation: 4 @ 1; yourself)
		           entrySide: #south.
	self
		assert: element printString
		equals:
		'a LaserPathElement(a MirrorCell(4@1 leans right, off) from south)'
```

`print:` is `printOn:` applied to another object, so one print method composes with the next.
The result — `a LaserPathElement(a MirrorCell(4@1 leans right, off) from south)` — is a whole step of the beam in one line, and a list of them gives you a readable trace of the beam.

## The tabs we already have

One line is not much, and the rest of what we want to know was given a tab chapters ago.

A cell carries two, written in *Enhancing MirrorCell* when the four sides were being asked one at a time.
*Sides* lists the four sides of a cell against where a beam entering each one leaves and whether that side is lit; *Lean* puts the same four sides against the way the mirror leans, and says row by row whether the two agree.
Read that second sentence again with this chapter's bug in mind.
A mirror whose lean was changed without its exit sides reads *no* on every row of the *Lean* tab, which is the fault we are hunting, named by a tab written before the fault existed.

A grid carries two more.
*Board*, written in *The game board*, draws the grid with the same element the window uses; *Beam*, written in *Drawing the target*, lists the path the laser takes, one row per step, each row printing its cell with the print method we have just given it.

So the diagnosis costs nothing but four clicks.
Inspect the grid: the *Board* tab draws the beam going the wrong way, so the fault is in the model and not in the drawing.
Inspect the mirror at `4@1`: the header says it leans left, and the *Sides* tab says a beam entering from the south still leaves to the east, which is where a mirror leaning *right* sends it.
The *Lean* tab says *no* on all four rows.
The bug is on the screen, in two tables, before we have stepped through anything.

That question — model or drawing? — is the one the *Board* tab exists to answer, and we ask it over and over in the rest of this section.
When the board in the tab is wrong, the fault is in the model; when the tab is right and the window is wrong, the fault is in the drawing.
Half the search, for one glance.

> **The lesson as a sentence.** A view written at the moment a fact was hard to reach is a view waiting for the bug that fact causes.

## The test that names the fault

Now the bug, with our tools in place.
The beam is built one step at a time by this method:

```smalltalk
LaserPathElement >> nextElementIn: aGrid
	| loc dirSym direction vector newLoc nextCell |
	loc := self cell gridLocation.
	dirSym := self cell exitSideFor: self entrySide.
	dirSym isNil ifTrue: [^nil].
	direction := GridDirection directionFor: dirSym.
	vector := direction vector.
	newLoc := loc + vector.
	nextCell := aGrid at: newLoc.
	^nextCell isNil
		ifTrue: [nil]
		ifFalse: [self class cell: nextCell entrySide: direction adjacentInversionSymbol]
```

Read the second line: `dirSym := self cell exitSideFor: self entrySide`.
The direction the beam leaves by does not come from the lean.
It comes from `exitSides`, a dictionary the cell keeps.
For the turned mirror it answers `#east` where it should answer `#west`, and everything after that line is correct arithmetic on a wrong answer.

There is the fault, and it has a name: the way a mirror leans is written down **twice** — once in `leansLeft`, once in the four entries of `exitSides` — and `rotate` changed one copy.

Having found it, we ask it as a test, at the method where it shows:

```smalltalk
LaserPathElementTestCase >> testTheNextElementFollowsTheMirrorAfterItIsRotated
	"Ask the step of the beam directly: the mirror at 4@1 of the demo grid sends a beam that enters
	from the south out to the east, and once it is turned, out to the west. A rotation that left
	the exit sides unchanged would send the beam out the way it went out before, and this is the
	method where that shows."

	| grid mirror element |
	grid := GridExample demoGrid.
	mirror := grid at: 4 @ 1.
	element := LaserPathElement cell: mirror entrySide: #south.
	self assert: mirror isRight.
	self
		assert: (element nextElementIn: grid) cell
		equals: (grid at: 5 @ 1).
	mirror rotate.
	self
		assert: (element nextElementIn: grid) cell
		equals: (grid at: 3 @ 1)
```

Compare it with the grid tests that failed first.
Those fire a laser, walk nine cells and assert on a target two objects away from the fault; this one builds a mirror, asks for the next step, turns the mirror and asks again.

Same bug, four lines, and the name of the test says what is broken instead of what the player noticed.

That is the move to practise.
A failing test at the level of the whole system tells you *that* something is wrong.
Once you know *what* is wrong, write the test one level down, where the fault is, and keep both: the low one tells you what broke, the high one tells you that it matters.

And we rewrite the mirror's own test to ask the question it should have asked in the first place:

```smalltalk
MirrorCellTestCase >> testCellRotate

	| cell |
	cell := MirrorCell new.
	cell leanLeft.
	self assert: cell isLeft.
	self assert: (cell exitSideFor: #south) equals: #west.
	cell rotateClockwise.
	self assert: cell isRight.
	self assert: (cell exitSideFor: #south) equals: #east.
	cell rotateCounterClockwise.
	self assert: cell isLeft.
	self assert: (cell exitSideFor: #south) equals: #west
```

We add three assertions, interleaved with the three that were there: after every change of lean, ask where a beam goes.
Now the test reads a fact that `rotate` does not write directly, which is what makes it able to fail.

## The fix

`MirrorCell` already has two methods that set the lean and the four exit sides together, written when we built the model and used by `GridExample demoGrid` ever since:

```smalltalk
MirrorCell >> leanLeft
	self leansLeft: true.
	self exitSides at: #north put: #east.
	self exitSides at: #east put: #north.
	self exitSides at: #south put: #west.
	self exitSides at: #west put: #south.
```

```smalltalk
MirrorCell >> leanRight
	self leansLeft: false.
	self exitSides at: #north put: #west.
	self exitSides at: #east put: #south.
	self exitSides at: #south put: #east.
	self exitSides at: #west put: #north.
```

So `rotate` has nothing to compute.
It has only to use them:

```smalltalk
MirrorCell >> rotate
	"Turn me a quarter of a turn, which puts my mirror on the other diagonal. Go through leanLeft
	and leanRight rather than flipping leansLeft, because the lean and the four exit sides have to
	change together: a lean changed on its own leaves the beam going out the way it went out
	before."

	self isLeft
		ifTrue: [ self leanRight ]
		ifFalse: [ self leanLeft ]
```

All five tests go green.
And the lesson is not "remember to update the dictionary".
It is this: when one fact is stored in two places, there must be exactly one method that writes both, and every other method must go through it.

`leansLeft: self isLeft not` was wrong not because it forgot something, but because it wrote one of the two copies by hand.

The question to ask of any setter you are about to write is whether some existing method already keeps the whole of the object consistent.
Here two did, and they had been there all along.

## Two small tidies

Reading the class closely for this bug turns up two other things we should correct.

The class-side constructors send `super new` where we meant `self new`:

```smalltalk
MirrorCell class >> leanLeft
	"Answer a mirror on the diagonal from my top left corner to my bottom right one."

	^ self new leanLeft
```

`super new` on the class side reaches past `MirrorCell class` to find `new`, which skips any `new` `MirrorCell class` might define later.
Nothing is wrong today; the method simply says something nobody meant.
Use `self new` unless there is a reason to skip an override.

And `Cell`, which has never been meant to have instances of its own, now says so where it matters:

```smalltalk
Cell >> initializeExitSides
	"Fill exitSides with the side a beam leaves by for each side it can enter from. Every
	subclass answers this differently, which is what makes a cell blank, a mirror or a target,
	so I am abstract here."

	^ self subclassResponsibility
```

`subclassResponsibility` raises an error naming the class and the selector, which is a far better failure than a cell that quietly has no exit sides.
Where filling in a method is the whole job of a subclass, say so in the method rather than in a comment on the class.

## Checking it

```smalltalk
| grid |
grid := GridExample demoGrid.
grid fireLaser.
grid inspect
```

You get the beam crossing the top row into the target in the *Board* tab, and the *Beam* tab lists the path a step at a time, each row printing its cell.
Then turn the mirror and inspect again:

```smalltalk
| grid |
grid := GridExample demoGrid.
grid fireLaser.
grid rotateCellClockwiseAt: 4 @ 1.
grid inspect
```

The board redraws with the beam going west and the target dark.
Inspect the mirror at `4@1` itself and read its *Sides* tab: the lean in the header and the *Leaves by* column now agree, which is the whole of this chapter in four rows.

A mirror turns correctly.
Nothing the player can do makes it turn — that is the next chapter, which is short, because the model is finished and the click already arrives.

# Click and rotate a cell

A mirror knows how to turn.
The board knows which region a click falls in.
In this chapter we join the two, and at the end of it the game is playable with a mouse.
The click asks its region whether it can act, the region acts, and the cell redraws the one thing that changed.

It is a short chapter, and that is the whole point of the four before it.
Every piece is already written; all we do is send one message along a chain that already exists.

## What a click has to mean

We start with the rule, because it is easy to get wrong.
A click is not a button release.
If the player presses the button on one cell, drags the pointer into the next one and lets go, that is a click on neither: the release landed somewhere the press did not.

Written by hand that is four pieces of work — handle the press, remember which cell it landed in, handle the release, compare the two, and clear the memory afterwards whatever happens.
An instance variable that holds the cell of the press is a variable that can be left behind, and every method that resets the game then has to remember to clear it too.

We write none of that here, because `BlClickEvent` *is* that rule.
Bloc raises it only when the press and the release both land on the same element.
The cell element has listened for it since *Handle mouse events*, and the handler is unchanged:

```smalltalk
LaserGameCellElement >> click: anEvent
	"A click landed on me: a press and a release in the same cell, which Bloc decides. The point
	the event carries is in my own coordinates, and it decides what the click does."

	self clickAt: anEvent localPosition
```

Look for this before writing event code.
A press-and-release pair in one element, a double click, a drag, the enter and leave of an element — those are events Bloc raises, not states to keep.

Code that tracks a state the framework already tracks is code that can disagree with the framework, and the disagreement always shows up as something that happens one time in twenty.

`anEvent localPosition` is the point of the click in the coordinates of the cell it landed in, so the click arrives already expressed in the only terms the regions understand.

## The same chain, one event later

Trace what a hint does, because the click is about to walk the identical path.

The pointer moves; the cell element asks its renderer for a hint region; the renderer — if it is a mirror's — asks `CellClickRegion` which region the point falls in; the region answers a picture.
Four objects, each asked one question, and not one `ifTrue:` on the class of anything.

The click walks the same four steps.
First the renderer, asked whether a click does anything to its cell:

```smalltalk
CellRenderer >> mouseUpAt: aPoint
	"Act on a click at aPoint, in the coordinates of my cell, and answer the cell it acted on, or
	nil when nothing happened. Nothing happens here: only a mirror answers a click, so the
	superclass does nothing and the mirror renderer deals with the request."

	^ nil
```

```smalltalk
MirrorCellRenderer >> mouseUpAt: aPoint
	"Act on a click at aPoint, in the coordinates of my cell, and answer the cell it acted on, or
	nil when the region aPoint falls in can do nothing. The region decides both questions: the
	outside region turns my mirror one way or the other, the inside region pushes it when there
	is room, and the ignore margin does nothing. The cell and the grid are passed down to the
	region, because a region knows what a click means and nothing else does."

	| region |
	region := CellClickRegion clickRegionForPoint: aPoint.
	^ (region
		   canActOnCellAtPoint: aPoint
		   cell: self cell
		   withinGrid: self grid)
		  ifTrue: [
		  region
			  mouseUpWithinCellAtPoint: aPoint
			  cell: self cell
			  withinGrid: self grid ]
		  ifFalse: [ nil ]
```

That is `hintRegionAt:` again, with a different message: every renderer is asked, all but the mirror answer nothing, and the mirror asks the region.
The two pairs of methods are not similar by accident — we wrote the second by copying the shape of the first, which is the cheapest kind of design work there is.

Two things in the mirror's version deserve reading closely.

The cell and the grid travel **down** with the message.
A region is geometry with an opinion about what a click there means; it has no cell and no grid of its own, and it is not going to be given one, because the same four push regions answer for every cell on the board.

So the renderer, which does know its cell, hands both along.
When a stateless object has to act on something, pass the something in rather than giving the object a reference to it.

And the method **answers** the cell it acted on, or nil.
That return value is what the caller uses to decide whether anything needs redrawing, and it means the question "did this click do something?"
is answered by the object that did it, not guessed at afterwards.

## Asking before acting

We split the click in two halves: *can* something be done here, and *do* it.
Both live on the regions.

```smalltalk
CellClickRegion class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	"Answer whether a click at aPoint can do anything to aCell. Nothing can be done in me: the
	ignore margin is a region where a click is a click on nothing, and the inside and outside
	regions each answer for the region the point really falls in."

	^ false
```

```smalltalk
CellClickRegionOutside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	^true
```

```smalltalk
CellClickRegionInside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid

	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^ pushRegion canPushCell: aCell withinGrid: aGrid
```

`^ false` on the superclass is doing real work.
The ignore margin — the four pixel border where a click means nothing — never needs a method of its own, because the honest default answer for a region in general is "no".

The outside region always can, since a mirror can always turn.
The inside region does not know, so it asks the push region of the point, which asks the grid whether there is room.

Then the doing, and each refining region passes the click on to the region the point really falls in:

```smalltalk
CellClickRegion class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	^aCell
```

```smalltalk
CellClickRegionOutside class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	| rotateRegion |
	rotateRegion := self rotateRegionForPoint: aPoint.
	^rotateRegion mouseUpForCell: aCell withinGrid: aGrid
```

```smalltalk
CellClickRegionInside class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^pushRegion mouseUpForCell: aCell withinGrid: aGrid
```

The two bodies are the same sentence with one word changed, and so were `hintRegionForPoint:` on the same two classes.
A region that divides itself answers for its parts by asking the part; that is the one idea this hierarchy has, and it now does three different jobs with it.

Separating "can you" from "do it" is worth the extra method.
The alternative is an action that quietly does nothing when it cannot, which leaves the caller unable to tell a refused click from a successful one — and the caller needs to know, because it is what decides whether to redraw.

A question that is asked before an action can also be asked by anything else that wants to know, which is what the next section's arrow colours will do with it.

## The leaf regions act

The two rotate regions are the end of the chain, and they have the easiest methods in the section:

```smalltalk
CellClickRegionRotateClockwise class >> mouseUpForCell: aCell withinGrid: aGrid
	aGrid rotateCellClockwiseAt: aCell gridLocation.
	^aCell
```

```smalltalk
CellClickRegionRotateCounterClockwise class >> mouseUpForCell: aCell withinGrid: aGrid
	aGrid rotateCellCounterClockwiseAt: aCell gridLocation.
	^aCell
```

Note what they send.
Not `aCell rotateClockwise`, although the cell understands it — the turn goes to the **grid**, naming the location.

The grid records every move it is asked to make, which is what the undo later in the book will read, and a cell turned behind the grid's back would be a move that nothing wrote down.
When a model has an object that owns the moves, send the move there.

We wrote the push regions the same way, and they are the reason the push already works:

```smalltalk
CellClickRegionPushNorth class >> canPushCell: aCell withinGrid: aGrid
	^aGrid canPushCellNorthFromLocation: aCell gridLocation
```

```smalltalk
CellClickRegionPushNorth class >> mouseUpForCell: aCell withinGrid: aGrid
	^aGrid pushCellNorthFromLocation: aCell gridLocation
```

So the same three methods that make a click turn a mirror make a click push one, and the guard keeps it honest: a push into an occupied cell or off the edge of the board cannot happen, because the region says the action is impossible before the click is ever passed on.
Later chapters still owe the player the arrows that show a push, the counter that counts the moves, and a bug — but the mechanism is here.

## Drawing what changed

The click acts on the model.
Something has to put the result on the screen.

```st
LaserGameCellElement >> clickAt: aPoint
	"Act on a click at aPoint, in my own coordinates. My board records that I was clicked, my
	renderer decides whether my cell acts and which region handles it, and the board draws itself
	again when something changed."

	self board ifNotNil: [ :board | board clickCellElement: self ].
	(self renderer mouseUpAt: aPoint) ifNil: [ ^ self ].
	self board ifNotNil: [ :board | board redrawCells ]
```
> **Note.** *Add a counter and window colours* replaces the last line: the board is told that a move was made, and it decides for itself what to redraw and what to count.

Three lines, and the middle one is the interesting one.
`(self renderer mouseUpAt: aPoint) ifNil: [ ^ self ]` leaves the method when nothing happened — a click in the ignore margin, a click on a blank cell, a push with no room.

No redraw, no move counted, nothing.
That is the return value of `mouseUpAt:` earning its keep: an early return on nil is the clearest way a method has of saying "nothing to do here".

And when something did happen, we draw every cell again:

```smalltalk
LaserGameBoardElement >> redrawCells
	"Draw every cell again. One action on one cell changes more than that cell: a turned mirror
	sends the beam somewhere else, and a pushed mirror leaves its old place empty, so nothing
	tries to work out which cells are affected."

	self children do: [ :each | each redraw ]
```

Every cell, not the one that was clicked.
This looks wasteful and it is the right choice, for a reason worth being explicit about: **a click changes more than the cell it landed on.**
Turn a mirror that stands on the beam and the beam goes somewhere else entirely; push a mirror and two cells swap contents.

Code that tries to work out exactly which cells an action affected is code that will one day be wrong, and being wrong looks like a cell left lit after the beam has gone.

Redrawing twenty-five small elements costs nothing a player can see.
Spend it, and keep your drawing code free of a dependency on the rules of the game.

```st
LaserGameCellElement >> redraw
	"Draw my cell again after the model changed. The cell standing at my location may be another
	one than before, since a push swaps two cells, so the renderer is chosen again; my hint is
	kept, because the pointer has not moved."

	| grid location region |
	grid := self renderer grid.
	location := self gridLocation.
	region := hintRegion.
	self removeChildren.
	hintElement := nil.
	hintRegion := nil.
	self renderer: (CellRenderer rendererFor: (grid at: location) grid: grid).
	self renderer renderBackgroundOn: self.
	self renderer renderBorderOn: self.
	self renderer renderContentsOn: self.
	hintRegion := region.
	self updateHintElement
```
> **Note.** The two lines about the hint are the subject of *Visual bug with push*, which reads the hint again from the cell that now stands here instead of keeping it; *Drawing the laser beam* adds the beam to the middle of the method.

Read the order: remember the hint, throw the children away, pick a renderer, draw, put the hint back.

A cell element keeps its *identity* through a redraw — it is still the element at `1@2`, the pointer is still inside it — but it does not keep its *renderer*, because a push means the cell standing at `1@2` may be a different cell of a different class.
Asking `CellRenderer rendererFor:` again is how the drawing follows the model.

What you watch is that `removeChildren` also destroys the arrow, and the arrow is not the model's business: the pointer has not moved, so the hint is still true.

Hence we save it in `region` and put it back.
State that belongs to the pointer has to survive a redraw of state that belongs to the model, and the two get tangled every time they are not separated on purpose.

The renderer reads its cell from the grid every time, rather than holding one:

```smalltalk
CellRenderer >> cell
	"Answer the cell I render, read from the grid every time. I hold a location and not a cell, so
	a cell that is replaced in the grid does not leave me showing the old one."

	^ self grid at: self cellLocation
```

A one-line method with a large consequence.
A renderer that held its cell would go on describing a cell that had been pushed somewhere else, and nothing would say so.
Holding the *location* and asking the grid means the renderer cannot be out of date.
Prefer deriving over storing whenever the thing stored can change behind your back.

## Tests

A click in the upper half of the outside region turns the mirror clockwise; the lower half turns it the other way.
The mirror lands on the other diagonal either way, so we cannot read the *direction* from the mirror.
We read it from the move the grid recorded:

```smalltalk
LaserGameCellElementTestCase >> testClickingTheUpperOutsideRegionOfAMirrorTurnsItClockwise
	"A click in the outside region turns the mirror, and the upper half turns it clockwise. The
	click carries a point in the coordinates of the cell, which is the whole of what the region
	needs."

	| element mirror |
	element := board cellElementAt: 4 @ 1.
	mirror := element cell.
	self assert: mirror isRight.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self assert: mirror isLeft.
	self assert: board grid movesStack last key equals: #clockwise
```

```smalltalk
LaserGameCellElementTestCase >> testClickingTheLowerOutsideRegionOfAMirrorTurnsItCounterClockwise
	"The lower half of the outside region turns the mirror the other way. The mirror ends up on
	the same diagonal either way, so the direction is read from the move the grid records. The
	last row of the outside rectangle belongs to the ignore margin, as `Rectangle >>
	containsPoint:` leaves its bottom edge out, so the point is taken one pixel above it."

	| element mirror |
	element := board cellElementAt: 4 @ 1.
	mirror := element cell.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle bottomLeft - (0 @ 1);
			 yourself).
	self assert: mirror isLeft.
	self assert: board grid movesStack last key equals: #counterClockwise
```

That is a trick worth keeping: when two different actions leave the object in the same state, assert on the record of the action rather than on the state.
Without `movesStack`, these two tests would be indistinguishable, and a bug that sent every click down the clockwise branch would pass both.

Then we test the two cases where a click does nothing:

```smalltalk
LaserGameCellElementTestCase >> testClickingTheIgnoreRegionOfAMirrorDoesNothing
	"The margin around the outside region shows no hint and does nothing when it is clicked.
	The superclass of the regions answers that no action is possible, which is where the ignore
	region gets its answer from."

	| element mirror |
	element := board cellElementAt: 4 @ 1.
	mirror := element cell.
	element dispatchEvent: (BlClickEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: mirror isRight.
	self assert: board grid movesStack isEmpty.
	self assert: board clickedCell identicalTo: mirror
```

```smalltalk
LaserGameCellElementTestCase >> testClickingACellThatIsNotAMirrorDoesNothing
	"Only a mirror acts on a click. A blank cell and the target answer nothing wherever they are
	clicked, which is the renderer superclass doing nothing."

	#( 1 5 ) do: [ :column |
		| element |
		element := board cellElementAt: column @ 1.
		element dispatchEvent: (BlClickEvent new
				 position: CellClickRegionInside regionRectangle center;
				 yourself).
		element dispatchEvent: (BlClickEvent new
				 position: CellClickRegionOutside regionRectangle topLeft;
				 yourself).
		self assert: board clickedCell identicalTo: element cell ].
	self assert: board grid movesStack isEmpty
```

`self assert: board grid movesStack isEmpty` is the assertion that makes both of these mean something.
"Nothing happened" is only checkable against a record of what happens, and the moves stack is that record.

Note too that the ignore-region test still asserts the click was *delivered* — the board recorded the cell — so the test cannot pass because the event never arrived.

One click changes more than one cell, and we give that its own test:

```smalltalk
LaserGameCellElementTestCase >> testTurningAMirrorOnTheBeamRedrawsTheWholeBoard
	"One click changes more than one cell: the mirror at 4@1 sends the beam into the target at
	5@1, and turning it sends the beam west instead. Every cell is drawn again after an action,
	so the target goes dark without anything working out which cells the beam left. The disc is the
	last child of the target, since a lit target draws the beam under its picture."

	| target |
	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	target := board cellElementAt: 5 @ 1.
	self
		assert: target children last background paint color
		equals: LaserGameColors targetCenterColorActive.
	(board cellElementAt: 4 @ 1) dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self
		assert: (board cellElementAt: 5 @ 1) children last background paint color
		equals: LaserGameColors targetCenterColorIdle
```
> **Note.** The *last child* in the two assertions is how the cell is built once *Laser on target cell* draws the beam underneath the picture of the target.
> Until then the disc is simply the last thing the target renderer adds.

This is the one test in the chapter that reads a colour on the screen.
It clicks one cell and asserts on a different one, four columns away, which is precisely the claim `redrawCells` makes.

Keep tests like this rare and keep them pointed at a claim; a test that checked the colour of all twenty-five cells would say no more and break on every cosmetic change.

And the push, which comes free:

```smalltalk
LaserGameCellElementTestCase >> testClickingTheInsideRegionOfAMirrorPushesIt
	"The inside region pushes. A push region is named after the side the cell is pushed from, so
	the lower triangle pushes north; the mirror at 1@2 has a blank cell above it, and after the
	click each of the two cell elements draws what now stands in it."

	| element |
	element := board cellElementAt: 1 @ 2.
	self assert: element cell class equals: MirrorCell.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionInside regionRectangle bottomCenter - (0 @ 1);
			 yourself).
	self assert: (board grid at: 1 @ 1) class equals: MirrorCell.
	self assert: (board grid at: 1 @ 2) class equals: BlankCell.
	self
		assert: (board cellElementAt: 1 @ 1) renderer class
		equals: MirrorCellRenderer.
	self
		assert: (board cellElementAt: 1 @ 2) renderer class
		equals: BlankCellRenderer
```

The last two assertions are the ones about `redraw`, and they are why `CellRenderer >> cell` reads from the grid.

The model moved the mirror from `1@2` to `1@1`; the two cell elements did not move, and each of them now holds a renderer of the class that matches what stands in it.
An element that had kept its original renderer would draw a mirror in an empty cell, which is exactly the bug a later chapter is named after.

## Checking it

```smalltalk
| grid space board |
grid := GridExample demoGrid.
grid fireLaser.
board := LaserGameBoardElement on: grid.
space := BlSpace new.
space root addChild: board.
space extent: 300 @ 300.
space title: 'Click and rotate'.
space show
```

Click the rim of a mirror and you turn it; the beam follows and the target lights or goes dark.
Click near the middle of a mirror and you move it, if there is room.

The game is playable.
It is also visibly unfinished, and in two ways worth noticing now, because both of them are chapters: move the pointer off a cell quickly and you sometimes leave the arrow behind; push a mirror and the cell it came from can keep showing something that is no longer there.
The first is next.

# Clean up left-over hints

Play the game for a minute and you get ghosts: arrows left standing on cells the pointer passed over and left long ago.
Four of them at once, on cells nothing is hovering.

The obvious suspect is the wrong one, twice over.
We fix it by letting the board own the one hint there is, and two tests keep the ghosts from coming back.

This chapter is about a kind of bug that is easy to misdiagnose, because the obvious explanation is wrong.
The arrows are drawn by code that works.
They are left behind by an event that never arrived.

## The wrong suspect

The natural first thought is geometry: some path the pointer can take that ends in the ignore margin, or on a boundary, leaving a cell with a hint and no event to clear it.
Chase that and you will read the region methods over and over, and they are all correct.

The second thought is better, and it comes from asking a different question.
Not *what did the code do with the events it got?*
but **what events did it actually get?**

We answer that question by watching, not reading.
Move the pointer quickly down a column of the board with an inspector open on the board element, or put a `self haltOnCount: 20` in `mouseMove:` as *Stopping code that runs too often* describes, and count what arrives.

Moving the pointer swiftly from the top of a column to the bottom, the game is told about the cell at `5@2` and then about the cell at `5@3` — and never about the one in between at all.

There is the bug, and it is not in this program:

> **Mouse move events are samples.** The operating system reads the mouse position at intervals, and the image handles whatever it is given.
> Nothing promises an event for every pixel the pointer crosses, so a cell can be entered and left between two samples.

Every program you write that follows a pointer has to live with this.
The lesson is general: when an event handler seems to run with the wrong state, find out what events it actually received before changing anything about what it does with them.

## Why the arrow survives in the first place

Bloc does better than the raw samples.
The mouse processor hit-tests each move it is given, compares the element under the pointer with the one that was under it before, and manufactures the leave of the old element and the enter of the new one.

So a pointer that jumps from one cell to a far one still produces a leave on the first cell, and the arrow of the cell that was left is taken away:

```smalltalk
LaserGameCellElement >> mouseLeave: anEvent
	"The pointer left me: my board hovers me no longer, and my hint goes with it."

	self board ifNotNil: [ :board | board unhoverCellElement: self ].
	self clearPositionHint
```

```st
LaserGameCellElement >> clearPositionHint
	"Forget my hint: the pointer is no longer in me, so the arrow goes too."

	hintRegion ifNil: [ ^ self ].
	hintRegion := nil.
	self updateHintElement
```
> **Note.** *Visual bug with push* adds a first line to this method, which forgets the point the hint was read at as well.

That is already most of the fix, and it is the reason the ghosts are intermittent rather than constant.
But look at what it rests on: a promise from the event system that a leave is always delivered.

Build on that promise alone and the ghost comes back the first time it is not kept — on a slow frame, during a window resize, on a platform that reports the pointer differently.

So we do not rest on it.
We make the invariant true in the program itself.

## One hint, kept by the board

The invariant we state is simple: **at most one cell holds a hint at a time, and it is the cell the board hovers.**
Written that way, we enforce it in one line, because the board already learns which cell is hovered on every enter and on every move:

```smalltalk
LaserGameBoardElement >> hoverCellElement: aCellElement
	"Remember that the pointer is over aCellElement. A cell tells me this when the pointer enters
	it and while it moves inside it. The cell I hovered before loses its hint here: mouse moves
	arrive as samples, so a cell the pointer crossed quickly is never told that it was left. One
	cell can hold a hint at a time, so clearing the previous one is this single line."

	hoveredCellElement == aCellElement ifTrue: [ ^ self ].
	hoveredCellElement ifNotNil: [ :each | each clearPositionHint ].
	hoveredCellElement := aCellElement
```

Three lines, each doing one thing.
The first returns at once when the hovered cell has not changed, which is the common case, since a move inside a cell sends this message on every sample.
The second takes the hint away from whatever cell was hovered before.
The third records the new one.

Nothing here asks which cells the pointer crossed, and that is the design decision you take away from this chapter.
The skipped cells do not matter.
What matters is which cell was hovered before and which is hovered now, and the board knows both of those without any help from the event stream.

An invariant enforced at the one place the state changes cannot be broken by a missing event.
An invariant maintained by a pair of events — one to set, one to clear — is only as reliable as the delivery of both.

And its counterpart is unchanged:

```smalltalk
LaserGameBoardElement >> unhoverCellElement: aCellElement
	"Forget the pointer position, but only when aCellElement is the cell I hover. Moving from
	one cell to the next can deliver the enter of the new cell before the leave of the old one."

	hoveredCellElement == aCellElement ifTrue: [ hoveredCellElement := nil ]
```

Two guards, in two methods, against two different orderings of the same pair of events.
Read them together: `hoverCellElement:` ignores a hover of the cell it already hovers, and `unhoverCellElement:` ignores an unhover from a cell it does not hover.
Between them the board's idea of where the pointer is cannot be corrupted by the order the events arrive in.

The last ghost — the pointer leaving the board entirely — needs nothing at all.
Leaving the board means leaving a cell of it, and the cell is told.

## Tests

Our first test is the skipped event, written directly.
Two cells each get a move, and no leave is ever delivered to either.
Without the new line in `hoverCellElement:` it fails:

```smalltalk
LaserGameCellElementTestCase >> testHoveringAnotherCellClearsTheHintOfTheOneLeftBehind
	"The pointer moves fast, mouse moves are sampled, and cells are skipped, so a cell can be
	left without ever being told. The board hovers one cell at a time, so the cell it hovered
	before loses its hint when another one takes its place, whatever events were missed."

	| first second |
	first := board cellElementAt: 4 @ 1.
	second := board cellElementAt: 1 @ 2.
	first dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: (first children includes: first hintElement).
	second dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: first hintRegion isNil.
	self assert: first hintElement isNil.
	self assert: (second children includes: second hintElement)
```

This is a test that reproduces a *missing* event, which is a thing you should know how to do.

We do it by sending only the events the bug needs — a move on one cell, then a move on another — and deliberately not sending the leave that a real pointer would usually produce.
`dispatchEvent:` gives exactly that control: the test decides what the game hears.

The next two go the other way and leave the events to Bloc, in a real space, so that the enter and leave events come from the mouse processor rather than from the test:

```smalltalk
LaserGameHintEventTestCase >> setUp
	"Open a headless space on a board of the demo grid. The space is what makes the mouse
	processor of Bloc deliver the enter and leave events my tests rely on."

	| aSpace |
	super setUp.
	board := LaserGameBoardElement on: GridExample demoGrid.
	aSpace := self newTestingSpace.
	aSpace root addChild: board.
	aSpace settle
```

```smalltalk
LaserGameHintEventTestCase >> positionInCellAt: aGridLocation offset: aPoint
	"Answer the position in space coordinates of the point aPoint of the cell at aGridLocation.
	The event simulator speaks in space coordinates; a renderer and a click region speak in the
	coordinates of one cell, which is what aPoint is in."

	^ (board cellElementAt: aGridLocation) bounds inSpace bounds origin + aPoint
```

```smalltalk
LaserGameHintEventTestCase >> cellElementsShowingAHint
	"Answer the cell elements of my board that hold a hint arrow."

	^ board children select: [ :each | each hintElement notNil ]
```

Three helper methods and a test case of its own, which is a lot of scaffolding for two tests.
It buys us one thing: these tests do not know how the enter and leave of an element are decided.

They move a pointer and look at the board.
Every other test in this section would still pass if Bloc stopped producing leave events; these two would not.

`newTestingSpace` is a space that runs without a window, which is why these tests can run in a build with no screen.

`aSpace settle` lays the elements out, which is what gives the cells their real positions — and we need `positionInCellAt:offset:` because the simulator speaks in *space* coordinates while everything else in this section speaks in the coordinates of one cell.
One method to do that conversion, in one place, named after what it answers.

```smalltalk
LaserGameHintEventTestCase >> testMovingQuicklyToADistantCellLeavesNoArrowBehind
	"Move the pointer quickly and whole cells are skipped: the game hears about one cell and then
	about a distant one, with nothing in between. Here those two moves are the only ones the space
	is given, and the mirror that was left keeps no arrow."

	| first second |
	first := board cellElementAt: 4 @ 1.
	second := board cellElementAt: 1 @ 2.
	board eventSimulator mouseMoveAt:
		(self positionInCellAt: 4 @ 1 offset: CellClickRegionInside regionRectangle center).
	self assert: first hintElement notNil.
	board eventSimulator mouseMoveAt:
		(self positionInCellAt: 1 @ 2 offset: CellClickRegionInside regionRectangle center).
	self assert: first hintElement isNil.
	self assert: second hintElement notNil.
	self assert: self cellElementsShowingAHint asArray equals: { second }
```

The last assertion is the one that catches a ghost anywhere on the board, and you should copy the shape of it.
The two assertions before it check the two cells the test knows about; this one checks that *no other cell* is showing anything.

A bug of the "something left behind" kind is invisible to a test that only looks where it expects the state to be.
Ask the whole collection.

```smalltalk
LaserGameHintEventTestCase >> testMovingOffTheBoardClearsTheArrow
	"The pointer leaves the board entirely, so no cell is entered next. Bloc sends the leave of the
	cell under the pointer whatever is under it afterwards, so the arrow goes and the board hovers
	nothing."

	board eventSimulator mouseMoveAt:
		(self positionInCellAt: 4 @ 1 offset: CellClickRegionInside regionRectangle center).
	self assert: (board cellElementAt: 4 @ 1) hintElement notNil.
	board eventSimulator mouseMoveAt: board bounds inSpace bounds bottomRight + (20 @ 20).
	self assert: self cellElementsShowingAHint isEmpty.
	self assert: board hoveredCellElement isNil
```

`board bounds inSpace bounds bottomRight + (20 @ 20)` is a point twenty pixels past the corner of the board — off it, with certainty, at any cell size.
Write a point outside something as *its own corner plus a margin*, never as a number that happens to be outside today.

## Checking it

```smalltalk
| grid space board |
grid := GridExample demoGrid.
grid fireLaser.
board := LaserGameBoardElement on: grid.
space := BlSpace new.
space root addChild: board.
space extent: 300 @ 300.
space title: 'Ghost arrows'.
space show
```

Move the pointer across the board as fast as you can, in and out of the mirrors, off the board and back.
One arrow at a time, and none left behind.

The next bug is a different shape: not something left on the screen, but something the model keeps believing after it has stopped being true.

# Bug with target cell

Fire the laser.
The target lights up.
Now turn the mirror that feeds it.
The beam goes somewhere else — and the target stays lit.

We decide first whether the fault is in the model or in the drawing, reproduce it in a test, and then fix it where it belongs — in the grid, not in the method that turns the mirror.

This is the third bug hunt of the book and it has a shape of its own.
The arrows left behind were a missing event.

The mirror that turned its picture and not its behaviour was one fact stored twice.
This one is a method that is correct, called by a method that is correct, with nothing in between asking the question that needed asking.

## Model or drawing?

The first question for *every* bug where the screen is wrong: is the model wrong, or is the picture of a correct model wrong?
Answer that before anything else, because it halves the code you have to read, and it is cheap to answer.

A grid has three tabs by now and every one of them was written before this bug existed: *Board* draws it, *Beam* lists the path the laser takes, and *Cells* — written back in *Grid*, when a row and a column had just been confused in `at:put:` — lists one row per cell with what the cell is and whether it is lit.
So we answer the question by looking:

```smalltalk
| grid |
grid := GridExample demoGrid.
grid fireLaser.
grid rotateCellCounterClockwiseAt: 4 @ 1.
grid inspect
```

The *Cells* tab says it in one row: `a TargetCell(5@1, on)`, with *yes* in the *Lit* column, while the *Beam* tab shows a path that no longer goes anywhere near it.
So the model is wrong.
The drawing is faithfully showing a cell that believes something untrue, and no amount of reading the renderers would have found that for you.

Notice how little work that was, and notice that it was work done *earlier*.
Three tabs, written in three different chapters for three different reasons, and the one written for a confusion between rows and columns is the one that names this bug.
That is the argument for writing a view the day a fact is hard to reach rather than the day a bug needs it: you do not know yet which bug it will catch, and it costs one method either way.

One warning while reading a tab like this, and it is the commonest way to waste an afternoon: change **one** thing at a time.
Turn a mirror *and* stop the laser, then look at the cells, and whatever is wrong could belong to either action.
Our experiment above turns a mirror and nothing else.

## The test that reproduces it

Stop looking at the screen.
We already have a test about rotation:

```smalltalk
GridTestCase >> testFireLaserAfterMirrorRotation

	| cell |
	grid fireLaser.
	self assert: grid laserIsActive.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	grid stopLaser.
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 4 @ 1.
	self assert: cell isOff.
	grid rotateCellClockwiseAt: cell gridLocation.
	grid fireLaser.
	cell := grid at: 4 @ 1.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

and it is green.
Read it carefully before trusting that: `stopLaser` comes **before** the rotation and `fireLaser` after it.
The test turns the mirror while the beam is off.
That is not what the player did.

That is the most useful habit in this chapter.
When a bug is on the screen and the tests are green, do not assume the tests are inadequate in some vague way — read the one nearest the bug, line by line, and name the difference between what it does and what you did.
Here the difference is one word: *while*.

So we write the missing test, which turns the mirror with the beam running:

```smalltalk
GridTestCase >> testFireLaserDuringMirrorRotation

	| cell |
	grid fireLaser.
	self assert: grid laserIsActive.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	cell := grid at: 4 @ 1.
	grid rotateCellCounterClockwiseAt: cell gridLocation.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

Red, on the last assertion.
The bug is now a failing test, and we need the screen no more.

Two tests, named `...AfterMirrorRotation` and `...DuringMirrorRotation`, differing in one thing: when the rotation happens relative to the state of the laser.
That pair is worth keeping as a model.
Where an action can be taken in two different states of the system, there are two tests, and the names say which state.

## Why the method that turns the mirror cannot fix it

Step into `rotate` and it does exactly what it says and nothing more: the mirror goes onto the other diagonal.
Nothing recalculates the beam.

You will be tempted to make it do so — to have the cell ask its grid to recalculate after it turns.

Resist it, and be clear about why: **a cell does not know its grid, and must not.**
Cells get pushed from one location to another; a cell holding a reference to a grid would be a second copy of the fact of where it belongs, and the chapter on rotation has already shown what a second copy of a fact costs.

A cell knows its own four sides and its location.
That is all.

If the cell cannot do it and the click region has no business knowing about beams, then the responsibility belongs to the object that owns both the cells and the beam.
That is the grid:

```smalltalk
Grid >> rotateCellClockwiseAt: aPoint
	"Turn the cell at aPoint clockwise. The beam is taken off the board first and put back
	afterwards if the laser is on, so the cells it lit before the turn go dark and the cells on the
	new path light up. The turn is recorded, so that it can be undone and counted."

	| cell |
	cell := self at: aPoint.
	self clearCellsInPath.
	(self at: aPoint) rotateClockwise.
	self laserIsActive ifTrue: [ self activateCellsInPath ].
	self stackAction: #clockwise forCell: cell
```

```smalltalk
Grid >> rotateCellCounterClockwiseAt: aPoint
	"Turn the cell at aPoint counter clockwise. See `rotateCellClockwiseAt:`; only the action
	recorded differs."

	| cell |
	cell := self at: aPoint.
	self clearCellsInPath.
	(self at: aPoint) rotateCounterClockwise.
	self laserIsActive ifTrue: [ self activateCellsInPath ].
	self stackAction: #counterClockwise forCell: cell
```

Read the order of the three middle lines, because the order is the fix:

1. `clearCellsInPath` — put out every cell the beam currently lights, **while the old path is still
   the right one**.
2. the cell turns.
3. `activateCellsInPath` — light the cells of the new path, but only if the laser is on.

Clearing has to happen first.
Turn the mirror before putting the old beam out and the path is already the new one, so the cells of the *old* path never get cleared, and the bug is still there with the lines in a different order.

```smalltalk
Grid >> clearCellsInPath
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe clearCell]
```

```smalltalk
Grid >> activateCellsInPath
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe activateCell]
```

Both of them recalculate the path before walking it, which is what makes them safe to call in this order around a change to a cell.
And the guard `self laserIsActive ifTrue:` is the whole of the difference between the two tests above: with the laser off there is nothing to put back.

The last line records the move:

```smalltalk
Grid >> stackAction: aSymbol forCell: aCell
	"Record that aSymbol was done to aCell, so that the move can be taken back and counted. An
	entry holds the symbol of the move and where the cell is now: a pushed cell has already
	moved, and the push that undoes it starts from where it landed."

	self movesStack add: aSymbol->(aCell gridLocation)
```

A symbol and a location, pushed on a stack.
Nothing reads it yet.
It is what the counter of moves and the undo are built on later, and we write it here because here is where a move is actually made — a record kept anywhere else would be a record that could be forgotten.

Both tests go green, and nothing in the click chain changes, because the click already went to the grid and named a location: `aGrid rotateCellClockwiseAt: aCell gridLocation`.
The fix landed behind an interface that was already in the right place.

## The real lesson

The bug was not a wrong calculation anywhere.
Every method involved did what its name said.
What was missing was the knowledge that **turning one cell invalidates a fact held by several other cells.**

That is a kind of bug you should expect for the rest of this book, and the question that finds it is always the same: *when this changes, what else was computed from it?*
Here the answer is the beam, and the cells it lit.

The fix is to put the derived state back in step at the one place the change is made, in an object that can see both.

The alternative — recomputing the beam from scratch whenever anyone asks whether a cell is lit — would also be correct.
It is not what this program does, and the trade is worth naming: this design stores derived state and takes on the duty of keeping it fresh, in exchange for a cell that can answer `isOn` instantly.

Whenever you store something derived, there is a method somewhere that has to keep it true, and it is worth knowing which one it is.

## Tests

The model is fixed and tested.
What we add in this chapter is a guard that the picture cannot drift from the model again.
After a turn made by a real click, with the laser on, every cell element is asked whether it still shows its own cell:

```smalltalk
LaserGameCellElementTestCase >> testEveryCellElementAgreesWithItsCellAfterATurn
	"After a mirror is turned while the laser is on, is what the board shows still what the grid
	holds? Every cell is asked: the renderer is the one of the cell standing there, and the
	target is drawn lit exactly when its cell is on."

	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	(board cellElementAt: 4 @ 1) dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	1 to: grid numberOfRows do: [ :row |
		1 to: grid numberOfColumns do: [ :column |
			| location element cell |
			location := column @ row.
			cell := grid at: location.
			element := board cellElementAt: location.
			self assert: element renderer class modelClass equals: cell class.
			cell class = TargetCell ifTrue: [
				self
					assert: element children fourth background paint color
					equals: (cell isOn
							 ifTrue: [ LaserGameColors targetCenterColorActive ]
							 ifFalse: [ LaserGameColors targetCenterColorIdle ]) ] ] ]
```

This is the whole investigation turned into one assertion, run over all twenty-five cells: the renderer of each element matches the class of the cell standing at that location, and the target is drawn lit exactly when its cell is on.
Not *the target at 5@1 is dark* — the rule, for every cell, whatever the board is.

Write a test like this once per bug class, not once per bug.
It costs a nested loop and it closes the whole family: any future change that leaves an element describing a cell that is no longer there fails here.

The *Cells* tab has gone untested since *Grid*, and this is the first chapter that can test it, because the row that matters is the lit one and nothing lit a board until Section 2.
A presentation method gets one smoke test, and here it is:

```smalltalk
GridTestCase >> testTheCellsTabListsEveryCellWithItsState
	"The Cells tab answers in one view whether any cell disagrees with the beam: one row per cell,
	with what the cell is and whether it is lit."

	| builder table |
	grid fireLaser.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := grid inspectionCells: builder.
	self
		assert: table items size
		equals: grid numberOfColumns * grid numberOfRows.
	self assert: (table items includes: (grid at: 5 @ 1)).
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals: #( 'Cell' 'Lit' )
```

One row per cell, the target among them, two columns.
Not the pixels: the rows and the column titles, which is enough to catch the tab raising an error, and that is the only way a tab really breaks.
A tab that silently stopped listing some of the cells would be worse than no tab, since you would trust it.

## Checking it

```smalltalk
| grid space board |
grid := GridExample demoGrid.
grid fireLaser.
board := LaserGameBoardElement on: grid.
space := BlSpace new.
space root addChild: board.
space extent: 300 @ 300.
space title: 'Target cell'.
space show
```

Turn the mirror next to the target and you get a dark target; turn it back and it lights again.
Better, try it on the mirror at the start of the beam: every mirror along the path moves the beam, and the target follows every time.

We have left one question open on purpose.
Should a player be allowed to rearrange the board at all while the laser is running?
The game says yes for now, and the beam simply follows.
It is a rule about the game rather than a bug in it, and it comes back later.

Next, the other half of what a click can do: pushing a cell.

# Push a cell

Turning a mirror is one of the two moves of the game.
In this chapter we write the other one: pushing a mirror sideways into the empty square next to it.

The rules give us the tests, the four directions become four objects, and the move is written down, so that a chapter near the end of the book can take it back.

The rules first, in sentences, before any code:

- only mirror cells move;
- the target never moves;
- one cell moves at a time, so two mirrors standing side by side do not travel together;
- and nothing is really pushed. A mirror and the blank cell beside it trade places.

The last line is the whole of the logic.
If the neighbour in the direction of the push is a blank cell, the two trade places.
Otherwise nothing happens — and "otherwise" covers every other case in exactly the same way: a mirror there, the target there, or the edge of the board with no cell there at all.

Writing the rules out like that, before writing code, is worth the few minutes it takes.
Each line becomes a test further down, and the fourth line decides the shape of the code: a push is not a move, it is a swap.

A rule you can state in one sentence usually has a method behind it that is just as short.

## Whose job is it?

The rules talk about neighbours.
A cell knows where it sits, but it does not know what sits next to it, and it should not.
A cell that could reach its neighbours could push itself around, and then "only one cell moves at a time" would be a rule spread over twenty-five objects.

`Grid` holds the cells, so the grid is the only object that can answer *what is north of 3@3?*.
The push belongs to the grid.

That is the same reasoning as in *Bug with target cell*, where turning a mirror had to be the grid's work because the beam had to be worked out again around it.

It is a good question to ask of any new operation: which object already knows everything the operation needs?
Put the operation there, and no new connection between objects has to be invented.

## The demo grid, once more

Every test in this chapter plays on the demo grid, so it helps to have its map in front of you.
`/` and `\` are mirrors, `T` is the target, and the laser starts in the bottom left cell:

```text
       1   2   3   4   5
   1   .   .   .   /   T
   2   /   .   .   .   \
   3   .   \   /   .   \
   4   .   \   \   .   .
   5   /   .   .   /   .
```

Locations are written column @ row, so `4@1` is the mirror on the top edge and `1@5` is the one the laser starts in.
The grid has a case for every rule: a blank corner at `1@1`, the target at `5@1`, a mirror on its own in open space at `1@2`, a block of four mirrors at `2@3`, `3@3`, `2@4` and `3@4`, and mirrors against the edges at `4@1`, `1@5` and `4@5`.

That is not an accident.
We built the demo grid to be looked at, and it earns its keep as a test fixture because it holds every situation the rules mention.

When you find yourself building a fresh object in ten tests, each one slightly different, stop and build one object that covers all ten.
That is what `GridExample demoGrid` has been since the chapter *Grid*, and `GridTestCase >> setUp` reads it into the `grid` instance variable before every test, so no test in this chapter deals a board of its own.
You will see the tests below start straight in on `grid`, with nothing between the temporaries and the first push.

## The tests come from the rules

Rule one says only mirrors move.
We push the blank corner at `1@1` all four ways and it must still be a blank cell:

```smalltalk
GridTestCase >> testPushBlankCell

	| cell |
	cell := grid at: 1 @ 1.
	grid pushCellSouthFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	grid pushCellNorthFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	grid pushCellWestFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	grid pushCellEastFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell
```

Look at what the test does between two pushes: it asks the grid for the cell again.
That is not clumsiness, it is the point.
A location is a place in the grid, not a cell, and a push changes which cell lives there.

A test that fetched the cell once and then kept asking *that* cell questions would be asking about a cell that may have moved somewhere else.
Every push test follows the same pattern: push, then fetch, then assert.

Rule two says the target never moves, and we give it the same four pushes at `5@1`:

```smalltalk
GridTestCase >> testPushTargetCell

	| cell |
	grid pushCellSouthFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell.
	grid pushCellNorthFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell.
	grid pushCellWestFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell.
	grid pushCellEastFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell
```

Then the mirrors, which is where the rules actually bite.
We write six tests: `testPushIsolatedMirrorCellNorthCase1` and `Case2`, `testPushIsolatedMirrorCellEastCase1` and `Case2`, `testPushIsolatedMirrorCellSouth` and `testPushIsolatedMirrorCellWest`.
Each one pushes once, and then asks three things: what is at the location pushed from, what is at the location pushed into, and what is at the neighbours that must not have moved.

The first takes the lone mirror at `1@2` and pushes it up into the empty corner:

```smalltalk
GridTestCase >> testPushIsolatedMirrorCellNorthCase1

	| cell |
	grid pushCellNorthFromLocation: 1 @ 2.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 1 @ 2.
	self assert: cell class equals: BlankCell.
	cell := grid at: 2 @ 2.
	self assert: cell class equals: BlankCell.
	cell := grid at: 1 @ 3.
	self assert: cell class equals: BlankCell
```

The second takes a mirror out of the block at `3@3`, where the cell above is free but the neighbours to the left and below are mirrors that have to stay where they are:

```smalltalk
GridTestCase >> testPushIsolatedMirrorCellNorthCase2

	| cell |
	grid pushCellNorthFromLocation: 3 @ 3.
	cell := grid at: 3 @ 2.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 3 @ 3.
	self assert: cell class equals: BlankCell.
	cell := grid at: 2 @ 3.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 3 @ 4.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 4 @ 3.
	self assert: cell class equals: BlankCell
```

The four remaining tests are the same two situations in the other directions.
The names are the one weak thing here: `Case1` and `Case2` say only that there are two of them.

What tells them apart is the first line of each — a mirror in open space, or a mirror inside a block — and if you write tests in pairs like this, try to get that difference into the name.

Something worth noticing before any code exists: run these tests against four methods that do nothing at all, and the ones that push a mirror *into another mirror* already pass.
Nothing moved, and nothing was supposed to move.

A test that passes before the code is written tells you nothing about the code — but do not delete it.
It is the test that fails the day the push becomes too eager and starts shoving mirrors into each other.

## One direction at a time, and then none

The four methods the tests call are the obvious ones.
We start them as empty stubs, which is enough to make the tests run instead of erroring:

```st
pushCellNorthFromLocation: aPoint

pushCellEastFromLocation: aPoint

pushCellSouthFromLocation: aPoint

pushCellWestFromLocation: aPoint
```
> **Note.** Stubs only.
> They are replaced further down this chapter.

Now we write the north one for real, in full, with nothing shared:

```st
pushCellNorthFromLocation: aPoint

	| cell swapLoc swapCell |
	cell := self at: aPoint.
	cell class = MirrorCell ifFalse: [ ^ cell ].
	swapLoc := aPoint + (0 @ -1).
	swapCell := self at: swapLoc.
	swapCell isNil ifTrue: [ ^ cell ].
	swapCell class = BlankCell ifFalse: [ ^ cell ].
	self swapCell: cell with: swapCell.
	^ swapCell
```
> **Note.** That is the one-direction version, replaced further down this chapter by `pushCell:fromLocation:`.

Read it and ask how much of it is about north.
One term: `0 @ -1`.
Everything else is the rules, and the rules are the same in all four directions.

Writing the south version by copying this one and changing one number is the moment to stop and split the method in two: a method that knows a direction, and a method that knows the rules.

Here is the method that knows the rules:

```smalltalk
Grid >> pushCell: aGridDirection fromLocation: aPoint
	"Push the cell at aPoint one step in aGridDirection and answer the cell that ended up where
	it started. Only a mirror cell moves, the target never does, and the move happens only when
	the neighbour in that direction is a blank cell, which includes there being a neighbour at
	all. Nothing is really pushed — the mirror and the blank trade places. The beam is taken off
	the board first and put back afterwards if the laser is on, as in rotateCellClockwiseAt:, so
	the cells lit before the push go dark and the new path lights up."

	| cell vector swapLoc swapCell |
	cell := self at: aPoint.
	cell class = MirrorCell ifFalse: [ ^ cell ].
	vector := aGridDirection vector.
	swapLoc := aPoint + vector.
	swapCell := self at: swapLoc.
	swapCell isNil ifTrue: [ ^ cell ].
	swapCell class = BlankCell ifFalse: [ ^ cell ].
	self clearCellsInPath.
	self swapCell: cell with: swapCell.
	self laserIsActive ifTrue: [ self activateCellsInPath ].
	^ swapCell
```

Three things in it are worth a paragraph each.

**The three refusals are written as early returns.** Each one is a rule, each one answers immediately, and you meet them in the order we wrote the rules down: not a mirror, no neighbour, neighbour not blank.

The alternative is one nested condition three levels deep whose `ifTrue:` block holds the real work.
Prefer the early returns.
A method that deals with its impossible cases first and then does its job in a straight line can be read from the top, and a fourth rule is one more line rather than one more level of indentation.

**The method answers a cell**, and which cell it answers is the useful part: the cell that ended up at the location the push started from.
When the push happens, that is the blank cell that came back the other way.

When the push is refused, it is the mirror that never left — and in that case nothing in the grid changed.
So the caller can find out whether anything happened by looking at what it got back, with no second question to the grid.
When a method can either act or decline, have it answer something that tells the two apart.

**The two beam lines** are the lesson of *Bug with target cell* applied to the push.
The cells lit by the old path have to go dark before the mirror moves, and the new path has to be lit afterwards, and only when the laser is actually on.

The order is what makes it right: clear while the old path is still the true one, move, then light the path that is true now.

With the rules in one place, the four direction methods have nothing left to say but their direction:

```smalltalk
Grid >> pushCellNorthFromLocation: aPoint
	"Push the cell at aPoint one row up. One method per direction, each with nothing to say but
	its direction."

	^ self pushCellAction: #north fromLocation: aPoint
```

```smalltalk
Grid >> pushCellEastFromLocation: aPoint
	"Push the cell at aPoint one column to the right."

	^ self pushCellAction: #east fromLocation: aPoint
```

```smalltalk
Grid >> pushCellSouthFromLocation: aPoint
	"Push the cell at aPoint one row down."

	^ self pushCellAction: #south fromLocation: aPoint
```

```smalltalk
Grid >> pushCellWestFromLocation: aPoint
	"Push the cell at aPoint one column to the left."

	^ self pushCellAction: #west fromLocation: aPoint
```

Four one-line methods look like something that ought to be collapsed into one method taking a direction.
They are not, and the reason is the caller.

In two chapters' time, the thing that calls these is a push region that knows it means north and nothing else, and `pushCellNorthFromLocation:` is the whole of what it has to say.
A short method whose name is exactly what the caller means is worth keeping, even when its body is a single send.

## Trading places

The swap is the sentence the rules ended on, written as a method:

```smalltalk
Grid >> swapCell: aCell with: anotherCell
	"Trade the places of two cells. A pushed mirror is never moved, it changes places with the
	blank cell beside it. at:put: writes the new location into the cell, so both cells know
	where they are afterwards, and the copies are taken before the first write because that
	write already changes one of the two locations."

	| oldLocation newLocation |
	oldLocation := aCell gridLocation copy.
	newLocation := anotherCell gridLocation copy.
	self at: newLocation put: aCell.
	self at: oldLocation put: anotherCell
```

We read the two locations into variables before either write happens, and that is not tidiness — the method is wrong without it.
`at:put:` tells the cell where it now sits:

```smalltalk
Grid >> at: aPoint put: aCell
	"Put aCell at aPoint, a column @ row location, and tell the cell where it now sits."

	aCell gridLocation: aPoint.
	self cells at: aPoint put: aCell
```

So by the time the fourth line of `swapCell:with:` runs, `aCell gridLocation` is the *new* location.
Asking the cell for its old place after the move has already been recorded gives the wrong answer, and the wrong answer here is one blank cell overwriting the mirror that just arrived — a push that makes a mirror disappear.

This is a shape to watch for: **a write that changes what you were about to read.**
Reading both values into variables first is the fix, and it costs two lines.

The `copy` on each is one step of further care: the two variables then hold points of their own, and nothing a cell does to its own location later can reach them.

## Four directions as four objects

`pushCell:fromLocation:` asks its direction for a `vector`, and the direction is a class.
We write one class per direction, each answering, on its class side, everything there is to know about one direction:

```smalltalk
GridDirectionNorth class >> directionSymbol
	^#north
```

```smalltalk
GridDirectionNorth class >> vector
	^0@(-1)
```

```smalltalk
GridDirectionSouth class >> vector
	^0@1
```

```smalltalk
GridDirectionEast class >> vector
	^1@0
```

```smalltalk
GridDirectionWest class >> vector
	^-1@0
```

Each of them answers one more thing, which the beam needs rather than the push:

```smalltalk
GridDirectionNorth class >> adjacentInversionSymbol
	^#south
```

```smalltalk
GridDirectionEast class >> adjacentInversionSymbol
	^#west
```

```smalltalk
GridDirectionSouth class >> adjacentInversionSymbol
	^#north
```

```smalltalk
GridDirectionWest class >> adjacentInversionSymbol
	^#east
```

A beam leaving a cell northwards arrives at the next cell from the south.
That is the whole of what `adjacentInversionSymbol` means, and it is a name that tells you none of it until you have seen the four answers side by side — which we do two sections on.

`0 @ -1` is up, because row 1 is the top row.
Adding a vector to a location is the whole of "the cell one step that way", and it is why `pushCell:fromLocation:` has no conditional about direction in it at all.

We find a direction by its symbol:

```smalltalk
GridDirection class >> directionFor: aSymbol
	"Answer the subclass of mine whose direction symbol is aSymbol. The four directions know their
	own symbols, so there is no table here to keep in step with them."

	^self subclasses detect: [:cls | cls directionSymbol = aSymbol]
```

A dictionary from `#north` to `GridDirectionNorth` would do the same job, and it would be one more place for you to edit when a direction is added.

Asking the subclasses means the classes themselves are the table.
The beam uses the same four classes to walk from cell to cell, which is where they came from.

One test covers all four:

```smalltalk
GridDirectionTestCase >> testDirectionSelection

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
```

Four blocks of four lines, one per direction, with the answers written out as literals.

Tests over a small fixed set of objects are allowed to be boring and repetitive.
The alternative — a loop over the four directions computing what to expect — would compute the expected value the same way the code does, and would agree with a mistake.

## Four objects, one table

`testDirectionSelection` is four blocks of four lines, and the name it repeats four times is `adjacentInversionSymbol`.
Nothing in that name says what the answer is for, and the literal beside it says only what the answer is.
A reader who meets `#south` under `GridDirectionNorth` has to be told why, every time.

Four rows say it once:

```smalltalk
GridDirection class >> inspectionDirections: aBuilder
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
```

The rows are fetched through `directionFor:`, the message the game uses to turn a symbol into a direction, so the table comes out in compass order without a list of the four classes being written anywhere in the view.
That is the same trick as `sortedSubclasses` in *Priority decides, not geometry*: a view that lists what it shows is a second place to keep in step.

Inspect `GridDirection` and the tab reads:

```text
GridDirectionNorth  north  (0@ -1)  south
GridDirectionEast   east   (1@0)    west
GridDirectionSouth  south  (0@1)    north
GridDirectionWest   west   (-1@0)   east
```

The last column is the whole point, and it is why the column is titled with a sentence rather than with the selector.
A beam leaving a cell northwards arrives at the next cell from the south, so `adjacentInversionSymbol` is the side the next cell is entered by, and `nextElementIn:` passes it to the step it builds.

The vector column settles something else quickly: north is `(0@ -1)`, because the first row of the board is at the top and `y` grows downwards.
Every sign error in a direction is that line being misremembered.

The tab is class-side, because the question is about the hierarchy rather than about one direction, and a direction has no subclasses of its own to list:

```smalltalk
GridDirection class >> inspectionDirectionsContext: aContext
	"Show the Directions table on the class that has the four directions under it. A direction has
	no subclasses to list, so the tab would be empty on one of them."

	aContext active: self subclasses notEmpty
```

A view is a method, so it gets a test like any other:

```smalltalk
GridDirectionTestCase >> testTheDirectionsTabListsTheFourDirectionsWithTheirVectors
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
```

Three claims: the columns are the four we meant, the rows are in compass order, and one row reads out in full.
`each evaluation value: GridDirectionNorth` is how you ask a Spec column what it would print for an item without opening a window — the column holds the block, and `evaluation` hands it back.

That last assertion is the same four literals `testDirectionSelection` holds, read through the table instead of through the classes.
Two tests over one fact is the right amount here: one of them is the rule, and the other is the only place a reader will go looking for it.

## Writing the move down

The four direction methods do not call `pushCell:fromLocation:` straight away.
They go through one more method, which pushes and then writes the move down:

```smalltalk
Grid >> pushCellAction: aDirectionSymbol fromLocation: aPoint
	"Push the cell at aPoint towards aDirectionSymbol and record the move so that it can be
	undone and counted. The four direction methods become one by looking the direction up from
	its symbol; the move is written only when the cell really moved, which is what the
	comparison of the two locations asks."

	| direction cell swappedCell |
	cell := self at: aPoint.
	direction := GridDirection directionFor: aDirectionSymbol.
	swappedCell := self pushCell: direction fromLocation: aPoint.
	swappedCell gridLocation = cell gridLocation ifFalse: [
		self stackAction: aDirectionSymbol forCell: cell ].
	^ swappedCell
```

We wrote `stackAction:forCell:` in *Bug with target cell*, where a turn was recorded the same way.
It puts the direction and the location on the grid's `movesStack`, which is what a move counter reads, and what an undo written later reads back.

The interesting line is the comparison.
The record has to be written only when something actually moved, and the method finds that out with no extra question, because of what `pushCell:fromLocation:` answers.

On a real push, the cell that came back is the blank from the next square, whose location is now where the mirror used to be — a different location from the mirror's.
On a refused push, the same mirror comes back and the comparison finds one location twice.

Record the move where the move is made.
Not in the mouse handler, which would miss every push done from a test or a script, and not inside `pushCell:fromLocation:`, which is also used to ask whether a push is possible.

One method, one responsibility, and the recording sits in the one place that knows a push was asked for *and* whether it happened.

## What the class tests leave open

The tests we wrote from the rules ask which class sits at which location.
That is enough to catch a mirror that fails to move.
It is not enough for three other questions, and we give each one a test of its own.

The first is the edge of the board.
`self at: swapLoc` answers nil when there is no such cell, and the `isNil` line of `pushCell:fromLocation:` is the one line the tests above never reach:

```smalltalk
GridTestCase >> testPushingAMirrorOffTheEdgeOfTheGridDoesNothing
	"There is no cell beyond the border, so the push finds nothing to trade places with. The rule
	is a rule about the adjacent cell; the demo grid has a mirror on the left edge at 1@2 and one
	on the bottom edge at 1@5."

	grid pushCellWestFromLocation: 1 @ 2.
	self assert: (grid at: 1 @ 2) class equals: MirrorCell.
	grid pushCellSouthFromLocation: 1 @ 5.
	self assert: (grid at: 1 @ 5) class equals: MirrorCell
```

Go through your tests now and then asking the opposite question to the usual one: not *what does this test cover?*
but *which line of the method does no test reach?*.
A nil check is a favourite answer, because the case that produces the nil is usually the one nobody draws a picture of.

The second is the neighbour that is not blank, in both of its forms — another mirror, and the target:

```smalltalk
GridTestCase >> testPushingAMirrorAgainstANonBlankNeighbourDoesNothing
	"A mirror with a blank cell beside it moves; two mirrors beside each other do not move
	together. The target is no different from a mirror here — it is simply not blank, so a
	mirror cannot be pushed into it either."

	grid pushCellEastFromLocation: 2 @ 3.
	self assert: (grid at: 2 @ 3) class equals: MirrorCell.
	self assert: (grid at: 3 @ 3) class equals: MirrorCell.
	grid pushCellEastFromLocation: 4 @ 1.
	self assert: (grid at: 4 @ 1) class equals: MirrorCell.
	self assert: (grid at: 5 @ 1) class equals: TargetCell
```

The target appears twice in the rules — it never moves, and nothing can be pushed into it — and `testPushTargetCell` only covers the first.
The two assertions after the second push cover the other.
When one object is named by two rules, check that you have a test for each of them.

The third is about identity rather than class.
Imagine a push that built a *fresh* `MirrorCell` at the new location and a fresh `BlankCell` at the old one.
Every test so far would pass, and the lean of the mirror — the only property that makes a mirror worth pushing — would quietly be lost:

```smalltalk
GridTestCase >> testAPushedMirrorIsTheSameCellInItsNewPlace
	"A push test that only asks which class sits where leaves room for a push that builds a fresh
	mirror: the classes would still be right and the lean of the mirror, or anything else the
	cell carries, would be lost. Both cells are the ones that were there before, and both know
	their new location."

	| mirror blank |
	mirror := grid at: 3 @ 3.
	blank := grid at: 3 @ 2.
	grid pushCellNorthFromLocation: 3 @ 3.
	self assert: (grid at: 3 @ 2) identicalTo: mirror.
	self assert: (grid at: 3 @ 3) identicalTo: blank.
	self assert: mirror gridLocation equals: 3 @ 2.
	self assert: blank gridLocation equals: 3 @ 3.
	self deny: mirror leansLeft
```

`identicalTo:` asks for the same object, not an equal one, and that is the right question whenever an operation is supposed to *move* something rather than replace it.

The last two assertions are the other half of the same idea: the cells moved, so both of them have to know their new place.
And `self deny: mirror leansLeft` is the property that would have been dropped, named explicitly.

A test that asserts identity is also the cheapest guard against a whole family of mistakes that `equals:` cannot see.
Any time you describe a method with a verb like move, rotate, reorder, or sort in place, ask whether the objects at the end are the objects from the beginning.

And since a push is recorded, a refused push must record nothing:

```smalltalk
GridTestCase >> testAPushThatMovesNothingRecordsNoMove
	"A push that the rules refuse is not a move, so nothing goes on the moves stack. This is what
	pushCellAction:fromLocation: asks when it compares the two locations."

	grid pushCellNorthFromLocation: 1 @ 1.
	grid pushCellWestFromLocation: 1 @ 2.
	grid pushCellEastFromLocation: 2 @ 3.
	grid pushCellSouthFromLocation: 5 @ 1.
	self assert: grid movesStack isEmpty.
	grid pushCellNorthFromLocation: 3 @ 3.
	self assert: grid movesStack size equals: 1
```

Four refusals, one for each reason a push can be refused, and then one real push to prove the stack was working all along.
That last line matters: a test that only asserts a collection is empty passes just as well when nothing is ever added to it.

## The beam, during and after

The two beam lines in `pushCell:fromLocation:` get the same pair of tests as the turn did.
First, a push with the laser already on:

```smalltalk
GridTestCase >> testFireLaserDuringMirrorPush
	"A push made while the laser is on takes the beam off the board and lays it down again along
	the new path. The beam crosses the mirror at 4@5, so pushing that mirror west sends the beam
	a different way and the target goes dark."

	| cell |
	grid fireLaser.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	grid pushCellWestFromLocation: 4 @ 5.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 3 @ 5.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

Then the same push with the laser off, and the firing afterwards:

```smalltalk
GridTestCase >> testFireLaserAfterMirrorPush
	"The same push with the laser off moves the mirror and lights nothing. Firing afterwards
	follows the new path, which no longer reaches the target."

	| cell |
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 5 @ 1.
	self assert: cell isOff.
	grid pushCellWestFromLocation: 4 @ 5.
	grid fireLaser.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 3 @ 5.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

The two tests end with the same three assertions and differ only in when the laser is fired.

That is the pattern to copy whenever an action can be taken in two different states of the system: write one test per state, and put the state in the name.
*During* and *after* are two words doing the work of a paragraph of comment.

Notice also what they assert: never only the flag, always the cells.
`laserIsActive` would be true in both tests at the end and would tell you nothing about where the beam goes.
The target going dark is the thing a player would see.

## One step of the beam

Both of those tests assert cells, and when one of them fails the thing you want to know is where the beam went instead.
`LaserPathElement >> nextElementIn:` is the method that answers it, and it is eight lines with two `nil` guards in them: a reader who wants to know why a beam stopped has to run all eight in their head.

We ask it the same questions in a tab, and lay the answers out as facts:

```smalltalk
LaserPathElement >> inspectionStep: aBuilder
	"Answer the questions nextElementIn: asks about me: the side the beam leaves my cell by, the
	location it lands on, and whether it stops here. 'nowhere' means my cell swallows the light,
	which is the first of the two ways a beam path ends."

	<inspectorPresentationOrder: 1 title: 'Step'>
	| exitSide facts |
	exitSide := self cell exitSideFor: self entrySide.
	facts := OrderedCollection new.
	facts add: 'Cell' -> self cell printString.
	facts add: 'Enters from' -> self entrySide asString.
	facts add: 'Leaves by' -> (exitSide
			 ifNil: [ 'nowhere' ]
			 ifNotNil: [ :side | side asString ]).
	facts add: 'Next location' -> (exitSide
			 ifNil: [ 'nowhere' ]
			 ifNotNil: [ :side |
				 (self cell gridLocation + (GridDirection directionFor: side) vector) printString ]).
	facts add: 'Stops here' -> (exitSide
			 ifNil: [ 'yes' ]
			 ifNotNil: [ 'no' ]).
	^ aBuilder newTable
		  items: facts;
		  addColumn: (SpStringTableColumn title: 'Fact' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  yourself
```

A two-column table over a collection of associations is the plainest way to show a handful of facts about one object, and it reads top to bottom like a sentence.

The first step of the beam on the demo board reads:

```text
Cell           a MirrorCell(1@5 leans right, on)
Enters from    south
Leaves by      east
Next location  (2@5)
Stops here     no
```

and the last step reads:

```text
Cell           a TargetCell(5@1, on)
Enters from    west
Leaves by      nowhere
Next location  nowhere
Stops here     yes
```

`nowhere` twice over is the first of the two guards in `nextElementIn:`: a cell with no exit side for the side the beam came in by swallows the light.
The other guard is a location off the board, and the *Next location* row is what tells you when you are about to meet it.

Read this tab beside the *Directions* table of two sections ago and there is no mystery left in the beam.
One of them says which way a direction goes; the other says where this step of this beam is going, and why it is the last one.

```smalltalk
LaserPathElementTestCase >> testTheStepTabSaysWhereTheBeamGoesNext
	"The Step tab answers, for one step of the beam, the three questions nextElementIn: asks: the
	side the beam leaves by, the location it lands on, and whether it stops here. A target cell
	stops it, which is the row that explains the first of the two nil guards."

	| grid step builder table value target |
	grid := GridExample demoGrid.
	step := LaserPathElement cell: grid startingCell entrySide: #south.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := step inspectionStep: builder.
	self
		assert: (table items collect: [ :each | each key ]) asArray
		equals: #( 'Cell' 'Enters from' 'Leaves by' 'Next location' 'Stops here' ).
	value := [ :fact |
	          (table items detect: [ :each | each key = fact ]) value ].
	self assert: (value value: 'Enters from') equals: 'south'.
	self
		assert: (value value: 'Leaves by')
		equals: (step cell exitSideFor: #south) asString.
	self assert: (value value: 'Stops here') equals: 'no'.
	target := LaserPathElement cell: (grid at: 5 @ 1) entrySide: #west.
	table := target inspectionStep: builder.
	value := [ :fact |
	          (table items detect: [ :each | each key = fact ]) value ].
	self assert: (value value: 'Leaves by') equals: 'nowhere'.
	self assert: (value value: 'Next location') equals: 'nowhere'.
	self assert: (value value: 'Stops here') equals: 'yes'
```

The test asks the table by name — `value value: 'Leaves by'` — rather than by row number, so a fact added in the middle later will not make it fail for the wrong reason.

The *Leaves by* row is asserted against `exitSideFor:` rather than against `#east`, because the point of that row is that it agrees with the model.
The target cell is asserted literally, since `nowhere` is the fact we are here for.

## Checking it

The push is in the model, and nothing on the screen can reach it yet, but you can push the model from a playground.
Open an inspector on the grid and watch its *Board* and *Beam* tabs:

```smalltalk
| grid |
grid := GridExample demoGrid.
grid fireLaser.
grid pushCellWestFromLocation: 4 @ 5.
grid inspect
```

The *Board* tab draws the board after the push, with the mirror now at `3@5`, and the *Beam* tab lists the new path: it leaves the starting cell, turns north at `3@5` instead of `4@5`, runs through the block of mirrors and walks off the left edge at `1@3`.
The target is not on the list, which is the same fact `testFireLaserDuringMirrorPush` asserts.
Click any entry of that list and the inspector opens on a `LaserPathElement`, where the *Step* tab says which side the beam leaves that cell by and where it lands next.

Try a refused push in the same place — `grid pushCellEastFromLocation: 2 @ 3` — and you get no change in either tab.
Then ask `grid movesStack` and it holds one entry, from the push that worked.

Run `GridTestCase`.
You get green on every test in it, and the model now knows both moves of the game.
What it still has no way of knowing is that a player wants one: the four arrows drawn on the board since *Drawing push hints on the game board* do nothing when they are clicked.
That is the next chapter.

# Push cells with the mouse

The model can push a mirror.
The board has been drawing push arrows since *Drawing push hints on the game board*, and since *Click and rotate a cell* a click already travels from the cell element down to the region that decides what it means.

Nothing new has to be written to make the arrows work: the four push regions were wired at the same time as the two rotate ones, and the push methods of the last chapter are what they were waiting for.

What is left to write is the question a push asks before it acts, `canPushCell:fromLocation:`, and the swap that happens once the answer is yes.

So open the game, click the middle of a mirror, and watch it move.

Then do the thing this chapter is actually about.
A feature that has just started working is the best possible moment to go looking for what it broke, because you still remember what you changed.
Sitting back is how a bug reaches the next chapter and takes an hour to find there.

## A push answers a question before it acts

One part of the push does deserve a look of its own, because it is the half of the operation that never moves anything:

```smalltalk
Grid >> canPushCell: aGridDirection fromLocation: aPoint
	"Answer whether the cell at aPoint could be pushed one step in aGridDirection, without moving
	anything. The arrow drawn on a mirror asks this before any click, so that a push the rules
	refuse can be shown as refused. The three questions are the push rules themselves."

	| cell vector swapLoc swapCell |
	cell := self at: aPoint.
	cell class = MirrorCell ifFalse: [^false].
	vector := aGridDirection vector.
	swapLoc := aPoint + vector.
	swapCell := self at: swapLoc.
	swapCell isNil ifTrue: [^false].
	swapCell class = BlankCell ifFalse: [^false].
	^true
```

With, as for the push itself, one short method per direction:

```smalltalk
Grid >> canPushCellNorthFromLocation: aPoint
	"Answer whether the cell at aPoint could be pushed one row up."

	| direction |
	direction := GridDirection directionFor: #north.
	^self canPushCell: direction fromLocation: aPoint.
```

This is the question `CellClickRegionInside class >> canActOnCellAtPoint:cell:withinGrid:` asks, and it is asked in two places that both matter.
A click in a push region that the rules refuse never reaches the grid at all, so the board is not redrawn and no move is counted.

And the arrow the player hovers can be coloured by the answer — green for a push with room, red for one without — which is what a chapter in the next section does with it.

A question written as its own method gets used by things that were not thought of when it was written.
An action that silently declines does not.

It also has a cost, and it is visible if you read the two methods side by side: the three rules are written twice, once in `canPushCell:fromLocation:` and once in `pushCell:fromLocation:`.
The push cannot simply call the question, because it needs the neighbouring cell it found, not a boolean.

So a change to the rules has to be made in two places, and only one of them has tests that would notice.
If you want an exercise, this is a good one: make the push ask the question first and fetch the neighbour afterwards, and check that `GridTestCase` still passes.

The point is not that one shape is right.
It is that you should know where your rules are written down, and how many copies there are.

## Three things a push does that a turn does not

We wired pushing into the same chain as turning, so it is worth asking how the two differ.
Three ways, and each one is a chance for the screen to disagree with the model:

1. the object standing at a location changes. After a turn, `3@3` holds the same mirror it held
   before; after a push, it holds a different cell, of a different class;
2. two locations change at once. A turn touches one cell, a push touches two;
3. the cell under the pointer may stop offering what it was offering. A mirror that has just been
   pushed away is not under the pointer any more; a blank cell is.

The first two are already handled, and by decisions made in *Click and rotate a cell* rather than by anything written for the push.
A renderer holds a location and reads its cell from the grid every time, which is the method that chapter ended on:

```smalltalk
CellRenderer >> cell
	"Answer the cell I render, read from the grid every time. I hold a location and not a cell, so
	a cell that is replaced in the grid does not leave me showing the old one."

	^ self grid at: self cellLocation
```

and a click redraws the whole board rather than guessing which cells it changed.
That is what `redrawCells` is for, and the push is the case we wrote it for.

The third is not handled.
Finding that out is what the rest of the chapter does, in two ways which are the two ways to look at any bug of this kind: walk the code, or ask the objects.

## Walking the code: a halt at the far end

Put a halt in the method the whole chain exists to reach:

```st
	self halt.
```

as the first line of `Grid >> swapCell:with:`.
Then open the game and push a mirror.
The debugger opens with a stack that is the entire feature in one picture, newest frame at the top:

```st
Grid >> swapCell:with:
Grid >> pushCell:fromLocation:
Grid >> pushCellAction:fromLocation:
Grid >> pushCellNorthFromLocation:
CellClickRegionPushNorth class >> mouseUpForCell:withinGrid:
CellClickRegionInside class >> mouseUpWithinCellAtPoint:cell:withinGrid:
MirrorCellRenderer >> mouseUpAt:
LaserGameCellElement >> clickAt:
LaserGameCellElement >> click:
[ :anEvent | self click: anEvent ] in LaserGameCellElement >> initialize
... and a dozen Bloc frames that delivered the event ...
```

Three habits are worth taking from this.

**Put the halt at the far end of the chain, not at the near end.** A halt in the click handler means stepping through everything that already works before reaching anything interesting.

A halt in the model means the stack hands you the route for free: eleven frames, each naming a class and a method, read from the bottom up as the story of one click.
If you ever wonder how a Bloc event reaches your code, this is the cheapest way to find out — halt somewhere deep and read the frames above.

**Click the frames and look at the receivers.** Each frame in the Pharo debugger is an object and its variables.

Clicking `MirrorCellRenderer >> mouseUpAt:` shows which renderer it is and which location it holds; clicking the `Grid` frames shows `aPoint`, `swapLoc` and the two cells.
A stack read this way answers *which* object, not only *which* method, and most of these bugs are about which object.

**Then step out, not over.** The interesting part of a drawing bug is never the model method you halted in; it is what runs *after* the model has changed.

Step out of `swapCell:with:`, out of the two push methods, and keep going until you are back in `clickAt:` watching `board moveMade` run with a grid that has already moved.
That is where the screen is built from the new model, and that is where a view that still believes in the old one shows itself.

A plain `self halt` is fine here because a click happens once.
For anything driven by mouse moves, use the `haltOnce` of *Stopping code that runs too often* instead — and in both cases, take the halt out again before you play on.

A halt left in a method is the most annoying bug in this book, because it looks like the image has frozen.

## Asking the objects: one test over every cell

The other way is to make no change at all, run the action, and then ask every object whether it still agrees with the model.
The *Board*, *Cells* and *Beam* tabs of the grid inspector, built in *Rotate a mirror cell* and *Bug with target cell*, are exactly that question asked by hand: push a mirror in a playground, then look at whether the picture, the list of cells, and the list of beam elements tell the same story.

And what you can look at by hand, a test can look at for all twenty-five cells at once:

```smalltalk
LaserGameCellElementTestCase >> testEveryCellElementAgreesWithItsCellAfterAPush
	"Fire the laser, then push the mirror at 4@5 west to 3@5. Nothing feeds the target at 5@1 any
	more, so it must not be left drawn lit. This is the same walk as after a turn, made through a
	real click on a push arrow: the beam is off the board and back on it before anything is
	drawn, and every cell element shows the cell that stands in it."

	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	self assert: (grid at: 5 @ 1) isOn.
	(board cellElementAt: 4 @ 5) dispatchEvent: (BlClickEvent new
			 position: CellClickRegionInside regionRectangle rightCenter - (1 @ 0);
			 yourself).
	self assert: (grid at: 3 @ 5) class equals: MirrorCell.
	self deny: (grid at: 5 @ 1) isOn.
	1 to: grid numberOfRows do: [ :row |
		1 to: grid numberOfColumns do: [ :column |
			| location element cell |
			location := column @ row.
			cell := grid at: location.
			element := board cellElementAt: location.
			self assert: element renderer class modelClass equals: cell class.
			cell class = TargetCell ifTrue: [
				self
					assert: element children fourth background paint color
					equals: (cell isOn
							 ifTrue: [ LaserGameColors targetCenterColorActive ]
							 ifFalse: [ LaserGameColors targetCenterColorIdle ]) ] ] ]
```

It is the twin of `testEveryCellElementAgreesWithItsCellAfterATurn` from *Bug with target cell*, and the differences between the two are the whole of the point.

The click lands on a push arrow — the right half of the inside region, one pixel inside its edge, which pushes west.
The push is a real push, chosen because it takes the mirror at `4@5` out of the beam and leaves the target fed by nothing.

And the assertions afterwards are identical, because the rule they check does not care what the action was: *the element at every location draws the cell that stands at that location, and the target is drawn lit exactly when it is lit.*

Two tests, one rule, two actions.
That is the right amount of duplication for a guard like this: one test per way of breaking the rule, with a name that says which way.

The three lines before the loop are worth copying as a habit, too.
They assert that the thing the test is about actually happened: the target was lit to start with, the mirror really arrived at `3@5`, and the target really went out.

Without them, a push that silently did nothing would leave every element agreeing with every cell, and the test would pass while testing nothing at all.
**A test of a consequence needs an assertion that the cause took place.**

## Four push rules, asked of every mirror

`canPushCell:fromLocation:` is three questions in a row, and the arrows on the board are drawn from it.
The player sees the answers one mirror at a time, and the test above walked every cell to check the *picture* rather than the rules.

Nobody has yet seen the rules themselves laid out, and there are only forty answers on the demo board: four directions for each of ten mirrors.
We ask all forty at once, in one table.

First a small method to turn a rule's answer into something a column can print:

```smalltalk
Grid >> pushAnswerFor: aGridDirection fromLocation: aPoint
	"Answer 'yes' when the rules allow the mirror at aPoint to be pushed in aGridDirection, and an
	empty string when they do not. The Pushes tab reads the rules through me."

	^ (self canPushCell: aGridDirection fromLocation: aPoint)
		  ifTrue: [ 'yes' ]
		  ifFalse: [ '' ]
```

It belongs on the grid rather than in the view, because it is the grid that knows the rules, and because the test can then read an answer without a presenter.

Then the tab:

```smalltalk
Grid >> inspectionPushes: aBuilder
	"Show one row per mirror on the board and ask the four push rules of each: a yes is a push the
	rules allow from where that mirror stands now. The arrows the player sees are drawn from these
	same four questions."

	<inspectorPresentationOrder: 5 title: 'Pushes'>
	| mirrors |
	mirrors := OrderedCollection new.
	1 to: self numberOfRows do: [ :row |
		1 to: self numberOfColumns do: [ :column |
			| location |
			location := column @ row.
			(self at: location) class = MirrorCell ifTrue: [ mirrors add: location ] ] ].
	^ aBuilder newTable
		  items: mirrors;
		  addColumn: (SpStringTableColumn title: 'Mirror' evaluated: [ :each | each printString ]);
		  addColumn: (SpStringTableColumn title: 'North' evaluated: [ :each |
					   self pushAnswerFor: GridDirectionNorth fromLocation: each ]);
		  addColumn: (SpStringTableColumn title: 'East' evaluated: [ :each |
					   self pushAnswerFor: GridDirectionEast fromLocation: each ]);
		  addColumn: (SpStringTableColumn title: 'South' evaluated: [ :each |
					   self pushAnswerFor: GridDirectionSouth fromLocation: each ]);
		  addColumn: (SpStringTableColumn title: 'West' evaluated: [ :each |
					   self pushAnswerFor: GridDirectionWest fromLocation: each ]);
		  yourself
```

The two loops walk the board row by row, so the rows of the table come out in the order the board reads, and only mirrors get a row.
On the demo board the tab reads:

```text
(4@1)         south  west
(1@2)  north  east   south
(5@2)                       west
(2@3)  north                west
(3@3)  north  east
(5@3)         south  west
(2@4)         south  west
(3@4)  east   south
(1@5)  north  east
(4@5)  north  east          west
```

Every blank in that table is a push the player will click for and not get, and now you can see why before they do.
The arrows drawn on the board and the yeses in this table come from the same method, so one of them cannot be right while the other is wrong.

That is the *Pushes* tab, fifth on the grid after *Board*, *Beam* and *Cells* — and the undo stack takes a fourth in *Undo*.
Its smoke test has to wait: it asserts the number of rows against `grid numberOfMirrors`, and the grid does not learn to count its own mirrors until *Dealing a random board*, where the dealer needs the count to be tested at all.
Asserting `10` instead would make the test agree with the demo board rather than with the rule, so the test is written there, where the two counts can be compared.

Open the tab now, though, and read the row for `1@2`: north, east and south, with west blank because the mirror stands against the left edge.
The next chapter is about an arrow that stayed on the screen after the push it hinted at had been made, and this is the tab that says whether the arrow was ever right.

## What is left

Run the package: everything is green, including the new walk over the board.
So play instead, and watch the one thing neither the stack nor your new test looked at.

Rest the pointer in the middle of the mirror at `1@2`, where the arrow points north into the empty corner.
Click.

The mirror moves up, the board is redrawn — and the arrow is still there, drawn over a blank cell that cannot be pushed anywhere.
Nothing is wrong in the model, nothing is wrong in the picture of the cells, and something on the screen is a lie.

That is the third item of the list at the top of this chapter, and it is the next chapter.

## Checking it

```smalltalk
| grid board space |
grid := GridExample demoGrid.
grid fireLaser.
board := LaserGameBoardElement on: grid.
space := BlSpace new.
space title: 'Push with the mouse'.
space extent: (LaserGameBoardElement extentForGrid: grid) + 40.
space root
	background: Color veryLightGray;
	addChild: board.
board position: 20 @ 20.
space show
```

You get mirrors that move the way the arrow points, mirrors with no room that do not move at all, a beam that follows them, and a target that lights up and goes dark as the path reaches it or misses it.
Both moves of the game now work with the mouse.

# Visual bug with push

Here is the bug the last chapter ended on, in the four steps that produce it.
We find where the stale hint is kept, write the point down and read it back, and cover both halves of the rule with tests.

1. rest the pointer in the middle of the mirror at `1@2`, in the lower half, so the north arrow
   appears — the empty corner at `1@1` is where the mirror can go;
2. click;
3. the mirror moves up to `1@1`;
4. the arrow is still drawn, over the blank cell that is now at `1@2`.

Nothing moves afterwards, because nothing more happens.
The pointer has not moved, so no mouse event arrives, so nobody asks the question again.
A blank cell can be pushed nowhere, and the board is showing the player an arrow that promises a move that does not exist.

## Model or drawing?

Ask the question of *Bug with target cell* first, because it is cheap and it halves the search you have to do: is the model wrong, or is the drawing wrong?

Push the mirror in a playground and look at the grid:

```smalltalk
| grid |
grid := GridExample demoGrid.
grid pushCellNorthFromLocation: 1 @ 2.
grid inspect
```

The *Cells* tab lists `a MirrorCell(1@1 leans right, off)` and `a BlankCell(1@2, off)`.
The *Board* tab draws the mirror in the corner.

The model is right, and it is right in every detail — so this time the fault is entirely in the view, which is a different kind of search for you.
There is no `Grid` method to read.
What there is, is one object that holds state about something that changed behind its back.

That is the question to carry from this chapter: **which view is holding on to something the model has replaced?**

## What a hint is made of

Follow the arrow back to where it comes from.
A cell element shows an arrow because of three statements written in *Detecting mirror cell click regions* and *Drawing push hints on the game board*:

- a mouse move hands the cell element a point;
- the element asks its renderer which region that point falls in, and keeps the answer in
  `hintRegion`;
- `updateHintElement` turns the region it holds into a child element.

Read that chain with a push in mind.
The *input* to the whole thing is a point.
The *output* is a region, and then a picture of a region.
And a push does not change the point: it changes which cell the point is in, which means the same input now has a different right answer.

Then look at what the redraw of *Click and rotate a cell* did with that:

```st
	region := hintRegion.
	...
	hintRegion := region.
	self updateHintElement
```

It saves the region, draws the cell again, and puts the region back.
For a turn that is exactly right: the mirror is still there, the pointer is still in the same part of it, the arrow is still the truth.
For a push it is exactly wrong, and in the most misleading way possible, because the method looks careful.
It *is* careful — it carefully preserves the wrong thing.

> **An element that keeps an answer across a change of the model keeps a stale answer.
> An element that keeps the question can ask it again.**

The fix is to store the point instead of the region, and that is one slot:

```smalltalk
BlElement << #LaserGameCellElement
	slots: { #renderer . #hintRegion . #hintElement . #hintPosition };
	tag: 'Graphics';
	package: 'Laser-Game'
```
> **Note.** *Better cursor management* adds a fifth slot, for the cross hair drawn with the arrow.

`hintRegion` stays, because `updateHintElement` needs something to draw and comparing the new region with the old one is what keeps the arrow from being rebuilt on every pixel of movement.
What changes is that `hintRegion` is now a *cache* of an answer that can always be computed again, and `hintPosition` is the thing it is computed from.

## Writing the point down, and reading it back

The point is written where the pointer is heard from:

```st
LaserGameCellElement >> showPositionHintAt: aPoint
	"Keep the hint my renderer answers for aPoint, which is in my own coordinates, and show it.
	My renderer decides: a mirror answers the region the point falls in, every other cell answers
	nothing. A move within the same region changes nothing about the arrow, so it is built once.
	The point is kept, because a redraw has to ask the question again for the cell that stands in
	me then."

	| region |
	hintPosition := aPoint.
	region := self renderer hintRegionAt: aPoint.
	region = hintRegion ifTrue: [ ^ self ].
	hintRegion := region.
	self updateHintElement
```
> **Note.** *Better cursor management* makes the early return move the cross hair before it answers, since the cross hair follows every pixel while the arrow does not.

and forgotten where the pointer leaves:

```smalltalk
LaserGameCellElement >> clearPositionHint
	"Forget my hint: the pointer is no longer in me, so the arrow goes too, and so does the point
	it was read at."

	hintPosition := nil.
	hintRegion ifNil: [ ^ self ].
	hintRegion := nil.
	self updateHintElement
```

`hintPosition := nil` is the first line, before the early return.
That matters: the early return is there for the common case of a cell that had no hint to begin with, and it would otherwise skip the line that forgets the point.

A guard put in for one reason quietly covering a second thing is a regular source of bugs — when you add a line to a method that has an early return in it, decide deliberately which side of the return it goes.

And the redraw asks the question again instead of restoring the answer:

```st
LaserGameCellElement >> redraw
	"Draw my cell again after the model changed. The cell standing at my location may be another
	one than before, since a push swaps two cells, so the renderer is chosen again — and so is
	the hint, at the point the pointer was last seen at, because an arrow kept across a redraw
	is the arrow of the cell that has moved away. A blank cell offers no push, so the arrow of
	the mirror that left goes with it."

	| grid location point |
	grid := self renderer grid.
	location := self gridLocation.
	point := hintPosition.
	self removeChildren.
	hintElement := nil.
	hintRegion := nil.
	self renderer: (CellRenderer rendererFor: (grid at: location) grid: grid).
	self renderer renderBackgroundOn: self.
	self renderer renderBorderOn: self.
	self renderer renderContentsOn: self.
	point ifNotNil: [ self showPositionHintAt: point ]
```
> **Note.** *Drawing the laser beam* adds the beam to the middle of this method, and *Better cursor management* the cross hair to its bookkeeping.

The last line is the whole fix, and it works because we wrote `showPositionHintAt:` as a method that takes a point and answers nothing.
The redraw can call it exactly as a mouse move does.
When a method's only input is its argument, anybody can call it — including code that has no event in its hands.

Read the order once more: keep the point, throw everything away, choose the renderer for the cell that is there *now*, draw it, then ask the hint question again *of that cell*.
The emptied cell asks its new renderer, which is a `BlankCellRenderer`, which answers nil, and no arrow is drawn.
Nothing in the method knows what a push is.

## Two tests, because the rule has two halves

The obvious test is the bug:

```smalltalk
LaserGameCellElementTestCase >> testTheArrowGoesWhenAPushEmptiesTheCellUnderThePointer
	"A push moves a mirror out of the cell the pointer is in. The renderer is chosen again when a
	cell is drawn again, so the picture of the cell is right — but the hint drawn over it would
	be the one of the cell that moved away. The pointer has not moved, and a blank cell offers no
	push, so the arrow goes and the emptied cell looks like any other blank cell."

	| element blank |
	element := board cellElementAt: 1 @ 2.
	blank := board cellElementAt: 2 @ 2.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle bottomCenter - (0 @ 1);
			 yourself).
	self assert: (element children includes: element hintElement).
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionInside regionRectangle bottomCenter - (0 @ 1);
			 yourself).
	self assert: element cell class equals: BlankCell.
	self assert: element hintRegion isNil.
	self assert: element hintElement isNil.
	self assert: element children size equals: blank children size.
	self assert: (board cellElementAt: 1 @ 1) hintElement isNil
```

It is the four steps of the first paragraph, written down: a move event into the lower half of the mirror, an assertion that there *is* an arrow, the click, and then four assertions that there is not.

Those four are worth reading one by one, because they are four different ways of asking the same thing and the test needs all of them:

- `hintRegion isNil` — the element holds no region. That is the state.
- `hintElement isNil` — it holds no arrow element either. The two are set together and a bug that
  cleared one and not the other would be invisible to the first assertion.
- `children size equals: blank children size` — the emptied cell has exactly as many children as a
  cell that was blank all along, `2@2`. This is the assertion that catches *anything* left behind,
  not only an arrow, and it does it without the test having to know how a blank cell is built.
- the last one looks at a different cell: the mirror arrived at `1@1`, and it must not have gained an
  arrow on the way. Nobody is pointing at `1@1`.

Comparing an object with another object that is supposed to look the same — the emptied cell against a cell that was always blank — is a trick worth having.
It states the rule as *indistinguishable from* rather than as a list of properties, and it keeps on being true when the drawing changes.

The other half of the rule needs its own test, and without it the "fix" could as well have been to throw every hint away on every redraw.
A turn leaves the mirror where it is, so the arrow under the pointer is still the right one and has to survive:

```st
LaserGameCellElementTestCase >> testTheArrowStaysWhenTheCellUnderThePointerStillOffersIt
	"The other half of the same rule: a turn leaves the mirror where it is, so the hint under the
	pointer is still the right one and the arrow survives the redraw. The hint is read from the
	cell that stands there after the action, not kept and not dropped."

	| board element childCount |
	board := LaserGameBoardElement on: GridExample demoGrid.
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionRotateClockwise.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self assert: element cell class equals: MirrorCell.
	self assert: element hintRegion equals: CellClickRegionRotateClockwise.
	self assert: (element children includes: element hintElement).
	self assert: element children size equals: childCount + 1
```
> **Note.** *Better cursor management* counts two children per hint rather than one, since the cross hair arrives with the arrow.

Whenever you fix a bug by removing something, write the test that the thing is still there when it should be.
"The arrow goes when it must" and "the arrow stays when it may" are two tests, and the second one is the one that stops the next person from fixing a different bug by deleting your line.

## What this bug was really about

Three chapters of this section have now ended in the same place, and it is worth saying once, plainly:

- in *Bug with target cell*, a cell stayed lit because the beam had been computed from a mirror that
  had since turned;
- in *Clean up left-over hints*, an arrow stayed because a leave event never arrived;
- here, an arrow stayed because the region had been computed from a cell that had since moved.

Every one of them is the same shape: **a value computed from something that changed afterwards.**
The question that finds all three is not *where is the drawing code wrong?*
but *what did I compute this from, and is that thing still the same?*

And the three answers were different, which is the honest part.
The first re-computed the derived value at the moment of the change.
The second enforced an invariant on the way in.
The third stopped storing the answer and stored the question.
There is no single rule to apply; what carries over is the question to ask.

## Checking it

Run the package: everything is green.
Then open the board and play with it, because you have to see this one:

```smalltalk
| grid board space |
grid := GridExample demoGrid.
grid fireLaser.
board := LaserGameBoardElement on: grid.
space := BlSpace new.
space title: 'Push and the arrow'.
space extent: (LaserGameBoardElement extentForGrid: grid) + 40.
space root
	background: Color veryLightGray;
	addChild: board.
board position: 20 @ 20.
space show
```

Hold the pointer still in the lower middle of a mirror with room above it and click: the mirror goes up, the beam follows, and the cell under the pointer is a plain blank cell with nothing drawn on it.

Hold the pointer on the rim of a mirror and click: the mirror turns, and the arrow is still there, ready for the next click.
Move one pixel and you get the arrow back where it is due.

That is the section finished.
The board is playable with the mouse: both moves work, the beam follows them, the hints appear and go when they should.

What the game still has no notion of is the player — there is no move counter, no sense of a window around the board, and no cursor that says the board is something to interact with.
That is the next section.