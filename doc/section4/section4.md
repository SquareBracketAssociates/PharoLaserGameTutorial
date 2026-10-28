# Communicate with arrow colours

The game plays.
From here on the chapters are a list of things that could be better, and the first one is what the player notices first.

In this chapter we make the renderers answer a colour for each hint arrow, green where the click would work and red where it would not, so an arrow says both what a click does and whether the board will let it.

A hint arrow says which way a click would move a cell.
It says nothing about whether it could.
Rest the pointer in the middle of the mirror at `4@1` of the demo grid and you get four push arrows on offer, one for each direction, and only two of those pushes can happen: north is off the board, and east is the target, which never moves.

An arrow that promises a move the grid will refuse is worse than no arrow at all, because the only way you find out is to click.

The grid already knows the answer.
In this chapter we carry it to the player, in colour.

## Two colours

```smalltalk
LaserGameColors class >> allowActionArrowColor
	"Answer the colour of a hint arrow for a move that can be made. The arrow says which way a
	click would move a cell; this colour says the click would work."

	^Color green
```

```smalltalk
LaserGameColors class >> denyActionArrowColor
	"Answer the colour of a hint arrow for a move that is refused. An arrow that promises a move
	the grid would not make is worse than no arrow, so the colour is the warning."

	^Color red
```

Plain green and plain red, which are too bright and too harsh over the cells.
Keep them anyway.

They are unmistakable while we build the behaviour, and the chapter *Add A Counter and Window Colors* gives the whole game a palette and tones them down then.
Choosing a colour you can see is a reasonable thing to do before choosing a colour you can live with.

Note where we put them: `LaserGameColors`, with every other colour of the game.
No `Color green` appears in a renderer or an element.
The reason is not tidiness — it is that a colour is a decision, and a decision that is written in twelve places is twelve decisions.

## The question already exists

The arrow needs to know whether a push is allowed.
We wrote that question in *Push cells with the mouse*, because a click had to be refused before it could be coloured:

- `Grid >> canPushCell:fromLocation:` answers a Boolean and changes nothing;
- the four `canPushCell<Direction>FromLocation:` methods name a direction each;
- each push region class answers `canPushCell:withinGrid:` by asking the grid for its own direction;
- `CellClickRegionInside class >> canActOnCellAtPoint:cell:withinGrid:` hands the question to the
  push region the point falls in;
- `CellClickRegionOutside class >> canActOnCellAtPoint:cell:withinGrid:` answers `true`, because a
  mirror can always be turned;
- and `CellClickRegion class >> canActOnCellAtPoint:cell:withinGrid:`, from *Click and rotate a
  cell*, answers `false`, so the ignore margin needs no special case.

So we change nothing in the model here.
A question that answers a value, asked of the object that holds the state, gets used by callers that did not exist when it was written — the click used it to refuse an action, and the arrow is about to use it to choose a colour.

**Separating the question from the action is what makes the question reusable.**

That is worth noticing as a pattern, because the opposite is the normal mistake: a method named `push` that silently does nothing when it cannot, with no way to ask it in advance.
The view then has nothing to show the player, and ends up re-deriving the rules itself.

## The renderer answers the colour

Which colour a point deserves is a question about the cell, so we let the renderer answer it — next to `hintRegionAt:`, and split the same way.
The base renderer is the cell that reacts to nothing:

```smalltalk
CellRenderer >> hintColorAt: aPoint
	"Answer the colour a hint arrow is painted in at aPoint, in the coordinates of my cell. My
	cell reacts to nothing, so the question does not arise here and a neutral grey is answered;
	the mirror renderer asks the click region whether the move is allowed."

	^ LaserGameShapes arrowColor
```

and the mirror renderer is the one that has something to say:

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

Read the shape of that method rather than its length.
There is no test on the direction of the push, no test on what the neighbour is, and no test on the kind of the cell.
There is one message sent to the region the point falls in, and two colours.

Every rule about what can be pushed where is behind `canActOnCellAtPoint:cell:withinGrid:`, and a new rule — a wall, a cell that is nailed down, a second mirror that may be pushed only sideways — goes in there and reaches the screen without us opening this method again.

The grey the base renderer answers has been in `LaserGameShapes` since we drew the arrows:

```smalltalk
LaserGameShapes class >> arrowColor
	"Answer the colour an arrow is painted in when nobody says otherwise. A caller that knows
	whether the move it hints at is allowed sets its own colour instead."

	^ Color gray
```

Only a mirror ever shows a hint, so you never see that grey on the board.
It is what the method answers when a renderer with no hints to offer is asked anyway.
A default that is never used is not dead code here: it is what lets the caller ask every renderer the same question.

## The element paints it

An arrow is a child element, so we colour it by setting a background:

```st
LaserGameCellElement >> updateHintElement
	"Show the picture of the hint I hold, and no other, in the colour of what a click there would
	do. The arrow is a child of mine, so the previous one goes when it is removed and no arrow is
	ever left behind. The colour comes from my renderer: green when the move is allowed, red when
	it is refused. A region without a picture, such as the ignore margin, answers nothing and
	leaves me with no hint at all."

	hintElement ifNotNil: [ :each | self removeChild: each ].
	hintElement := hintRegion ifNotNil: [ :region |
		               region hintElementOfExtent: CellRenderer hintArrowExtent ].
	hintElement ifNotNil: [ :each |
		each
			background: (self renderer hintColorAt: hintPosition);
			position: CellRenderer hintArrowOffset.
		self addChild: each ]
```
> **Note.** *Better cursor management* adds the cross hair to this method, which is drawn with the arrow and has to end up as the child on top of it.

Two things in there are worth a sentence each.

We read the colour at `hintPosition`, the point the pointer was last seen at, which we introduced in *Visual bug with push* so that a redraw could ask for the hint again.

The same slot answers a second question now, and it answers it correctly for free: after a push, the cell under the pointer is a different cell, the renderer is a different renderer, and we read the colour from that one.
Storing the question rather than the answer keeps paying.

And we put `background:` inside the guarded block, not cascaded onto the expression above it.
`hintElementOfExtent:` answers `nil` for a region with no picture — the ignore margin — and a cascade on the outer expression would send `background:` to that `nil`.

When a method can answer nil, every use of its answer belongs inside an `ifNotNil:`, including the ones that look like formatting.

Nothing else changes.
`showPositionHintAt:` still rebuilds the arrow only when the region changes, which is enough: the board is still while the pointer moves within one region, so the colour cannot change without the region changing.
A push does change the board, and that path goes through `redraw`, which asks for the hint again from scratch.

## Two tests

The first one is this chapter in one cell.
The mirror at `4@1` can go south, where `4@2` is blank, and cannot go east, where the target stands.
Same cell, same pointer, two colours:

```smalltalk
LaserGameCellElementTestCase >> testAPushArrowIsColouredByWhetherThePushIsAllowed
	"The arrow says which way a click would move the cell; its colour says whether it could. The
	mirror at 4@1 can be pushed south, where 4@2 is blank, and cannot be pushed east, where the
	target stands. Same cell, same pointer, two colours."

	| element |
	element := board cellElementAt: 4 @ 1.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle topCenter + (0 @ 1);
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushSouth.
	self
		assert: element hintElement background paint color
		equals: LaserGameColors allowActionArrowColor.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle leftCenter + (1 @ 0);
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushEast.
	self
		assert: element hintElement background paint color
		equals: LaserGameColors denyActionArrowColor
```

Each half asserts the region before it asserts the colour.
That is not padding.
If the point ever lands in another region — a changed cell size, a changed dividing line — you get a colour assertion that fails with no hint as to why, and the two-line form says *which* of the two claims broke.

**When a test asserts something derived, assert the thing it was derived from first.**

`element hintElement background paint color` is how we read a colour back off a Bloc element.
The background is a paint, and the paint is where the colour is.
Reading it back in the test, rather than asserting that `hintColorAt:` was asked, is what makes this a test of the arrow the player sees.

Before we wrote the two methods above, both colour assertions failed with:

```text
Got Color gray instead of Color green.
```

which is the grey we set out to get rid of — the default arriving because nobody had overridden it yet.
A first failure that names the old behaviour is a good sign: it means the test is looking at the right thing.

The second test holds the other half of the rule, the line that says a turn is never refused:

```smalltalk
LaserGameCellElementTestCase >> testARotateArrowIsAlwaysColouredAsAllowed
	"A mirror can always be turned, in either direction, whatever stands around it: the outside
	region answers true in one line. So both rotate arrows are drawn in the colour of a move
	that is allowed, even on a mirror that is boxed in."

	| element |
	element := board cellElementAt: 3 @ 3.
	{ (CellClickRegionOutside regionRectangle topLeft
	  -> CellClickRegionRotateClockwise).
	(CellClickRegionOutside regionRectangle bottomLeft - (0 @ 1)
	 -> CellClickRegionRotateCounterClockwise) } do: [ :each |
		element dispatchEvent: (BlMouseMoveEvent new
				 position: each key;
				 yourself).
		self assert: element hintRegion equals: each value.
		self
			assert: element hintElement background paint color
			equals: LaserGameColors allowActionArrowColor ]
```

The cell we pick is deliberate: `3@3` is a mirror with a mirror on every side of it, so every push from it is refused and every push arrow on it is red.

Both rotate arrows are still green.
A test of "always" is worth little on a cell where the answer would be green anyway — **pick the case where the wrong implementation would give the other answer.**

## Checking it

Run the package: you get green.
Then open a board on the demo grid and move the pointer slowly around the mirror at `4@1`:

```smalltalk
| grid board space |
grid := GridExample demoGrid.
grid fireLaser.
board := LaserGameBoardElement on: grid.
space := BlSpace new.
space title: 'Arrow colours'.
space extent: (LaserGameBoardElement extentForGrid: grid) + 40.
space root
	background: Color veryLightGray;
	addChild: board.
board position: 20 @ 20.
space show
```

The arrow turns from green to red as the pointer crosses from the lower triangle of the inside region to the left one: south is allowed, east is the target.

On the mirror at `3@3`, boxed in on all four sides, you get red on every push arrow and green on both rotate arrows.
The player can now see which clicks are worth making.

The arrows are easier to read than they were, and the colours are indeed too bright.
What we still miss is any mark of *where* the pointer is, which is the next chapter.

# Better cursor management

The arrows now say what a click would do and whether it would work.
The thing in the way of reading them is the pointer itself: a cell is small, the arrow fills most of it, and the pointer sits exactly on top of the arrow it is asking about.

Rather than change the pointer, we draw a small cross hair inside the cell at the place the pointer is, which means one more child element, one more number on the renderer, and three callers that each gain a single line.

There is a second reason to want a mark on the board, and it is the more important one.
A mirror cell is cut into six regions, and a single pixel decides between a push north and a push west.

The player has no way to see which point the click will be judged by.
The tip of the pointer is a guess.

So we draw a small cross hair in the cell, centred on the point under the pointer, and show it exactly when a hint arrow is shown.

## Why not change the pointer

Bloc can change the pointer.
`BlElement >> mouseCursor:` names the cursor an element wants, and the mouse processor walks up from the element under the pointer, takes the first cursor it finds, and hands it to the host window.

We do not use it, for two reasons worth separating.

The first is a dependency.
A cursor in Pharo is an image owned by the host window, not an element, and we build the game entirely out of elements it draws itself.
Keeping it that way is what lets us test every picture in it without a window.

The second is that it would answer the wrong question.
A different pointer shape still sits at the same place and still hides the same pixels; it tells the player *that* something can be clicked, not *where* the click lands.

A mark drawn in the cell, under the pointer, answers both: it is visible beside the arrow, and it is at the point the regions are asked about.

When a framework offers the obvious mechanism and you decide against it, write down which of the two reasons applies.
A dependency you are avoiding and a question you are answering differently are not the same argument, and the next reader needs to know which one to re-examine.

## The shape, and the one number

We wrote the shape itself in *Creating custom shapes*: `LaserGameShapes class >> crossHairElementOfExtent:` answers a transparent element of the size asked with two bars crossing at its centre, each arm a third of the box.
Nothing about it changes here.
All we have to choose is how big the box is:

```smalltalk
CellRenderer class >> crossHairExtent
	"Answer the size the cross hair under the pointer is drawn at. The shape makes its arms a
	third of the box it is given, so a box of one cell keeps the arms in proportion with the
	cell."

	^ self cellExtent
```

A whole cell for a mark that is a third of a cell.
That reads oddly until you remember the shape puts its arms at a third of whatever box it is given: the box is the measuring frame, not the ink.

And answering `self cellExtent` means the mark follows the cell size for free, which the next chapter — *Making larger cells* — immediately cashes in.

Every size in the game is a method like this one, on the class side of `CellRenderer`, and we derive every one of them from `cellExtent`.
One number is the size of the game.

## One more slot

The cell element gains a fourth piece of hint bookkeeping:

```smalltalk
BlElement << #LaserGameCellElement
	slots: { #renderer . #hintRegion . #hintElement . #hintPosition . #crossHairElement };
	tag: 'Graphics';
	package: 'Laser-Game'
```

and one method that keeps it right:

```smalltalk
LaserGameCellElement >> updateCrossHairElement
	"Mark the point the pointer is at, whenever I show a hint, and mark no point when I show
	none. The mark is there because the pointer itself hides the arrow under it: the game does
	not replace the pointer picture, so the cross hair is drawn in the cell instead, centred on
	the point a click would use. It is built when the hint is and then only moved, since the
	pointer sends an event for every pixel it crosses."

	hintElement ifNil: [
		crossHairElement ifNotNil: [ :each |
			self removeChild: each.
			crossHairElement := nil ].
		^ self ].
	crossHairElement ifNil: [
		crossHairElement := LaserGameShapes crossHairElementOfExtent:
			                    CellRenderer crossHairExtent.
		self addChild: crossHairElement ].
	crossHairElement position:
		hintPosition - (CellRenderer crossHairExtent // 2)
```

Read it as three statements, in the order you meet them:

1. **No arrow means no mark.** If there is no hint element, remove the cross hair if there is one and
   answer. The mark is tied to the arrow, not to the pointer, and this is the line that ties it.
2. **Build it once.** If there is no cross hair yet, build one and add it as a child.
3. **Move it every time.** Set its position so that its centre is at `hintPosition`.

That split matters, because of how often this method runs.
The pointer sends a move event for every pixel it crosses.
Building a fresh element per pixel would mean allocating, adding, and removing children dozens of times a second; moving one element is a position change.

**When something changes continuously, build the element once and change the one property that moves.** The arrow, which only changes when the region does, is handled the other way round: it is rebuilt, rarely.

Note also the arithmetic, which is the whole of the centring: `hintPosition - (extent // 2)`.
An element's `position:` is its top left corner, and the point we want at its centre is `hintPosition`, so the corner goes half an extent up and to the left.

Two integer divisions and a subtraction, in one place, with no offsets to carry around — because `hintPosition` is already in the coordinates of this element.

And the accessor, which the tests ask through:

```smalltalk
LaserGameCellElement >> crossHairElement
	"Answer the cross hair I show under the pointer, or nil when I show none."

	^ crossHairElement
```

## Three callers, one line each

`updateHintElement` gains the call at its end, plus three lines that drop the old cross hair before it:

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

Dropping a child that is about to be built again looks wasteful, and it is there for a reason you cannot see in the method: **children are drawn in the order they were added.**
The cross hair must be on top of the arrow, so we add it after the arrow.

This method has just removed and re-added the arrow, which puts the arrow last — so we drop the cross hair and rebuild it to put it back on top.

This is worth knowing in general.
In a tree of elements, overlap is decided by order of addition, not by any property you can set afterwards.
When one child must stay over another, what you control is *when* it is added.

`showPositionHintAt:` calls it on the path that used to return early:

```smalltalk
LaserGameCellElement >> showPositionHintAt: aPoint
	"Keep the hint my renderer answers for aPoint, which is in my own coordinates, and show it.
	My renderer decides: a mirror answers the region the point falls in, every other cell answers
	nothing. A move within the same region changes nothing about the arrow, so it is built once;
	the cross hair marks the point itself and moves with every event. The point is kept, because
	a redraw has to ask the question again for the cell that stands in me then."

	| region |
	hintPosition := aPoint.
	region := self renderer hintRegionAt: aPoint.
	region = hintRegion ifTrue: [ ^ self updateCrossHairElement ].
	hintRegion := region.
	self updateHintElement
```

That one line is the whole of "the mark follows the pointer".
The guard used to mean *nothing to do*; it now means *nothing to do about the arrow*.
The two things the method keeps up to date have different rates, and the early return is exactly the fork between them.

When you add a second piece of state to a method that already has a fast path, check what the fast path skips.
A guard that was right for one thing is the most likely place for the second thing to be forgotten.

And `redraw`, which rebuilds a cell after the model changed, forgets the old cross hair along with the old arrow:

```st
LaserGameCellElement >> redraw
	"Draw my cell again after the model changed. The cell standing at my location may be another
	one than before, since a push swaps two cells, so the renderer is chosen again — and so is
	the hint, at the point the pointer was last seen at, because an arrow kept across a redraw
	is the arrow of the cell that has moved away. A blank cell offers no push, so the arrow of
	the mirror that left goes with it, and the cross hair with the arrow."

	| grid location point |
	grid := self renderer grid.
	location := self gridLocation.
	point := hintPosition.
	self removeChildren.
	hintElement := nil.
	hintRegion := nil.
	crossHairElement := nil.
	self renderer: (CellRenderer rendererFor: (grid at: location) grid: grid).
	self renderer renderBackgroundOn: self.
	self renderer renderBorderOn: self.
	self renderer renderContentsOn: self.
	point ifNotNil: [ self showPositionHintAt: point ]
```
> **Note.** *Laser on blank cell* adds one line to this method, so that a cell drawn again after the laser was fired draws the beam with it.

`self removeChildren` has already taken the cross hair off the screen; the `crossHairElement := nil` is what stops the element from believing it still has one.
Whenever a slot holds a child, removing the child and clearing the slot are two steps, and forgetting the second leaves you with an object that disagrees with the screen.

The other half needs nothing at all.
The pointer leaving a cell runs `clearPositionHint`, which goes through `updateHintElement`, which calls `updateCrossHairElement`, which finds no arrow and removes the mark.
One path, which we wrote two chapters ago, with no new case to add.

## Three tests

The mark is where the pointer is, and it is the size the constant says:

```smalltalk
LaserGameCellElementTestCase >> testACrossHairMarksThePointWhereAHintIsShown
	"The pointer itself gets in the way of the hint it asks for, so a cross hair is drawn in the
	cell, centred on the point a click would use. An element is measured in a layout pass, so
	what it was asked for is read from its constraints."

	| element point extent |
	element := board cellElementAt: 4 @ 1.
	point := CellClickRegionInside regionRectangle center.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: point;
			 yourself).
	extent := CellRenderer crossHairExtent.
	self assert: element crossHairElement isNotNil.
	self
		assert:
		element crossHairElement constraints horizontal resizer size
		@ element crossHairElement constraints vertical resizer size
		equals: extent.
	self
		assert: element crossHairElement constraints position + (extent // 2)
		equals: point
```

The last two assertions read the element's `constraints` rather than its `extent` and `position`.
That is not a detour, it is the only honest way we can test this outside a window.

In Bloc, `extent:` and `position:` record what an element *asked for*, in its constraints; the values it actually gets are computed in a layout pass, and no layout pass happens for an element that was never drawn.
A test that asserted `extent` would be asserting the default, and would pass whatever the code did.

> **Assert what the code decided, not what a later stage would have computed from it.**

The mark moves within one region, which is the case the arrow deliberately ignores:

```st
LaserGameCellElementTestCase >> testTheCrossHairFollowsThePointerWithinOneRegion
	"The arrow is built once per region, since it does not change while the pointer stays in one,
	but the cross hair marks a point and moves with every event."

	| board element first second extent |
	board := LaserGameBoardElement on: GridExample demoGrid.
	element := board cellElementAt: 4 @ 1.
	extent := CellRenderer crossHairExtent.
	first := CellClickRegionInside regionRectangle center.
	second := first + (0 @ 4).
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
> **Note.** *A missed bug* replaces the four pixels of `second` with a quarter of the inside region, so that the second point is in the same push region at any cell size.
> The four here is a constant that happens to work at the size the cell is now, which is precisely the kind of thing that chapter is about.

The assertion in the middle is what makes the test mean what its name says: both points must be in the *same* region, or the test would be watching the arrow change rather than the mark move.

And the mark appears exactly when a hint does — not in the ignore margin, not after the pointer leaves, and never on a cell that offers nothing:

```smalltalk
LaserGameCellElementTestCase >> testTheCrossHairIsShownExactlyWhenAHintIs
	"The cross hair appears with the hint and goes in the two places the hint goes: a point that
	offers no action, and the pointer leaving. A cell that offers nothing, like the blank one at
	2@2, never shows either."

	| mirror blank |
	mirror := board cellElementAt: 4 @ 1.
	blank := board cellElementAt: 2 @ 2.
	mirror dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: mirror crossHairElement isNotNil.
	mirror dispatchEvent: (BlMouseMoveEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: mirror hintRegion equals: CellClickRegionIgnore.
	self assert: mirror hintElement isNil.
	self assert: mirror crossHairElement isNil.
	mirror dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: mirror crossHairElement isNotNil.
	mirror dispatchEvent: BlMouseLeaveEvent new.
	self assert: mirror crossHairElement isNil.
	blank dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: blank crossHairElement isNil
```

One test, five situations, in the order you would produce them as a player: into the cell, into the ignore margin, back in, out of the cell, and then onto a cell that has nothing to offer.

A rule with the word *exactly* in it needs both halves tested — when it appears **and** when it does not — and the cheapest way to write that is one test that walks through the cases rather than five tests that each build a board.

## Two tests that now count two children

A hint used to add one child to a cell.
It adds two.
Both tests that counted children say so:

```smalltalk
LaserGameCellElementTestCase >> testAMirrorCellShowsOneArrowAtATime
	"Old arrows must not clutter the board. The cell has one hint child, and moving to another
	push region replaces it. A hint brings two children: the arrow and the cross hair under
	the pointer."

	| element rect childCount |
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	rect := CellClickRegionInside regionRectangle.
	{ (rect leftCenter + (1 @ 0) -> LaserGameShapes eastArrowPoints).
	(rect topCenter + (0 @ 1) -> LaserGameShapes southArrowPoints).
	(rect rightCenter - (1 @ 0) -> LaserGameShapes westArrowPoints) } do: [ :each |
		element dispatchEvent: (BlMouseMoveEvent new
				 position: each key;
				 yourself).
		self assert: element children size equals: childCount + 2.
		self
			assert: element hintElement geometry vertices
			equals: (LaserGameShapes
					 pointsOf: each value
					 scaledToExtent: CellRenderer hintArrowExtent) ]
```

```smalltalk
LaserGameCellElementTestCase >> testTheArrowStaysWhenTheCellUnderThePointerStillOffersIt
	"The other half of the same rule: a turn leaves the mirror where it is, so the hint under the
	pointer is still the right one and the arrow survives the redraw. The hint is read from the
	cell that stands there after the action, not kept and not dropped. The cross hair comes back
	with the arrow, which is the second of the two children counted here."

	| element childCount |
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
	self assert: (element children includes: element crossHairElement).
	self assert: element children size equals: childCount + 2
```

Both of them count from `childCount`, read before any event, rather than from a literal.
That habit is why adding a child to every hint cost us a two-character change in each test instead of a hunt for magic numbers.

> **Measure the baseline in the test; assert the difference.**

## Checking it

Run the package: you get green.
Then open a board and move the pointer slowly across a mirror:

```smalltalk
| grid board space |
grid := GridExample demoGrid.
grid fireLaser.
board := LaserGameBoardElement on: grid.
space := BlSpace new.
space title: 'Cross hair'.
space extent: (LaserGameBoardElement extentForGrid: grid) + 40.
space root
	background: Color veryLightGray;
	addChild: board.
board position: 20 @ 20.
space show
```

A small cross follows the pointer inside the mirror, with the arrow of the region beside it, and the arrow jumps as the cross crosses a dividing line — which is the first time you can see those lines at all.
In the four-pixel margin at the edge of the cell both disappear, and over a blank or target cell nothing is drawn.

The hints are now readable, and they are readable because the cell is thirty pixels of which the pointer covered most.
In the next chapter we ask what happens if the cell is bigger.

# Making larger cells

A cell is fifty pixels square.
Nothing in the game says so twice.
In this chapter we put that claim to the test by changing the one number and running the suite at several cell sizes, which turns the region offsets and the target radii into arithmetic and turns up the places where a size had been written down by hand.

That is a claim, and this chapter is about the two things a claim like it is worth.
First, what it buys: changing one method changes the size of the whole game, and the arrows, the regions, the target ring, and the board all follow.

Second, how you find out whether it is true — because a size that was written down instead of derived does not announce itself.
It sits there looking correct until the day the cell changes size, and then it is wrong by exactly the amount nobody noticed.

The honest way for you to find those is to change the size and look.
The better way is to change the size in a test and assert.

## The one number

```smalltalk
CellRenderer class >> cellExtent
	"Answer the size, in pixels, of one cell. Every other size in the package is derived from
	this one, so a cell of another size needs no other change anywhere."

	^50@50
```

Every other size in the game is a class method beside it, which we write as a derivation:

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

Look at which of these are numbers and which are arithmetic, because the difference is a decision about what the thing *is*.

`ignoreRegionOffset` is four, flatly.
It is a margin that exists so that a click aimed at the neighbouring cell does not turn this one, and the width of a near miss does not depend on how big the cell is.
Four pixels is right in a thirty pixel cell and right in an eighty pixel one.

`insideRegionExtent` is the cell less twenty, so the ring around it keeps its width as the cell grows.
`outsideRegionExtent` we do not write at all — it is the cell less the margin on each side, which is the sentence "the rotate region is everything but the margin" turned into code.

The margin is the decision; the region is the consequence.

> **Write down the thing you decided, and derive everything that follows from it.** The question to ask of every constant is: if the cell doubled, would this number still be right?
> If yes it is a decision.
> If no it is a consequence, and it should be computed.

## A size that is deliberately not proportional

Not every size should follow the cell.
The target's ring is the example:

```smalltalk
TargetCellRenderer >> radius
	"Answer the radius of the ring drawn in a target cell. It is worked out from the cell size, so
	that the ring grows with the cell, and clamped at ten so that it stops growing once the cell
	is large enough."

	^(self class cellExtent x // 2 - 8) min: 10
```

```smalltalk
TargetCellRenderer >> innerRadius
	"Answer the radius of the filled center of the target, which stays inside the ring."

	^ self radius - self class centerInset
```

The clamp is the interesting half.
At a thirty pixel cell you get a radius of seven; at forty you get ten; at fifty, or eighty, you still get ten.

The target is not a disc that fills its cell, it is a small ring in the middle of one, and past a certain size growing it would make it a different thing.

So there are three kinds of size in this game, and you want the vocabulary for them: ones that are decisions (`ignoreRegionOffset`), ones that are consequences (`outsideRegionExtent`), and ones that grow up to a point and then stop (`radius`).
The third kind needs the comment most, because a clamp looks like a forgotten `TODO` to anyone who was not there.

## The experiment, as a test

Raising the cell size, opening the game and looking is a real experiment.
It is also one that nobody runs again.
We write it as a test instead, and it costs one helper:

```st
CellRendererTestCase >> withCellExtent: anExtent do: aBlock
	"Run aBlock with the cell size of the whole package set to anExtent, and put the old size
	back afterwards. Raising the cell size and asking the geometry whether it followed is the
	experiment this makes cheap."

	| previous |
	previous := CellRenderer class >> #cellExtent.
	[
	CellRenderer class
		compile: 'cellExtent' , String cr , String tab , '^ ' , anExtent printString
		classified: 'constants'.
	aBlock value ] ensure: [
		CellRenderer class compile: previous sourceCode classified: 'constants' ]
```
> **Note.** *A less brittle test design* moves this method onto a new abstract `LaserGameTestCase`, so that the click tests and the cell element tests can reach it too.
> The body is unchanged.

That method recompiles a method, inside a test, and that owes you a justification rather than a shrug.
The cell size is a class-side constant that the entire package reads through `CellRenderer`.

There is no instance to configure, no parameter threaded through forty methods, and no injected object to replace — which is the price of a global constant, and the price is paid here.
Recompiling it is the only way to ask "what would this geometry do at another size?"
without changing the design of the game to suit the test.

Two details make it safe for you to do.
`previous` holds the `CompiledMethod` itself, so the original source is restored exactly, comment and all.
And the restore is in an `ensure:` block, so it happens even when an assertion inside `aBlock` fails.

**Anything a test changes outside itself is restored in an `ensure:`, not at the end of the test body** — a failing assertion raises, and an end-of-test cleanup never runs.

Then the experiment itself, which asks the geometry the questions your eye would ask:

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

Five claims, at three cell sizes, and each claim is a sentence you would otherwise have to check by squinting at a window:

1. **The nested regions keep their promises.** Their extents are what the constants answer, and both
   stay centred in the cell. A region that drifted off centre as the cell grew would be invisible at
   fifty and obvious at eighty.
2. **The rotate line is at half the height.** With the line itself on the clockwise side, and the
   pixel below it on the other — three assertions that pin the boundary rather than its
   neighbourhood.
3. **Every point of the cell falls in a region**, checked by walking every pixel of the cell. At
   eighty that is 6400 points, and it costs milliseconds.
4. **The four push regions divide the inside square without overlapping**, checked by counting how
   many of them claim each point: exactly one, everywhere. Counting is how you test a partition —
   `count: ... equals: 1` says *covered* and *not twice* in one assertion.
5. **A target ring fits in its cell, and a board is the grid times the cell.** The first is the
clamp    staying sane at every size; the second is the one arithmetic that ties a cell to the whole
window.

Three sizes, not one: 30, 40, and 80.
One size proves nothing about following, because every wrong constant is right at some size — it is right at the size it was written for.
**A test of "this follows that" needs at least two values of "that", and a third one well away from both is cheap insurance.**

## What the experiment turned up

When we did this by hand first — opening a board at eighty pixels, then restoring fifty while the window was still on screen — we got one walkback per mouse move, fifty five of them, all the same:

```text
NotFound: [:cls | cls regionRectangle containsPoint: aPoint] not found in SortedCollection
CellClickRegion class>>clickRegionForPoint:
MirrorCellRenderer>>hintRegionAt:
LaserGameCellElement>>showPositionHintAt:
LaserGameCellElement>>mouseMove:
```

We had written the classification as a `detect:` with nothing to answer when no region matched:

```st
	^self sortedSubclasses
		detect: [ :cls | cls regionRectangle containsPoint: aPoint ]
```

That is safe exactly as long as some region contains every point it is asked about, and the reasoning that made it look safe was sound: the ignore region covers the whole cell, so every point *of a cell* finds a region.

The hole is in the part that was not stated — a point that is not in the cell at all.
A cell element laid out at eighty pixels hands over points up to `79@79`, and the regions, recomputed at fifty, stop at `49@49`.

Two things for you to take from the shape of this bug.

A `detect:` without `ifNone:` is an assertion written in the imperative.
It says "this always finds something", and when the claim is about the *arguments* rather than about the collection, it is a claim the method cannot check.

Ask what the method should answer in the case the claim excludes.
Here, there is a good answer, and the ignore region already means it: a point a click can do nothing with.

And a mouse handler is not a place to raise.
An error in a move handler fires again on the next pixel, and the walkback arrives dozens of times a second — which was how this made itself known.
Code on an event path should degrade to doing nothing.

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

and the test names all four ways out of a cell:

```smalltalk
CellClickRegionTestCase >> testAPointOutsideTheCellIsIgnored
	"A point that falls in no region is ignored rather than an error. An element larger than the
	cell the regions are computed from sends such a point on every mouse move, and what happens
	there must be nothing at all, not a walkback out of the event handler."

	| beyond |
	beyond := CellRenderer cellExtent.
	self
		assert: (CellClickRegion clickRegionForPoint: beyond)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: -1 @ -1)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: beyond x @ 0)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: 0 @ beyond y)
		equals: CellClickRegionIgnore
```

Past the corner, before the origin, past the right edge, past the bottom edge.
A point *at* `cellExtent` is outside the cell, because a cell of fifty pixels runs from `0@0` to `49@49` — the off-by-one you are better off writing a test about than reasoning about twice.

No other classification needs the same guard.
The four push regions answer the four combinations of two booleans, and the two rotate regions split on one, so those `detect:` calls always find exactly one subclass whatever point they are given.

Only the outermost one could fail, and only outside the cell.
If we fixed all six "for symmetry" we would add five dead `ifNone:` blocks that no test could ever reach.

## Checking it

The picture is still worth having.
Raise the size, look, and lower it again:

```smalltalk
CellRenderer class compile: 'cellExtent' , String cr , String tab , '^ 80@80' classified: 'constants'.
LaserGameElementExample openExample
```

```smalltalk
CellRenderer class compile: 'cellExtent' , String cr , String tab , '^ 50@50' classified: 'constants'
```

You get large cells, mirrors that reach into their corners, hint arrows that grow with them and stay centred, a target ring that stays the small ring the clamp asks for, and borders that are still one pixel.

Close the window before lowering the size again, for the reason the walkback above explains: a cell element is laid out once, at the size that was current when it was built, while the click regions are computed afresh on every mouse move.
Lower the size under an open board and you get a disagreement — the element is eighty wide, the regions are fifty, and most of the cell answers "ignore".

The board is now readable at any size.
The window around it is still a grey rectangle with a column of buttons, which is where we go next.

# Add a counter and window colours

Nothing in this chapter changes a rule of the game.
We put a colour ramp behind the window, move the control panel to the left of the board, and add a small LED display at the top of the panel counting the cells the beam crosses.

Eye candy, and it is worth a chapter for two reasons: the LED is a seven-rectangle element built and tested like any other, and the counter is the first thing in the game that has to be told when the board changes.

The first is that drawing a seven segment display is a good exercise for you in the lesson of the last chapter: every number in it is derived from one size.

The second is the last section, which is the real work.
A counter has to be told when the number it shows has changed, and the two moments when the beam can change are in two different objects — one of which has no business knowing that a counter exists at all.

## The window gets a ramp

A ramp is a list of stops: a fraction of the way along the fill, and the colour there.

```smalltalk
LaserGameColors class >> windowColorRamp
	"Answer the ramp the window is filled with: two stops, each a fraction of the way along the
	fill paired with the color there. Bloc calls them the stops of a gradient paint."

	^ {
		  (0.0 -> (Color r: 0.3 g: 0.8 b: 0.9)).
		  (1.0 -> (Color r: 0.2 g: 0.1 b: 0.7)) }
```

```smalltalk
LaserGameColors class >> windowColorRampDirection
	"Answer the direction the window ramp runs in, as a fraction of the window in each direction.
	The first stop sits at the top left corner and the last one that fraction of the way across
	and down."

	^ 0.3 @ 0.8
```

A pale blue at one end, a dark violet at the other, and a direction that runs across and down.
We keep the two methods separate because they are two decisions, and because the direction is the one of the pair somebody will want to change while looking at the window.

A `BlLinearGradientPaint` wants the stops and two points to run between:

```smalltalk
LaserGameElement class >> windowBackgroundPaint
	"Answer the paint behind the whole game: the window ramp, running in the direction
	`LaserGameColors windowColorRampDirection` gives. An element takes one paint, so the ramp is
	the whole of it; `LaserGameColors gameWindowColor` stays for whatever needs a single color."

	^ BlLinearGradientPaint new
		  stops: LaserGameColors windowColorRamp;
		  start: 0 @ 0;
		  end: LaserGameColors windowColorRampDirection;
		  yourself
```

An element has one background, and here it is the ramp.
There is no flat colour underneath it to show through, because nothing shows through a gradient that covers the element.

```st
LaserGameElement >> initialize
	"A game is a row of two: the control panel, and the board beside it. The margin around both is
	padding, and the ramp behind them shows through it."

	super initialize.
	self background: self class windowBackgroundPaint.
	self layout: BlLinearLayout horizontal.
	self padding: (BlInsets all: self class gameMargin)
```
> **Note.** *Add move counter and randomizer*, the next chapter, adds one line here, which starts the move count at zero.

For you to see the ramp at all, the panel in front of it has to get out of the way:

```smalltalk
LaserGameColors class >> controlPanelColor
	"Answer the color of the control panel beside the board: transparent, so that the ramp behind
	the whole window shows through it."

	^ Color transparent
```

`Color transparent` is not the same as no colour.
The panel still has a background; it is a background that draws nothing, which is how a child lets its parent show through.

We say it explicitly rather than leaving the slot unset — an element whose background nobody ever set and an element deliberately painted transparent look the same on the screen and read very differently in the code.

## The panel moves to the left

Which side the panel is on is the order we add its two children in:

```st
LaserGameElement >> rebuild
	"Replace what I hold with a control panel for me and a board showing my grid beside it, and
	take the size the two of them and my margins need. The board tells the panel when a move
	changed the grid, so the counters follow a click as well as the fire button."

	self removeChildren.
	board := LaserGameBoardElement on: self grid.
	controlPanel := self newControlPanel.
	self addChild: controlPanel.
	self addChild: board.
	board whenMoveMadeDo: [ self controlPanel updateCounters ].
	self extent: (self class extentForGrid: self grid)
```
> **Note.** *Add move counter and randomizer* counts the move before it sets the counters, so the block registered on the second to last line is one method call in the image today.

In a horizontal linear layout the first child is leftmost.
That is the whole of the change, and you should notice what did *not* have to change: no position, no offset, and no arithmetic involving the width of the panel.
The last line before the extent is the wire this chapter ends with.

## A display drawn from seven rectangles

Pharo has no LED widget, so we draw the display: seven rectangles per digit, and showing a number recolours them.
The class is a `BlElement` like the rest of the view, and it keeps four things: how many digits it shows, the number it is showing, whether it is highlighted, and the digit elements themselves.

```smalltalk
BlElement << #LaserGameLedElement
	slots: { #digitCount . #value . #highlighted . #digitElements };
	tag: 'Graphics';
	package: 'Laser-Game'
```

The accessors are written by hand below rather than generated, because setting the digit count or the value does work as well as storing it.

The segments carry the letters a seven segment display has always given them — `a` across the top, `b` and `c` down the right side, `d` across the bottom, `e` and `f` down the left, `g` across the middle:

```smalltalk
LaserGameLedElement class >> segmentNames
	"Answer the names of the seven segments, in the order they are held in a digit element."

	^ #( #a #b #c #d #e #f #g )
```

```smalltalk
LaserGameLedElement class >> segmentsForDigit: anInteger
	"Answer the names of the segments the digit anInteger lights."

	^ #( #( #a #b #c #d #e #f ) #( #b #c ) #( #a #b #g #e #d )
	     #( #a #b #g #c #d ) #( #f #g #b #c ) #( #a #f #g #c #d )
	     #( #a #f #g #e #c #d ) #( #a #b #c ) #( #a #b #c #d #e #f #g )
	     #( #a #b #c #d #f #g ) ) at: anInteger + 1
```

Ten entries, indexed by the digit itself.
`at: anInteger + 1` is the arithmetic that turns the digit zero into the first entry, and it is the only place in the game where we use a number as an index into a literal array.

The alternative — a ten-branch conditional, or a `Dictionary` built at class initialisation — would be more code saying the same thing.
A literal array *is* a lookup table, and reading the first entry as the shape of a zero is easy once you know the letters.

Where each segment sits is one method, and every number in it is derived:

```smalltalk
LaserGameLedElement class >> segmentBoundsOf: aSymbol
	"Answer the rectangle segment aSymbol occupies in a digit, in the digit's own coordinates. The
	three bars run across the top, the middle and the bottom, and the four arms fill the two gaps
	the bars leave, so every size follows the digit size and the segment thickness."

	| width height thickness arm |
	width := self digitExtent x.
	height := self digitExtent y.
	thickness := self segmentThickness.
	arm := height - (3 * thickness) // 2.
	aSymbol == #a ifTrue: [ ^ thickness @ 0 extent: width - (2 * thickness) @ thickness ].
	aSymbol == #b ifTrue: [ ^ width - thickness @ thickness extent: thickness @ arm ].
	aSymbol == #c ifTrue: [
		^ width - thickness @ (thickness + arm + thickness) extent: thickness @ arm ].
	aSymbol == #d ifTrue: [
		^ thickness @ (height - thickness) extent: width - (2 * thickness) @ thickness ].
	aSymbol == #e ifTrue: [ ^ 0 @ (thickness + arm + thickness) extent: thickness @ arm ].
	aSymbol == #f ifTrue: [ ^ 0 @ thickness extent: thickness @ arm ].
	aSymbol == #g ifTrue: [
		^ thickness @ (thickness + arm) extent: width - (2 * thickness) @ thickness ].
	^ self error: 'No segment is named ' , aSymbol printString
```

`arm` is the line that carries the design: the height, less the three bars, split between the two gaps.
Every other number is `thickness`, `width` or `arm`, and the three bars and four arms fall where they have to.

The last line is the else branch, and it raises.
That is right here, and it is the opposite of what we did with `clickRegionForPoint:` in the previous chapter, so the difference is worth stating.

A point outside a cell is a thing that happens — it arrives from the mouse, dozens of times a second, and there is a sensible answer for it.
A segment named `#h` cannot arrive from anywhere but a typo in this package.

**Answer the case that can happen; raise on the case that means the program is wrong.**

Three constants feed it:

```smalltalk
LaserGameLedElement class >> digitExtent
	"Answer the size, in pixels, of one digit: ten wide and sixteen high. Three bars of the
	segment thickness, at the top, the middle and the bottom, with an arm between each pair, need
	an even height to divide."

	^ 10 @ 16
```

```smalltalk
LaserGameLedElement class >> segmentThickness
	"Answer the thickness, in pixels, of one segment."

	^ 2
```

```smalltalk
LaserGameLedElement class >> digitGap
	"Answer the gap, in pixels, between two digits. It is drawn between the digits rather than
	inside them, so three digits come to thirty four pixels rather than thirty."

	^ 2
```

Sixteen rather than fifteen, and the comment says why: three bars of two pixels and two arms between them need an even height to divide.
Fifteen would leave an arm of four and a half pixels, and you would see the rounding as a display whose middle bar sits a pixel off centre.

**When a size has to divide, choose a size that divides** — and say in the comment that this is what the number is for, or somebody will round it back down to the nicer-looking fifteen.

We build a digit once, and after that only recolour it:

```smalltalk
LaserGameLedElement >> newDigitElement
	"Answer one digit: an element of the digit size holding one rectangle per segment, in the
	order the segment names are in. The rectangles stay; showing another number recolours them."

	| digit |
	digit := BlElement new.
	digit extent: self class digitExtent.
	digit background: BlTransparentBackground new.
	self class segmentNames do: [ :name |
		| area segment |
		area := self class segmentBoundsOf: name.
		segment := BlElement new.
		segment extent: area extent.
		segment position: area origin.
		digit addChild: segment ].
	^ digit
```

We add the children in the order of `segmentNames`, and that order is the whole of the bookkeeping: the third child of a digit is segment `c`, now and for ever.
Nothing holds a dictionary of name to element, and nothing searches for a segment by name.

How many digits a display has is a question it answers, and setting it is what builds them:

```smalltalk
LaserGameLedElement class >> digits: anInteger
	"Answer a display of anInteger digits, showing zero."

	| led |
	led := self new.
	led digitCount: anInteger.
	^ led
```

```smalltalk
LaserGameLedElement >> digitCount
	"Answer how many digits I show."

	^ digitCount
```

```smalltalk
LaserGameLedElement >> digitCount: anInteger
	"Show anInteger digits. Setting the count builds the digits."

	digitCount := anInteger.
	self rebuildDigits
```

`digits:` is the only way a display is made, so there is no display with no digits to go wrong later.

```st
LaserGameLedElement >> rebuildDigits
	"Replace my digits with digitCount fresh ones and take the size they need."

	self removeChildren.
	digitElements := (1 to: digitCount) collect: [ :each | self newDigitElement ].
	digitElements do: [ :each | self addChild: each ].
	self extent: (self class extentForDigits: digitCount).
	self updateDigits
```
> **Note.** *Counters the player can read*, the last chapter of this section, rewrites this method: the gap between the digits becomes a margin on each digit but the first.
> The block above is the method as this chapter leaves it.

A display is asked for by the number of digits it shows, and the number it shows is set afterwards:

```smalltalk
LaserGameLedElement >> value
	"Answer the number I show."

	^ value
```

```smalltalk
LaserGameLedElement >> value: anInteger
	"Show anInteger."

	value := anInteger.
	self updateDigits
```

Setting the value recolours the digits, and nothing else in the display has to be told.

```smalltalk
LaserGameLedElement >> updateDigits
	"Color every segment of every digit for the number I show. The number is right aligned, the
	digits in front of it stay blank, and a number too long for me keeps its last digits."

	| text |
	text := value printString.
	text size > digitCount ifTrue: [ text := text last: digitCount ].
	digitElements withIndexDo: [ :digit :index |
		| position segments |
		position := index - (digitCount - text size).
		segments := position > 0
			            ifTrue: [
			            self class segmentsForDigit: (text at: position) digitValue ]
			            ifFalse: [ #(  ) ].
		digit children withIndexDo: [ :segment :segmentIndex |
			segment background:
				((segments includes: (self class segmentNames at: segmentIndex))
					 ifTrue: [ self onColor ]
					 ifFalse: [ self offColor ]) ] ]
```

This one method is where the display decides what a number looks like, and it makes three decisions you can read off it.

The number is **right aligned**: `position := index - (digitCount - text size)` is the offset that pushes a short number to the right, and a `position` of zero or less means this digit comes before the number starts.
Those digits light nothing at all, rather than showing a zero — a counter reading `007` is a different number from one reading `7`.

A number **too long** keeps its last digits, the way an odometer does.
That is a choice, and the two alternatives are worse: going blank hides a number the player wanted, and raising turns a cosmetic problem into a broken game.

And we set every segment of every digit on every update, including the ones that do not change.
Seven rectangles times three digits is twenty one assignments of a colour, which is nothing.
The version that only touched what changed would need to know what was there before.

## A tab that shows which segments each digit lights

`segmentsForDigit:` is a table of ten rows and seven columns written as a literal array, and a literal array is the one shape a table cannot be read in.
Reading it is exactly what an inspector tab is for.

```smalltalk
LaserGameLedElement >> inspectionSegments: aBuilder
	"Show which of the seven segments each of the ten digits lights, and which digits I am
	showing now. A seven segment digit is a table in the first place; segmentsForDigit: is that
	table written as a literal array, and this tab is the same table read the way it was meant to
	be read."

	<inspectorPresentationOrder: 2 title: 'Segments'>
	| table |
	table := aBuilder newTable
		         items: (0 to: 9);
		         addColumn:
			         (SpStringTableColumn title: 'Digit' evaluated: [ :each |
					          each printString ]);
		         yourself.
	self class segmentNames do: [ :name |
			table addColumn:
				(SpStringTableColumn title: name asString evaluated: [ :each |
						 ((self class segmentsForDigit: each) includes: name)
							 ifTrue: [ 'on' ]
							 ifFalse: [ '' ] ]) ].
	table addColumn:
		(SpStringTableColumn title: 'Shown now' evaluated: [ :each |
				 (self inspectionShowsDigit: each)
					 ifTrue: [ 'yes' ]
					 ifFalse: [ '' ] ]).
	^ table
```

The tab asks the class for the table rather than restating it, so the two can never disagree: change a digit in `segmentsForDigit:` and the tab says so on the next click.
The last column is the one thing the class cannot answer, because it is about this display and not about the digits in general.

```smalltalk
LaserGameLedElement >> inspectionShowsDigit: anInteger
	"Answer whether anInteger is one of the digits I am showing. My value is read as it is
	printed, since that is what the digits hold."

	^ (self value ifNil: [ 0 ]) printString includes:
		  (Character digitValue: anInteger)
```

The value is read as it is printed, which is how the digits read it too.
A display that has never been given a number shows zero, and `ifNil: [ 0 ]` says so once rather than leaving the tab to fail on a display nobody has set yet.

The test asserts the shape of the table and the two things the table claims:

```smalltalk
LaserGameLedElementTestCase >> testTheSegmentsTabShowsWhichSegmentsEachDigitLights
	"The Segments tab is segmentsForDigit: read as a table: the ten digits down the side, the
	seven segments across the top, and a mark where a digit lights a segment. The last column
	says which of the ten I am showing at the moment, so the table belongs to this display and
	not only to the class."

	| led builder table titles shown |
	led := LaserGameLedElement digits: 3.
	led value: 108.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := led inspectionSegments: builder.
	self assert: table items asArray equals: (0 to: 9) asArray.
	titles := (table columns collect: [ :each | each title ]) asArray.
	self
		assert: titles
		equals: #( 'Digit' 'a' 'b' 'c' 'd' 'e' 'f' 'g' 'Shown now' ).
	self
		assert:
			((table columns allButFirst allButLast collect: [ :each |
				  each evaluation value: 8 ]) reject: [ :each | each isEmpty ]) size
		equals: 7.
	self assert: (table columns second evaluation value: 1) equals: ''.
	shown := table columns last.
	self assert: (shown evaluation value: 1) equals: 'yes'.
	self assert: (shown evaluation value: 0) equals: 'yes'.
	self assert: (shown evaluation value: 8) equals: 'yes'.
	self assert: (shown evaluation value: 2) equals: ''
```

Eight lights all seven segments, and one lights two, so a table that has lost a column or transposed its axes cannot pass both assertions.
`108` is the number to test the last column with, because it names three digits of three different kinds and leaves seven of the ten unshown.

Two displays are worth keeping to click on:

```smalltalk
LaserGameLedExample class >> ledShowingOneHundredAndEight
	"A three digit display showing 108, which lights one digit of each kind: a lean one, a round one and the full eight.
	LaserGameLedExample ledShowingOneHundredAndEight"

	<sampleInstance>
	| led |
	led := LaserGameLedElement digits: 3.
	led value: 108.
	^ led
```

```smalltalk
LaserGameLedExample class >> ledShowingEverySegmentLit
	"A three digit display showing 888, where every segment of every digit is on.
	The last column of the Segments tab then says yes to all seven.
	LaserGameLedExample ledShowingEverySegmentLit"

	<sampleInstance>
	| led |
	led := LaserGameLedElement digits: 3.
	led value: 888.
	^ led
```

The first is the one the test uses, and the second is the degenerate end of the same table: every digit showing, every segment on, the last column saying yes to all seven.
A display showing `888` is also the one to look at when a segment is drawn in the wrong place, since nothing is hidden behind an unlit rectangle.

The one thing an LED does that a printed number cannot is glow:

```smalltalk
LaserGameLedElement >> highlighted: aBoolean
	"Light my segments brightly, or dimly. The counter is highlighted while the laser fires."

	highlighted := aBoolean.
	self updateDigits
```

```st
LaserGameLedElement >> onColor
	"Answer the color of a lit segment: bright while I am highlighted, dim otherwise."

	^ highlighted
		  ifTrue: [ LaserGameColors counterDigitColor ]
		  ifFalse: [ LaserGameColors counterDigitColor darker ]
```
> **Note.** *Counters the player can read* rewrites this method and the next one, so that an unlit segment disappears into the slab behind it instead of being merely dark.

```smalltalk
LaserGameLedElement >> offColor
	"Answer the color of a segment that is not lit."

	^ LaserGameColors counterDigitOffColor
```

Note that `highlighted:` sets the flag and then calls `updateDigits`, rather than recolouring anything itself.
We read the colours in one place, so there is one answer to "what colour is a lit segment", and `highlighted:` only has to make sure the question is asked again.

```smalltalk
LaserGameColors class >> counterDigitColor
	"Answer the color a counter lights its segments in."

	^ Color r: 0.674 g: 0.674 b: 0.96
```

```st
LaserGameColors class >> counterDigitOffColor
	"Answer the color of a segment that is not lit: a much darker version of the color it lights
	in."

	^ self counterDigitColor muchDarker
```
> **Note.** *Counters the player can read* rewrites this one too, for the same reason.

## The frame around it

The display and its caption go in a rounded frame:

```smalltalk
LaserGameCounterElement >> initialize
	"A counter is a transparent rounded frame around a column: the display, then the caption under
	it, one inset apart."

	super initialize.
	self background: BlTransparentBackground new.
	self geometry: (BlRoundedRectangleGeometry cornerRadius: self class cornerRadius).
	self border: (BlBorder
			 paint: LaserGameColors counterBorderColor
			 width: self class borderWidth).
	self padding: (BlInsets all: self class inset).
	self layout: (BlLinearLayout vertical cellSpacing: self class inset).
	self constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ]
```

Five messages, and each one is a separate thing the frame is: a background, a geometry, a border, a padding, and a layout.
`BlRoundedRectangleGeometry` is what makes the corners round — the rounding is the shape of the element, not a property of its border, which is why a rounded element clips its children at the corners too.

`fitContent` on both constraints is the sentence "I am as big as what I hold".
The counter does not state a size anywhere, so when you change the caption or the number of digits you change the frame.

```st
LaserGameCounterElement >> digits: anInteger
	"Show anInteger digits."

	led ifNotNil: [ :each | self removeChild: each ].
	led := LaserGameLedElement digits: anInteger.
	self addChild: led
```

```st
LaserGameCounterElement >> labelText: aString
	"Caption me aString. The caption is added last, so it is drawn under the display."

	label ifNotNil: [ :each | self removeChild: each ].
	label := BlTextElement new text: (aString asRopedText
			         fontSize: self class labelFontSize;
			         foreground: LaserGameColors counterLabelColor;
			         yourself).
	self addChild: label
```
> **Note.** *Counters of one width*, near the end of Section 5, rewrites both of these: every counter of the panel is given one width, so the display and the caption are centred in it.
> The blocks above are the methods as this chapter leaves them.

Both start by removing what was there before, so that sending `digits:` twice leaves one display rather than two.
A setter that adds a child has to take the old one away, and `ifNotNil:` is how it copes with the first time.

```smalltalk
LaserGameCounterElement class >> labelled: aString digits: anInteger
	"Answer a counter of anInteger digits captioned aString."

	| counter |
	counter := self new.
	counter digits: anInteger.
	counter labelText: aString.
	^ counter
```

We write it out with a temporary rather than as a cascade on `self new`.
A cascade would send its messages to the class rather than to the new counter, and answer the class — the mistake is easy to make and reads as though it should work.

Two colours finish it:

```smalltalk
LaserGameColors class >> counterBorderColor
	"Answer the color of the frame around a counter. The frame is a flat two pixel border, and it
	takes the color of the label beside it."

	^ Color veryVeryLightGray
```

```smalltalk
LaserGameColors class >> counterLabelColor
	"Answer the color of the text under a counter."

	^ Color veryVeryLightGray
```

The same colour, under two names, because they are two decisions that happen to agree today.
One of them will change without the other, and when it does we have nothing to untangle.

## Hanging it on the panel

```smalltalk
LaserGameControlPanelElement class >> counterGap
	"Answer the gap, in pixels, between the counters and around the column they sit in."

	^ 4
```

```st
LaserGameControlPanelElement >> newLaserPathCounter
	"Answer the counter showing how long the laser beam is: three digits. Three digits hold every
	path a board of this size can produce."

	^ LaserGameCounterElement labelled: 'Laser Path' digits: 3
```
> **Note.** *Counters of one width* sends `newCounterLabelled:digits:` here instead, which states the width every counter of the panel is given.

```st
LaserGameControlPanelElement >> newCounterColumn
	"Answer the column of counters: one so far, at the top left corner of the panel, one gap away
	from both edges. The counters added later fall in under this one."

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
	^ column
```

```st
LaserGameControlPanelElement >> rebuild
	"Replace what I hold with fresh counters at my top and fresh buttons at my bottom, both acting
	on my game, and take the width of a panel and the height of the board beside me."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	laserPathCounter := self newLaserPathCounter.
	counterColumn := self newCounterColumn.
	buttonRow := self newButtonRow.
	self addChild: counterColumn.
	self addChild: buttonRow.
	self extent: LaserGameElement panelWidth
		@ (LaserGameBoardElement extentForGrid: self game grid) y.
	self updateCounters
```
> **Note.** *Add move counter and randomizer* hangs a second counter in the column and puts a third button in a row above the other two, so the image today builds more than these three methods list.
> The blocks above are the methods as this chapter leaves them.

There is one counter, and it already goes in a column of its own.
That is not over-engineering for its own sake: in the next chapter we add a second counter, and a column is where it will go.

If it were one counter pinned to the top left corner of the panel, we would have to undo that in the next chapter before we could add anything.

The panel is a frame layout, so a column asks for its place with two alignments and a margin: `alignLeft` and `alignTop` put it in the top left corner, and the margin holds it one gap in from both edges.
The buttons keep the bottom left corner they were given earlier, so the panel now has something at each end of it.

`rebuild` ends with `updateCounters`, and that single line is worth more than it looks.
It means there is no moment when a counter shows a number that nothing has written: building the panel sets them, so a game just opened shows what its board actually holds.

## Telling the counter what happened

The panel holds its counter, so we read it through an accessor:

```smalltalk
LaserGameControlPanelElement >> laserPathCounter
	"Answer the counter showing how long the laser beam is."

	^ laserPathCounter
```

```st
LaserGameControlPanelElement >> updateCounters
	"Show how long the beam is while the laser fires, and nothing while it does not."

	self game laserIsActive
		ifTrue: [
			self laserPathCounter
				highlighted: true;
				value: self game grid laserBeamPath size ]
		ifFalse: [
			self laserPathCounter
				highlighted: false;
				value: 0 ]
```
> **Note.** *Add move counter and randomizer* adds three lines to the end of this method, for the counter it hangs under this one.

The rule is: while the laser fires the counter is bright and holds the number of cells the beam crosses; while it does not, the counter is dim and holds zero.
One method, read top to bottom, says exactly that.

What is left is for us to send that message at the two moments the beam can change.
The fire button is easy, because the game already had a method for showing what the model says now:

```smalltalk
LaserGameElement >> refresh
	"Show what the model says now: redraw the cells, put the right label on the fire button and
	set the counters."

	self board rebuildCells.
	self controlPanel updateFireButtonLabel.
	self controlPanel updateCounters
```

A click on a mirror is the interesting one, and it is the one design decision of this chapter.

The click arrives at a cell element.
The cell element tells its board.
The board knows nothing about the panel, or about the game — which is exactly why you can open a board on its own with `LaserGameBoardExample openExample`.

Giving the board a reference to the game, so that it could reach the panel, so that it could update a counter, would end that.

So the board does not reach for the counter.
It says that a move was made, and whoever cares listens:

```smalltalk
LaserGameBoardElement >> moveMade
	"A move was made on one of my cells. Every cell is drawn again, and whoever asked to hear
	about moves is told. The counters belong to the panel and not to me, so I announce the move
	instead of reaching for them, and a board opened on its own still works."

	self redrawCells.
	moveAction ifNotNil: [ :anAction | anAction value ]
```

```smalltalk
LaserGameBoardElement >> whenMoveMadeDo: aBlock
	"Evaluate aBlock after every move made on one of my cells."

	moveAction := aBlock
```

```smalltalk
LaserGameCellElement >> clickAt: aPoint
	"Act on a click at aPoint, in my own coordinates. My board records that I was clicked, my
	renderer decides whether my cell acts and which region handles it, and the board is told that
	a move was made when something changed."

	self board ifNotNil: [ :board | board clickCellElement: self ].
	(self renderer mouseUpAt: aPoint) ifNil: [ ^ self ].
	self board ifNotNil: [ :board | board moveMade ]
```

We give this pattern a name of its own.
The board offers an *announcement* — one slot holding a block, one message to fill it, and a send guarded by `ifNotNil:`.

Whoever assembles the two objects connects them, which here is `LaserGameElement >> rebuild` with its `board whenMoveMadeDo: [ self controlPanel updateCounters ]`.
A board that nobody connected announces to nobody and plays exactly as before.

Compare it with the alternative in one line each.
A board that holds the game asks you "which game?"
in every test that builds a board.
A board that announces asks nothing, and the game it does not know about is free to listen.

Notice also the middle line of `clickAt:`.
`mouseUpAt:` answers nil when the click changed nothing, and the early return means no move is announced for a click on a blank cell.
The counter is not touched, the cells are not redrawn, and in the next chapter the move count does not go up.

**Let the thing that knows whether something happened be the thing that says so.**

## The tests

The display has the arithmetic, so it gets most of them.
A test reads a digit back by asking which of the seven rectangles are lit:

```smalltalk
LaserGameLedElementTestCase >> litSegmentsOf: aLed at: anIndex
	"Answer the names of the segments the digit at anIndex of aLed lights, sorted, so that a test
	can compare them against a list of names without caring about the order."

	| digit |
	digit := aLed digitElements at: anIndex.
	^ ((1 to: digit children size)
		   select: [ :each |
		   (digit children at: each) background paint color = aLed onColor ]
		   thenCollect: [ :each | LaserGameLedElement segmentNames at: each ])
		  asSortedCollection asArray
```

That helper is the chapter's main lesson about testing drawing code.
The display holds colours, which are hard to assert about; what you want to know is *which segments are lit*.
One helper converts the first into the second, and every test after it reads like a sentence about segments.

> **Write the helper that turns what the code holds into what the test means.**

`asSortedCollection asArray` is there so that we can compare against a list written in alphabetical order, whatever order the segments happen to be in.

```smalltalk
LaserGameLedElementTestCase >> testEachDigitLightsTheSegmentsOfItsNumber
	"Eight lights all seven segments, one lights the pair on the right, and zero lights every
	segment but the bar in the middle. Those are the shapes the segment names describe."

	| led |
	led := LaserGameLedElement digits: 1.
	led value: 8.
	self
		assert: (self litSegmentsOf: led at: 1)
		equals: #( #a #b #c #d #e #f #g ).
	led value: 1.
	self assert: (self litSegmentsOf: led at: 1) equals: #( #b #c ).
	led value: 0.
	self assert: (self litSegmentsOf: led at: 1) equals: #( #a #b #c #d #e #f )
```

Three digits out of ten, which we pick because each one says something different: eight lights everything, one lights the least, and zero is the one that differs from eight by a single segment.
Testing all ten would copy the lookup table into the test, which proves only that the table equals itself.

> **Pick the cases that would catch a wrong answer, not all the cases.**

```smalltalk
LaserGameLedElementTestCase >> testANumberIsShownRightAlignedWithoutLeadingZeros
	"A number shorter than the display sits at its right, and the digits in front of it light
	nothing at all. An LED that shows 007 for seven would read as another number."

	| led |
	led := LaserGameLedElement digits: 3.
	led value: 5.
	self assertEmpty: (self litSegmentsOf: led at: 1).
	self assertEmpty: (self litSegmentsOf: led at: 2).
	self assert: (self litSegmentsOf: led at: 3) equals: #( #a #c #d #f #g )
```

`assertEmpty:` on the first two digits is the assertion that matters.
"Nothing is lit" is easy to get wrong in a way that still looks plausible to you on the screen, since a dim segment and an unlit one are both dark.

We check the counter for the order of its two children:

```smalltalk
LaserGameCounterElementTestCase >> testCounterShowsADisplayWithItsCaptionUnderIt
	"A counter is the display and then the caption, in that order, so the caption is drawn under
	the display."

	| counter |
	counter := LaserGameCounterElement labelled: 'Laser Path' digits: 3.
	self assert: counter children size equals: 2.
	self assert: counter children first identicalTo: counter led.
	self assert: counter children second identicalTo: counter label.
	self assert: counter led class equals: LaserGameLedElement.
	self assert: counter led digitCount equals: 3.
	self assert: counter label text asString equals: 'Laser Path'.
	self assert: counter layout class equals: BlLinearLayout
```

And the panel for where the counter sits, and for the rule:

```st
LaserGameControlPanelElementTestCase >> testCounterColumnSitsAtTheTopLeftOneGapIn
	"The counters are aligned to the top left corner of the panel, one counter gap away from both
	edges. The buttons keep the bottom."

	| panel column |
	panel := self newPanel.
	column := panel counterColumn.
	self assert: (panel children includes: column).
	self assert: column children asArray equals: { panel laserPathCounter }.
	self
		assert: column constraints frame horizontal alignment
		equals: BlElementAlignment horizontal start.
	self
		assert: column constraints frame vertical alignment
		equals: BlElementAlignment top.
	self
		assert: column margin
		equals: (BlInsets all: LaserGameControlPanelElement counterGap)
```
> **Note.** *Add move counter and randomizer* replaces the fourth assertion, since the column holds two counters from there on.

```smalltalk
LaserGameControlPanelElementTestCase >> testCounterShowsTheBeamLengthOnlyWhileTheLaserFires
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
```

Read the shape of that test: a state, the assertions for it, a change, the assertions again, the change back, the assertions once more.
Three states and a round trip, which is more than a test of "fire sets the counter" and catches the version that lights up and never goes dim again.

One line in the middle earns its place.
`self assert: panel laserPathCounter value > 0` looks redundant beside the equality above it — but if the beam path were empty, the equality would hold with both sides zero and the test would pass while showing nothing.

**When a test compares two things the code computed, make sure the value is not the one a broken version would also produce.**

We check the game for the ramp and for both ways to the counter:

```smalltalk
LaserGameElementTestCase >> testWindowIsFilledWithTheColorRamp
	"The window is filled with a ramp of two colours rather than one flat colour, running the
	fraction of the way across and down that the ramp direction states."

	| paint |
	paint := game background paint.
	self assert: paint class equals: BlLinearGradientPaint.
	self assert: paint stops equals: LaserGameColors windowColorRamp.
	self assert: paint start equals: 0 @ 0.
	self assert: paint end equals: LaserGameColors windowColorRampDirection
```

```st
LaserGameElementTestCase >> testGameHoldsABoardAndAControlPanel
	"A game is a row of two children: the control panel first, the board beside it."

	| game |
	game := LaserGameElement on: GridExample demoGrid.
	self assert: game children size equals: 2.
	self assert: game children first equals: game controlPanel.
	self assert: game children second equals: game board.
	self assert: game board class equals: LaserGameBoardElement.
	self assert: game layout class equals: BlLinearLayout
```
> **Note.** *Showing where the laser comes from*, in Section 5, wraps the board in a column, so the board is no longer the second child of the game.

```smalltalk
LaserGameElementTestCase >> testFiringTheLaserSetsTheCounter
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
```

```smalltalk
LaserGameElementTestCase >> testAMoveOnTheBoardSetsTheCounter
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
```

That last test is the one that checks the announcement, and its last line is why it works.
Turning the mirror at the foot of the first column sends the beam off the board earlier, and the path drops from nine cells to four.

A test that only asserted that the counter equals the path would pass even if the block were never registered, because both would be read after the change.
Asserting that the number *changed* is what proves something told the panel.

## Checking it

Open the game:

```smalltalk
LaserGameElementExample openExample
```

You get the panel on the left, the ramp running from a pale blue at the top left corner to a dark violet below and to the right, and the counter at the top of the panel with `Laser Path` under it, reading zero.

Click Fire.
The digits brighten and read the length of the beam.
Click Stop and they go dim and read zero.
Fire once more and turn one of the mirrors: the beam takes another route and the counter follows it, without you touching the fire button.

# Add move counter and randomizer

Two features.
The first is a Moves counter, showing how many moves the player has made: the point of the game is to light the target in as few as possible, so the number is worth putting on the screen.

The second is a random game generator, so that the board is a new puzzle each time, which brings with it a third button, a new game, and a question put to the player before the window closes.

Both of them drag something else along.
A random board needs a New button, and the panel was laid out for two buttons in one row; three buttons means we have to decide how a panel arranges buttons at all.

And Quit, which used to sit alone, now has a neighbour that is easy to miss by a few pixels, so it ought to ask before it closes the window — which in Bloc is a more interesting problem than it sounds.

## Counting the moves

One instance variable, which we set where the game is built:

```st
LaserGameElement >> initialize
	"A game is a row of two: the control panel, and the board beside it. The margin around both is
	padding, and the ramp behind them shows through it. No move has been made yet."

	super initialize.
	self background: self class windowBackgroundPaint.
	self layout: BlLinearLayout horizontal.
	self padding: (BlInsets all: self class gameMargin).
	moves := 0
```
> **Note.** *Showing where the laser comes from*, in Section 5, takes the bottom margin out of the padding, leaving that band to the mark of the home of the laser.

```smalltalk
LaserGameElement >> moves
	"Answer how many moves the player has made. Every click on the board counts, and the player is
	meant to solve the puzzle in as few as possible."

	^ moves
```

```smalltalk
LaserGameElement >> incrementMoves
	"Count one more move."

	self moves: self moves + 1
```

Where the counting happens is the question worth asking, and the previous chapter answered it in advance.
The board already announces a move, and the game already registers a block for it; the block now does two things instead of one, so it becomes a method:

```st
LaserGameElement >> rebuild
	"Replace what I hold with a control panel for me and a board showing my grid beside it, and
	take the size the two of them and my margins need. The board tells me when a move changed the
	grid, so the counters follow a click as well as the fire button."

	self removeChildren.
	confirmation := nil.
	board := LaserGameBoardElement on: self grid.
	controlPanel := self newControlPanel.
	self addChild: controlPanel.
	self addChild: board.
	board whenMoveMadeDo: [ self moveMade ].
	self extent: (self class extentForGrid: self grid)
```
> **Note.** *Showing where the laser comes from* puts the board in a column with that mark, and gives the panel the bottom margin.

```smalltalk
LaserGameElement >> moveMade
	"A move was made on my board: count it, and set the counters. The board has already drawn its
	cells by the time it tells me, so nothing else is left to do."

	self incrementMoves.
	self controlPanel updateCounters
```

A one-line block that grows into a two-line block should become a method, and the reason is not tidiness.
You can read `[ self moveMade ]` without knowing what a move does, and a test can send `moveMade` without a board.

Now, what counts as a move?
The board is told only when a click changed something, so a click on a blank cell is not counted.

That is a decision, not an accident: the count is the number the player is asked to keep down, and a click that moved nothing did not cost the player anything.
A test below holds the game to that reading, and it is the kind of test worth writing precisely because the behaviour is a choice rather than a consequence.

## A second counter

The counter itself is the one from the last chapter, under another caption:

```st
LaserGameControlPanelElement >> newMovesCounter
	"Answer the counter showing how many moves the player has made: three digits."

	^ LaserGameCounterElement labelled: 'Moves' digits: 3
```
> **Note.** *Counters of one width*, near the end of Section 5, sends `newCounterLabelled:digits:` here instead, which states the width every counter of the panel is given.

And the column from the last chapter takes a second child:

```st
LaserGameControlPanelElement >> newCounterColumn
	"Answer the column of counters: the beam length, and the move count under it, at the top left
	corner of the panel, one gap away from both edges."

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
	^ column
```
> **Note.** *Adding more game stats*, in Section 5, stacks four counters in this column.

That is the whole of placing it: one more `addChild:`, and the gap between the two counters is the cell spacing the column already had.
No offset, no height of a counter, no arithmetic.
This is what the column was for, and it is worth noticing how cheap the second counter is compared to what the first one cost.

```st
LaserGameControlPanelElement >> updateCounters
	"Show how long the beam is while the laser fires, and nothing while it does not, and show how
	many moves have been made. The move count is never bright: only the beam says whether the
	laser is on."

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
		value: self game moves
```
> **Note.** *Adding more game stats* sets two more counters here.

`highlighted: false` on the move counter, every single time.
It never brightens, and saying so explicitly costs one line and removes a question: you do not have to work out whether the move counter *can* be bright.

## A third button

A New button makes three, and three buttons do not fit in a row that was built for two.
What we avoid here is working out where each button goes: the moment a panel computes positions from a row number and a column number, every later button is arithmetic.

A row of buttons is an element:

```smalltalk
LaserGameControlPanelElement >> newRowOfButtons: aCollection
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
```

and the rows are that helper, which we call twice:

```smalltalk
LaserGameControlPanelElement >> newButtonRow
	"Answer the bottom row of buttons: Quit first, then Fire."

	^ self newRowOfButtons: {
			  quitButton.
			  fireButton }
```

```st
LaserGameControlPanelElement >> newNewGameRow
	"Answer the row above it, holding the New button on the left."

	^ self newRowOfButtons: { newGameButton }
```
> **Note.** *Undo*, in Section 5, adds the Undo button to this row.

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
	column addChild: self newNewGameRow.
	column addChild: self newButtonRow.
	^ column
```
> **Note.** *Reset*, in Section 5, adds a third row here.

A row of rows, and a button never learns where it is.
The rows we add in later chapters — Undo beside New, Reset in a row of its own — fall in above these two without touching anything, because there is nothing to touch.

**When a layout is a structure rather than a calculation, adding to it is adding a child.**

The column takes no margin, and the comment explains why, because we found that out through a bug.
A linear layout spaces its cells from its own edges as well as from each other, so the cell spacing alone already holds the buttons one gap in on every side.

Add a margin of the same gap on top and the left edge gets both: two buttons and their gaps then fill more than the panel, and you get the last button of the bottom row touching the board.

The widths work out exactly, and we give that a test of its own:

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

Two buttons and three gaps equal the panel width exactly.
That is not a coincidence, it is where the panel width came from — and a test that says so turns a coincidence into a stated relationship.

The second assertion says the other half: a third button in the same row would not fit, which is *why* the buttons are in rows at all.

The panel reads its rows back out of the column, so the names we use elsewhere keep working:

```smalltalk
LaserGameControlPanelElement >> buttonRow
	"Answer the bottom row of buttons: Quit and Fire. It is the last row of the button column."

	^ self buttonColumn children last
```

```st
LaserGameControlPanelElement >> newGameRow
	"Answer the row holding the New button. It is the first row of the column."

	^ self buttonColumn children first
```
> **Note.** *Reset* makes this the middle row of three, so it is read as the second child rather than the first.

`children last` rather than `children first` for the bottom row, because a vertical layout draws its first child at the top.
Reading a row back by position instead of holding it in an instance variable is a small decision in favour of one source of truth: the column holds the rows, and nothing can get out of step with it.

```smalltalk
LaserGameControlPanelElement >> newNewGameButton
	"Answer the button that throws the board away and deals a new one."

	^ self newButton: 'New' action: [ self game newGame ]
```

```st
LaserGameControlPanelElement >> rebuild
	"Replace what I hold with fresh counters at my top and fresh buttons at my bottom, both acting
	on my game, and take the width of a panel and the height of the board beside me."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	newGameButton := self newNewGameButton.
	laserPathCounter := self newLaserPathCounter.
	movesCounter := self newMovesCounter.
	counterColumn := self newCounterColumn.
	buttonColumn := self newButtonColumn.
	self addChild: counterColumn.
	self addChild: buttonColumn.
	self extent: LaserGameElement panelWidth
		@ (LaserGameBoardElement extentForGrid: self game grid) y.
	self updateCounters
```
> **Note.** *Adding more game stats* builds two more counters here, stops holding the two columns in instance variables, and takes the height of what it holds when the board is shorter than the panel.

## Dealing a random board

The randomizer is model-side work, and it is all on `GridFactory`.
The entry point fixes where the target goes:

```smalltalk
GridFactory class >> randomizeGrid: aGrid
	"Deal mirrors and a target onto aGrid, with the target in the top right corner of whatever
	board it is."
	self randomizeGrid: aGrid targetAt: (aGrid numberOfColumns@1)
```

```smalltalk
GridFactory class >> randomizeGrid: aGrid targetAt: pt
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
```

`aGrid numberOfColumns @ 1` is the top right corner of any board, and the number of mirrors is one per two and a half cells, so a five by five board gets ten and a bigger one gets proportionally more.
Both are the lesson of *Making larger cells* on the model side: the board size is the one number, and what fills it follows.

Where the mirrors go is the only interesting part, and you will find it turns on a dictionary of flags:

```smalltalk
GridFactory class >> emptyRandomLocationsFor: aGrid
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
```

```smalltalk
GridFactory class >> unusedRandomLocationIn: list forGrid: aGrid
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
```

Read the dictionary first, because the whole method depends on what it is.
Every location of the board is a key, from the moment it is built, and the *value* says whether that location has been taken.
The target corner starts at `true`; everything else starts at `false`.

So `list at: pt` is the condition of the loop: draw a point, read its flag, and go round again while the flag says taken.
The line that would look more natural — `list includesKey: pt` — is true for every location on the board, and you would get a loop that never ends.

**A dictionary used as a set of flags is not a dictionary used as a set of keys, and the two read almost the same.** If a collection means "has it been taken", ask it for the value, never for the key.

The loop is a retry: draw again until you draw a free one.
That is fine at these densities — ten mirrors among twenty-five cells, thirty-two among eighty — and it is the simplest thing that cannot place two mirrors on one cell.

It would be a bad idea on a board that is nearly full, where the draws would mostly hit taken cells; if you ever deal a board that dense, shuffle a list of the free locations and take from the front instead.

The generator is one per class, made on demand:

```smalltalk
GridFactory class >> randomNumberGenerator
	"Answer the one generator the class deals from, seeded from the clock the first time it is
	asked for."
	RandomNumberGenerator isNil ifTrue: [
		RandomNumberGenerator := Random new.
		RandomNumberGenerator seed: Time totalSeconds].
	^RandomNumberGenerator
```

```smalltalk
GridFactory class >> reSeed
	"Seed the generator from the clock again, so the next board dealt differs from this one."
	self randomNumberGenerator seed: Time totalSeconds
```

```smalltalk
GridFactory class >> randomBoolean
	"Answer true or false, each as likely as the other."

	| int |
	int := self randomNumberGenerator nextInteger: 2.
	^int > 1
```

`randomNumberGenerator` is a lazily initialised class variable: the `isNil ifTrue:` builds it the first time and every later send answers the same one.

`reSeed` exists for one reason, and it is a reason worth the method: because the generator is seeded, we can seed it in a test and get the same board every run, and `reSeed` is what puts the randomness back afterwards.

**Make the random thing seedable and the tests stop being flaky.** The test case below seeds in `setUp` and calls `reSeed` in `tearDown`, and that is the whole of it.

`nextInteger:` answers one of 1 to the number asked for, which is exactly the range of a column or a row, so we need no `+ 1` anywhere in the drawing.

## Starting a new game

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

Five lines, and the order of the first and the fourth matters.
`randomizeGrid:` writes a target and its mirrors onto the grid and clears nothing, so the cells have to be emptied first — otherwise you get the old board with ten more mirrors on it.

The test below catches exactly that, by counting mirrors after a new game on a board that already had ten: the answer has to be ten, not twenty.

> **When a method writes onto something without clearing it, the caller owns the clearing, and the test that proves it is a count.**

The last line is `refresh`, which rebuilds the cell elements, relabels the fire button and sets the counters.
Nothing here has to erase anything.
Each cell is an element that draws its own cell, so a cell that was a mirror and is now blank draws itself blank.

If the board were one shared picture, this is where we would have to start painting over what we drew before — a cell could no longer assume it was blank underneath, because for the first time a cell can lose contents as well as gain them.

## Asking before quitting

Quit is small and sits next to Fire, so it should ask first.
In many toolkits that is one line for you: open a modal dialog, and read the answer as the value of the expression.

Bloc cannot do that, and the reason is worth understanding rather than working around.
The dialog would have to be drawn by the space, and the code that is waiting for the answer is running *inside* that space, in an event handler.
Stop and wait there and you get nothing drawn, including the question.

So we ask the question rather than wait for it.
It is an element that covers the game, and it hands its answer to a block:

```smalltalk
LaserGameConfirmElement >> initialize
	"A question is a shade over the game with a box in the middle of it. The shade is ignored by
	the layout of the game, so the game stays the row of two children it was."

	super initialize.
	self background: LaserGameColors confirmationShadeColor.
	self layout: BlFrameLayout new.
	self constraintsDo: [ :aConstraints | aConstraints ignoreByLayout ].
	yesButton := self newButton: 'Yes' answering: true.
	noButton := self newButton: 'No' answering: false.
	box := self newBox.
	self addChild: box
```

`ignoreByLayout` is the one Bloc detail that makes this work.
The game lays its children out in a horizontal row; the question is a child of the game, and without that constraint it would become a third cell of the row and push the board sideways.

Ignored by the layout, it sits where we put it — over the whole game — and the row stays a row of two.

```smalltalk
LaserGameConfirmElement >> newBox
	"Answer the box in the middle of the shade: the question, and the two answers under it."

	| element |
	element := BlElement new.
	element background: LaserGameColors confirmationBackgroundColor.
	element geometry:
		(BlRoundedRectangleGeometry cornerRadius: self class cornerRadius).
	element padding: (BlInsets all: self class inset).
	element layout: (BlLinearLayout vertical cellSpacing: self class inset).
	element constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignCenter.
		aConstraints frame vertical alignCenter ].
	messageElement := BlTextElement new.
	element addChild: messageElement.
	element addChild: self newAnswerRow.
	^ element
```

```smalltalk
LaserGameConfirmElement >> newAnswerRow
	"Answer the row holding the two answers, Yes first."

	| row |
	row := BlElement new.
	row background: BlTransparentBackground new.
	row layout: (BlLinearLayout horizontal cellSpacing: self class buttonGap).
	row constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ].
	row addChild: yesButton.
	row addChild: noButton.
	^ row
```

A frame layout with both alignments set to centre is how a box ends up in the middle of what covers the game, and `fitContent` on both constraints is how it ends up the size of the question it holds.

We build the box from the same three pieces as a counter — a background, a geometry, a padding — and that is not an accident worth hiding: a game that invents a new visual language for every element looks like several games.

```smalltalk
LaserGameConfirmElement >> newButton: aLabel answering: aBoolean
	"Answer a button labelled aLabel that answers aBoolean when it is clicked. The buttons of the
	control panel are this size, so the answers look like the rest of the game."

	| button |
	button := ToButton labelText: aLabel.
	button extent: LaserGameControlPanelElement buttonWidth
		@ LaserGameControlPanelElement buttonHeight.
	button clickAction: [ self answer: aBoolean ].
	^ button
```

```smalltalk
LaserGameConfirmElement >> answer: aBoolean
	"The player answered aBoolean. Whoever asked the question is told, and it is that object which
	takes me off the game: I do not know what my answer means."

	answerAction ifNotNil: [ :anAction | anAction value: aBoolean ]
```

```smalltalk
LaserGameConfirmElement >> whenAnsweredDo: aBlock
	"Evaluate aBlock with the answer when the player presses one of my buttons."

	answerAction := aBlock
```

Read the comment on `answer:` again, because it is the design.
The question does not know what its answer means, and it does not take itself off the game.
It collects a yes or a no and passes it on.

That is the same announcement pattern the board used for a move, and it buys the same thing: we can test this element on its own, and it can be used for the next question somebody wants to ask.

> **An element that reports instead of acting can be reused; an element that acts has one caller.**

```smalltalk
LaserGameColors class >> confirmationShadeColor
	"Answer the color laid over the whole game while it asks a question, so that the board behind
	it is visibly out of reach."

	^ Color black alpha: 0.6
```

```smalltalk
LaserGameColors class >> confirmationBackgroundColor
	"Answer the color of the box a question is asked in. The game asks inside itself rather than
	in a dialog of its own, so the box takes the flat window color that the window ramp leaves
	unused."

	^ self gameWindowColor
```

The shade is black at six tenths alpha, which is the whole of "the game is out of reach while this question stands": the board is still visible, still recognisable, and plainly behind something.

On the game side, `quit` asks and `close` does what `quit` used to do:

```smalltalk
LaserGameElement >> quit
	"Ask before closing. Quit sits next to Fire and is easy to hit by accident. A Bloc element
	cannot stop and wait for an answer, so the question is laid over the game and answers back."

	self ask: 'Are you sure you want to quit?' onConfirm: [ self close ]
```

```smalltalk
LaserGameElement >> ask: aString onConfirm: aBlock
	"Lay the question aString over me, and evaluate aBlock if the player answers yes. Either answer
	takes the question off first. One question is asked at a time, so a second click on Quit while
	the question stands does nothing."

	| question |
	self confirmation ifNotNil: [ ^ self ].
	question := LaserGameConfirmElement asking: aString.
	question extent: (self class extentForGrid: self grid).
	question whenAnsweredDo: [ :answer |
		self dismissQuestion.
		answer ifTrue: [ aBlock value ] ].
	confirmation := question.
	self addChild: question
```

```smalltalk
LaserGameElement >> dismissQuestion
	"Take the question off me. Answering does this, whichever answer it was."

	confirmation ifNil: [ ^ self ].
	self removeChild: confirmation.
	confirmation := nil
```

```smalltalk
LaserGameElement >> close
	"Close the game, by closing the space it is shown in."

	self space ifNotNil: [ :aSpace | aSpace close ]
```

`ask:onConfirm:` is the generic half, and `quit` is one use of it.
Three things in it are worth naming.

The early return at the top is the nearest thing to modality this gets: while a question stands, asking another does nothing.
Without it, two clicks on Quit would stack two shades over the game, and the second answer would leave you with the first question behind.

The block registered with `whenAnsweredDo:` dismisses the question *before* it acts on the answer, and it dismisses on either answer.
Put the dismissal inside `ifTrue:` and a No leaves you with the shade over a game nobody can reach.

And `onConfirm:` takes only the yes branch, because a No never has anything to do.
If a question ever needs both, the method we write then is `ask:onConfirm:onCancel:` — not a boolean argument to this one.

## The grid can count its mirrors

The tests of the dealer are all about how many mirrors it dealt and where they landed, and counting them is a question about the board rather than about the dealer:

```smalltalk
Grid >> numberOfMirrors
	"Answer how many mirror cells stand on my board, lit or not."

	^(self cells select: [:each | each class = MirrorCell]) size
```

`self cells` answers every cell of the board as a flat collection.
`select:` keeps the ones the block answers true for, and `size` counts what is left.
Reading those two lines aloud gives you the sentence in the comment, which is what you want from a method this small.

The demo board holds ten of them, which is the test:

```smalltalk
GridTestCase >> testNumberOfMirrorsCounter
	"The demo grid holds ten mirrors. They are counted over the whole board, lit or not."

	| count |
	count := grid numberOfMirrors.
	self assert: count equals: 10
```

The count also settles a debt from *Push cells with the mouse*.
The *Pushes* tab was written there and left untested, because the one assertion worth making about it is the number of rows, and the only honest right-hand side for that is a count the grid makes by its own route:

```smalltalk
GridTestCase >> testThePushesTabSaysWhichPushesTheRulesAllow
	"The Pushes tab asks the four push rules of every mirror on the board and answers in one
	table. A mirror with no yes is a mirror the player cannot move, which is what the arrows on
	the board are drawn from."

	| builder table north east |
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := grid inspectionPushes: builder.
	self assert: table items size equals: grid numberOfMirrors.
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals: #( 'Mirror' 'North' 'East' 'South' 'West' ).
	self assert: (table items includes: 1 @ 2).
	self deny: (table items includes: 5 @ 1).
	north := table columns second.
	east := table columns third.
	self
		assert: (north evaluation value: 1 @ 2)
		equals: ((grid canPushCellNorthFromLocation: 1 @ 2)
				 ifTrue: [ 'yes' ]
				 ifFalse: [ '' ]).
	self assert: (east evaluation value: 1 @ 2) equals: 'yes'
```

`grid numberOfMirrors` on the left of an assertion, rather than `10`, because the two count the same thing by different routes and a disagreement between them is worth being told about.
The target cell at `5@1` is denied a row, since nothing but a mirror can be pushed.

And the last two assertions check a column rather than the table: `north evaluation value: 1 @ 2` is what that column would print for that mirror, asked against the rule it prints, and then once against a literal because `1@2` really can be pushed east.

The player never sees this count; it goes on the screen in the next section, in *Adding more game stats*.
It is written now because the tests on this page need it, which is the ordinary reason a method exists before anybody has asked to see it.

## The tests

The randomizer deals from a known seed, so that a board is the same board every run:

```smalltalk
GridFactoryTestCase >> setUp
	"Deal from a known seed, so a randomized board is the same board every run."

	super setUp.
	GridFactory randomNumberGenerator seed: 42
```

```smalltalk
GridFactoryTestCase >> tearDown
	"Put the generator back on the clock, so a game deals a different board every time."

	GridFactory reSeed.
	super tearDown
```

Those two methods are the pattern for testing anything random.
Seed in `setUp`, restore in `tearDown`, and the tests in between can assert exact numbers.
`tearDown` runs even when a test fails, which is what keeps a failing test from leaving the game dealing the same board for the rest of the session.

```smalltalk
GridFactoryTestCase >> testARandomizedGridPutsTheTargetInTheTopRightCorner
	"The target goes in the top right corner of the grid, which on a five by five board is 5@1,
	and it is the only target on the board."

	| grid |
	grid := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: grid.
	self assert: (grid at: 5 @ 1) class equals: TargetCell.
	self
		assert: ((self cellsOf: grid) count: [ :cell | cell isKindOf: TargetCell ])
		equals: 1
```

```smalltalk
GridFactoryTestCase >> testTheMirrorsStandOneToACellAndAwayFromTheTarget
	"The mirrors are dealt onto locations that have not been used yet, and the target is marked
	used before the first of them, so every mirror dealt is still on the board afterwards and none
	of them stands on the target. A five by five board takes ten mirrors."

	| grid |
	grid := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: grid.
	self assert: grid numberOfMirrors equals: 10
```

One assertion, and it is the whole of the retry loop.
We dealt ten mirrors; if two of them had landed on one cell there would be nine, and if one had landed on the target there would be ten with no target.

Counting is how you test that a loop placed things *somewhere else each time* — you never have to know where.

```smalltalk
GridFactoryTestCase >> testTheNumberOfMirrorsFollowsTheSizeOfTheBoard
	"One mirror per two and a half cells: ten on a five by five board and thirty-two on the
	standard one."

	| grid |
	grid := Grid newOfSize: 8 @ 10.
	GridFactory randomizeGrid: grid.
	self assert: grid numberOfMirrors equals: 32
```

```smalltalk
GridFactoryTestCase >> testTheSameSeedDealsTheSameBoard
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
```

That test asserts the property the other three depend on.
If seeding did not make the dealing repeatable, the exact counts above would be luck.
It is worth writing the test for the thing your other tests assume.

We check the move counter and the new game on the game:

```smalltalk
LaserGameElementTestCase >> testEveryMoveOnTheBoardCountsOne
	"The board announces the move and the game counts it, so the count is shown without anything
	searching for the display."

	(game board cellElementAt: 1 @ 5) clickAt:
		CellClickRegionRotateClockwise regionRectangle center.
	self assert: game moves equals: 1.
	self assert: game controlPanel movesCounter value equals: 1
```

```smalltalk
LaserGameElementTestCase >> testAClickThatChangesNothingIsNoMove
	"A click on a blank cell does nothing, so the board is never told and nothing is counted. The
	count is what the player is asked to keep down, so only a move that happened counts."

	self assert: (game grid at: 2 @ 2) class equals: BlankCell.
	(game board cellElementAt: 2 @ 2) clickAt:
		CellClickRegionRotateClockwise regionRectangle center.
	self assert: game moves equals: 0
```

The second line of that test is doing real work.
`self assert: (game grid at: 2 @ 2) class equals: BlankCell` asserts the *premise* — that the cell being clicked is blank.

Without it, a change to the demo board that put a mirror at `2@2` would turn this into a test that quietly checks nothing: the click would count a move, the assertion would fail, and the failure would be a puzzle to you.

**State the premise of a test as an assertion, so that a broken premise fails as a premise.**

```smalltalk
LaserGameElementTestCase >> testANewGameDealsAFreshBoardAndForgetsTheMoves
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
```

```smalltalk
LaserGameElementTestCase >> testANewGameIsShownOnTheBoard
	"Every cell element is built again from the cell that stands at its location now, so a cell
	that was a mirror and is now blank draws itself blank. Nothing has to be erased: a cell
	element draws only its own cell."

	game newGame.
	1 to: game grid numberOfRows do: [ :row |
		1 to: game grid numberOfColumns do: [ :column |
			self
				assert: (game board cellElementAt: column @ row) renderer cell
				equals: (game grid at: column @ row) ] ]
```

We test the question by answering it the way a button does.
A Toplo button needs a live space before a click turns into its action, so the tests send `answer:` directly:

```smalltalk
LaserGameConfirmElementTestCase >> testTheAnswerGoesToWhoeverAsked
	"A Bloc element cannot stop and wait for an answer inside an event handler, so the answer is
	handed to a block instead."

	| question answers |
	answers := OrderedCollection new.
	question := LaserGameConfirmElement asking: 'Really?'.
	question whenAnsweredDo: [ :each | answers add: each ].
	question answer: true.
	question answer: false.
	self assert: answers asArray equals: #( true false )
```

Collecting the answers in an `OrderedCollection` and asserting the whole array at the end is a habit you should copy.
It says in one assertion that both answers arrived, that each arrived once, and that they arrived in order.

```smalltalk
LaserGameElementTestCase >> testQuittingAsksBeforeItCloses
	"Quit sits beside Fire and is easy to hit by accident, so quitting asks first. The
	question covers the game and is not one of the two children the game lays out in a row. A
	second click on Quit while the question stands asks nothing more."

	game quit.
	self assert: game confirmation class equals: LaserGameConfirmElement.
	self assert: game children size equals: 3.
	self assert: game children last equals: game confirmation.
	game quit.
	self assert: game children size equals: 3
```

```st
LaserGameElementTestCase >> testAnsweringNoLeavesTheGameAsItWas
	"No takes the question away and does nothing else."

	| game |
	game := LaserGameElement on: GridExample demoGrid.
	game quit.
	game confirmation answer: false.
	self assert: game confirmation isNil.
	self assert: game children asArray equals: {
			game controlPanel.
			game board }
```
> **Note.** *Showing where the laser comes from*, in Section 5, reads the second child as the column the board sits in.

Those two together are the pair worth having for any element that covers another: one that it appears and is not laid out, one that it goes away and leaves nothing behind.
The second test asserts the *whole* list of children, not its size, which is how you catch a shade that was removed while the box stayed.

And the panel follows its two new children:

```st
LaserGameControlPanelElementTestCase >> testCounterColumnHoldsTheBeamCounterAboveTheMoveCounter
	"The move counter sits under the beam counter, one counter lower in the same column."

	| panel |
	panel := self newPanel.
	self assert: panel counterColumn children asArray equals: {
			panel laserPathCounter.
			panel movesCounter }
```
> **Note.** *Adding more game stats* replaces this test with `testCounterColumnHoldsTheFourCountersInOrder`, which asserts all four.

```st
LaserGameControlPanelElementTestCase >> testNewGameButtonHasTheRowAboveTheOthers
	"New sits in the row above the others: the column of rows holds the New row first and the Quit
	and Fire row last, which is lowest."

	| panel |
	panel := self newPanel.
	self assert: panel buttonColumn children asArray equals: {
			panel newGameRow.
			panel buttonRow }.
	self assert: panel newGameRow children asArray equals: { panel newGameButton }.
	self assert: panel newGameButton labelText asString equals: 'New'
```
> **Note.** *Undo* drops the assertion that this row holds New alone, since Undo joins it there.

```smalltalk
LaserGameControlPanelElementTestCase >> testMovesCounterShowsTheMoveCountAndIsNeverBright
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
```

The last two lines are one assertion each and they belong together: the move counter is dim *while* the beam counter is bright.
Asserting only the first would pass on a game where nothing is ever bright.

## Checking it

Open the game:

```smalltalk
LaserGameElementExample openExample
```

You get two counters at the top of the panel, `Laser Path` over `Moves`, both reading zero, and three buttons at the bottom: New on its own row above Quit and Fire.

Turn a mirror.
You get one on the move counter, and it climbs with every turn and every push.
Click a blank cell and it stands still.
Fire the laser and the beam counter brightens beside it.

Click New.
You get the board dealt again: ten mirrors in new places, the target back in its corner, the laser off, the move counter back to zero.
Deal a few times and look for a board with no mirror in the first column — the randomizer can deal one, and it is a puzzle with nothing to solve.

Click Quit.
The game darkens and asks whether you are sure.
No takes the question away and leaves the game as it was; Yes closes the window.

# A bigger game board

Five columns by five rows was a choice, and it is time to find out whether the game knows that.
A tutorial game that only ever plays one board size tends to be full of fives nobody noticed: a loop that counts to five, a width worked out once on paper, a counter wide enough for the numbers the small board happens to produce.

In this chapter we deal boards of any extent, hand one to the game instead of letting the game make its own, and then go looking for whatever still believes in five.

So this chapter is mostly a search.
We ask the game for an eight by ten board and then look for everything that complains.

## The randomizer already takes a size

Nothing here is new, which is the point.
`randomizeGrid:targetAt:` of the last chapter asks the grid for its own dimensions — `aGrid numberOfColumns`, `aGrid numberOfRows` — and works out the number of mirrors from those.
It never mentions five.
So dealing a board of any size is one method that makes the grid and deals it:

```smalltalk
GridFactory class >> randomizedGridOfExtent: ext
	"Answer a board of ext columns by ext rows, dealt ready to play: the target in the top right
	corner of that board, and the mirrors of that size."
	| grid |
	grid := Grid newOfSize: ext.
	self randomizeGrid: grid targetAt: ((ext x)@1).
	^grid
```

This is what deriving everything from one number buys, and it is worth stopping on because it is the whole return on the care we took earlier.

We decided the size of the board in one place, told the grid, and computed every number that follows from the grid rather than writing it down.
A feature that would otherwise be a day of hunting for fives is a method that was already there.

Two tests, though, because until now nothing had ever asked for a board that was not five by five:

```smalltalk
GridFactoryTestCase >> testAGridOfAnyExtentIsDealtReadyToPlay
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
```

```smalltalk
GridFactoryTestCase >> testTheTargetCornerIsMarkedUsedOnABoardOfAnySize
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
```

The second test checks a line that was invisible on the small board.
`emptyRandomLocationsFor:` marks the target corner used before a single mirror is dealt, and on a five by five board that line could have been wrong in a way nothing would show you: the corner is `5@1`, the grid is square, and an off-by-one between columns and rows looks the same from either side.

On eight by ten it does not.
A non-square board is worth testing with precisely because it tells `numberOfColumns` and `numberOfRows` apart.

> **The test that finds a confusion between two numbers is the test where the two numbers differ.**

## Handing the game a board

The game has taken its grid from outside since the first graphics chapter, because a Bloc element has no choice: `initialize` runs when the element is made, before you can hand it anything.
So the grid arrives afterwards, through a setter that rebuilds:

```smalltalk
LaserGameElement >> grid: aGrid
	"Play on aGrid. Setting the grid rebuilds what I hold, so the same game element can show
	another grid."

	grid := aGrid.
	self rebuild
```

```smalltalk
LaserGameElement class >> on: aGrid
	"Answer a game element playing on aGrid."

	| element |
	element := self new.
	element grid: aGrid.
	^ element
```

Which means the new work in this chapter is one line, twice over:

```smalltalk
LaserGameElement class >> onRandomOfExtent: aPoint
	"Answer a game on a freshly dealt board of aPoint columns by aPoint rows. Dealing the board is
	all this does; #on: is what builds a game around a grid."

	^ self on: (GridFactory randomizedGridOfExtent: aPoint)
```

```smalltalk
LaserGameElement class >> openRandomOfExtent: aPoint
	"Open a game on a freshly dealt board of aPoint columns by aPoint rows and answer the space.

	LaserGameElement openRandomOfExtent: 8@10"

	^ self openOn: (GridFactory randomizedGridOfExtent: aPoint)
```

```smalltalk
GridFactory class >> defaultGrid
	"Answer the board a new game is dealt on: eight columns by ten rows, randomized."

	^self randomizedGridOfExtent: 8@10
```

Each of those is a name over an expression, and that is the right amount of code for them.

None of them decides anything: `onRandomOfExtent:` deals and hands over, `openRandomOfExtent:` deals and opens, `defaultGrid` names one particular size.
If any of them had grown a second line of real work, we would have had to ask which existing method should have had it.

The opener for the dealt board belongs with the examples, not with the game: it names a board and puts a window on the screen, which is what the examples package is for.

```smalltalk
LaserGameElementExample class >> openStandardExample
	"Open the standard board: eight columns by ten rows, dealt. The demo board of #openExample is
	the five by five one the earlier chapters play on.
	LaserGameElementExample openStandardExample"

	<sampleInstance>
	^ LaserGameElement openOn: GridFactory defaultGrid
```

Two openers, on purpose.
`openExample`, promoted back in *Assembling the game window*, still opens the five by five demo board.
A hand-made board you can check by eye is worth keeping next to one that is different every time: when something looks wrong on a dealt board, the first question is always whether it also looks wrong on the board you know.

## Three boards worth keeping

There are now three boards anybody reading this code might want in front of them, and only one of them has a name.
`GridExample demoGrid` is the five by five board of the earlier chapters, and the other two arrive with this one.

```smalltalk
GridExample class >> standardGrid
	"The board a new game is dealt on: eight columns by ten rows, thirty-two mirrors, the target in the corner.
	GridExample standardGrid"

	<sampleInstance>
	^ GridFactory defaultGrid
```

```smalltalk
GridExample class >> randomGrid
	"A board dealt afresh, so no two clicks show the same one.
	GridExample randomGrid"

	<sampleInstance>
	^ GridFactory randomizedGridOfExtent: 8 @ 10
```

Two examples over the same size of board, and they are not the same example.
`standardGrid` is the board a new game is dealt, and it comes through `defaultGrid` so that changing what a new game plays on changes the example too.
`randomGrid` says the size out loud, and its point is that it is different every time: click it twice and compare the two Cells tabs.

The third is the one the factory starts from:

```smalltalk
GridExample class >> emptyStandardGrid
	"The same eight by ten board before anything is dealt on it: eighty blank cells.
	Compare its Cells tab with the one of #standardGrid.
	GridExample emptyStandardGrid"

	<sampleInstance>
	^ GridFactory emptyStandardGrid
```

An eighty cell board with nothing on it looks like a mistake until you have the dealt board beside it, and then it is the before picture of the only method in this chapter that puts anything anywhere.

## A tab that draws the boards the factory deals

`GridFactory` has no instances worth inspecting and no state at all: everything it knows, it answers.
That is the case for a class-side tab, because the question "what does this factory deal?" is a question about the class.

```smalltalk
GridFactory class >> inspectionBoards: aBuilder
	"Show every board I deal, drawn side by side by the board element of the game. I answer boards
	and nothing else, so a picture of the boards is a picture of me."

	<inspectorPresentationOrder: 1 title: 'Boards'>
	^ aBuilder newMorph
		  morph: self inspectionBoardsElement asPreviewMorph;
		  yourself
```

```smalltalk
GridFactory class >> inspectionBoardsElement
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
```

The tab draws the boards with `LaserGameBoardElement`, which is the element the game draws with.
A tab that drew its own little squares would be a second drawing of the board, and a second drawing can be right while the game is wrong.

```smalltalk
GridFactory class >> inspectionBoardFacts
	"Answer each board I can deal, named by the selector that deals it: an empty board of the
	standard size, and the board a new game is dealt. The second is dealt afresh every time this
	is asked, since that is what a new game gets. The fixed board of the book is not here: it is
	an example, not a board I deal."

	^ OrderedCollection new
		  add: 'emptyStandardGrid' -> self emptyStandardGrid;
		  add: 'defaultGrid' -> self defaultGrid;
		  yourself
```

The facts are a list of selector to board, and the tab reads nothing else, so adding a board the factory deals is one line here rather than a new column in a layout.
The dealt board is dealt afresh on every click, because that is what a new game gets, and a tab that cached it would be showing one deal for ever.
The demo board is deliberately absent: it is a fixture the book and the tests play on, not a board the factory deals.

The test asserts that every board the facts name is drawn, and drawn with the right element:

```smalltalk
GridFactoryTestCase >> testTheBoardsTabDrawsEveryBoardIDeal
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
```

`children size equals: inspectionBoardFacts size` is the assertion that matters, since it is the one that fails when a board is added to the facts and the layout quietly drops it.

## A tab that counts the boards it deals

A dealt board is random, so the picture the Boards tab draws is a different picture every time the tab is opened, and a picture that never repeats cannot be checked by eye.
What a random board can be held to is its counts, and the grid counts mirrors already:

```smalltalk
GridFactory class >> inspectionNumberOf: aCellClass in: aGrid
	"Answer how many cells of aGrid are instances of aCellClass. The class is compared exactly,
	so a subclass of a cell is not counted as its superclass."

	| count |
	count := 0.
	1 to: aGrid numberOfColumns do: [ :x |
		1 to: aGrid numberOfRows do: [ :y |
			(aGrid at: x @ y) class = aCellClass ifTrue: [ count := count + 1 ] ] ].
	^ count
```

```smalltalk
GridFactory class >> inspectionCounts: aBuilder
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
```

```text
Board             | Columns | Rows | Cells | Mirrors | Targets | Blanks
emptyStandardGrid | 8       | 10   | 80    | 0       | 0       | 80
defaultGrid       | 8       | 10   | 80    | 32      | 1       | 47
```

`items:` is `self inspectionBoardFacts`, the same boards the Boards tab draws, so the picture and the counts cannot drift apart.
Three counts, and they add up to the cells on both rows.
That is the claim the test makes of both boards, and it is the one claim a dealt board can be held to: if only 79 of the 80 cells are accounted for, you have a hole in the board.

```smalltalk
GridFactoryTestCase >> testTheCountsTabSaysWhatIsOnEveryBoardIDeal
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
```

> **A random answer still has something exact to say about itself.** Count what has to balance, and the test holds even when the picture never repeats.

`inspectionNumberOf:in:` counts by class, exactly, with `class = aCellClass` rather than `isKindOf:`.
A mirror is not a blank cell that happens to lean, and a count that used `isKindOf:` would stop adding up the moment a cell class gained a subclass.

## Does anything still think the board is five by five?

We compute three sizes in this game, and all three have to come from the grid.

The board is the easy one, and we wrote it this way from the start:

```smalltalk
LaserGameBoardElement class >> extentForGrid: aGrid
	"Answer the extent a board showing aGrid occupies. Cells are laid out edge to edge and
	their borders are painted inside them, so the borders add nothing to this."

	^ CellRenderer cellExtent
	  * (aGrid numberOfColumns @ aGrid numberOfRows)
```

One multiplication of two points.
The cell size times the number of cells, in both directions at once, and `Point` does the arithmetic.
There is no loop, no accumulation, and nowhere for a five to hide.

The window is the board, the panel beside it, and a margin on each side:

```st
LaserGameElement class >> extentForGrid: aGrid
	"Answer the extent a game showing aGrid occupies: the board, the control panel beside it, and
	one margin on each side."

	^ (LaserGameBoardElement extentForGrid: aGrid) + (self panelWidth @ 0)
	  + (2 * self gameMargin)
```
> **Note.** *Adding more game stats*, the first chapter of Section 5, takes the height of the taller of the board and the panel instead, since four counters can stand taller than a board of few rows.

And the panel, from the last chapter, takes the width of a panel and the height of the board next to it.
So all three read the grid, and the test says so in one place:

```st
LaserGameElementTestCase >> testAGameTakesTheSizeOfWhateverBoardItIsGiven
	"A game is handed a grid rather than building one, so the size of the board is the size of the
	grid. The game is one cell per location, the panel keeps its width and takes the height of the
	board beside it, and the window is the two of them and the margins. The sizes are read from
	the layout constraints, since nothing is laid out until a space shows it."

	| game wanted |
	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	wanted := LaserGameElement extentForGrid: game grid.
	self assert: game board children size equals: 80.
	self
		assert: wanted
		equals: (8 * CellRenderer cellExtent x + LaserGameElement panelWidth
		         + (2 * LaserGameElement gameMargin))
			        @ (10 * CellRenderer cellExtent y
				         + (2 * LaserGameElement gameMargin)).
	self assert: game constraints horizontal resizer size equals: wanted x.
	self assert: game constraints vertical resizer size equals: wanted y.
	self
		assert: game controlPanel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: game controlPanel constraints vertical resizer size
		equals: 10 * CellRenderer cellExtent y
```
> **Note.** *Adding more game stats* rewrites this test for the taller panel, and that version is the one in the image.

Eight columns of fifty, plus a panel of a hundred and ten, plus two margins of ten, is five hundred and thirty wide; ten rows of fifty and the margins is five hundred and twenty high.

The last line of the comment is the detail that costs an afternoon if nobody writes it down.
We read the sizes from `constraints horizontal resizer size`, not from `extent`, because `extent` is `0.0@0.0` until a space lays the element out.

A test that asserts on `extent` without opening a window asserts on zero, and the first time you see that failure it looks like the size calculation is broken rather than the test.

> **When a test reads a value a framework computes later, read the instruction instead of the result.**

New deals the grid the game already plays on, so the size survives it:

```smalltalk
LaserGameElementTestCase >> testANewGameKeepsTheSizeOfTheBoard
	"New deals the grid the game already plays on, so a bigger board stays bigger: the cells are
	emptied and dealt again, one target in the corner and the mirrors of that size."

	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	game newGame.
	self assert: game grid numberOfColumns equals: 8.
	self assert: game grid numberOfRows equals: 10.
	self assert: game grid numberOfMirrors equals: 32.
	self assert: (game grid at: 8 @ 1) class equals: TargetCell.
	self assert: game board children size equals: 80
```

The search did turn up one number that is not derived from anything: the counters are three digits wide, which we chose while looking at a five by five board.
A bigger board makes a longer beam, so how much longer is a fair question:

```smalltalk
LaserGameElementTestCase >> testTheCountersStillHoldWhatABiggerBoardProduces
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
```

That test is an odd shape and worth defending.
It asserts an inequality — the path is shorter than a thousand — rather than a number, because the path length of a dealt board is not predictable.

What it pins down is that three digits are *enough* for the boards this game deals, which is the thing you want to know and the thing a later change could break.

A board large enough to overflow three digits would have to be hundreds of cells across.
If anybody ever wants one, `LaserGameCounterElement labelled:digits:` takes the digit count as an argument already, and the panel is its only caller.
That is the shape you want to leave a limit in: a parameter with one caller, rather than a constant with none.

## Checking it

```smalltalk
LaserGameElementExample openStandardExample
```

You get a window of 530 by 520, a board of eight columns by ten rows with thirty-two mirrors, the target in the top right corner, counters at the top of the panel, and three buttons at the bottom of it.
The panel is exactly as wide as it was on the small board; only its height follows the board.

Everything we built in the earlier chapters still works on it.
A click turns or pushes a mirror and counts a move, Fire lights the beam and brightens its counter, New deals another eight by ten board, Quit asks first.

Or ask for a size of your own:

```smalltalk
LaserGameElement openRandomOfExtent: 12@12
```

Try a thin one — `3@12`, say — and you get a panel taller than the board beside it, with the counters hanging off the top of a short board.
That is not a bug yet, because nothing is cut off; it becomes one in Section 5, when a fourth counter makes the panel taller than a short board can cover.

# Drawing the laser beam

The game is playable without the beam being drawn.
The counter says how many cells the beam runs through, the target lights up when the beam reaches it, and the player works out the rest.

That is enough to play, and it is a poor thing to look at, so in this chapter we build the shape of a beam — a pale band with a bright centre on it, horizontal and vertical — and test it before any cell asks for one.

We build the beam as a shape.
Nothing on the board draws it yet — we wire it into the cells in the next chapter — so the work here is one question: what *is* a laser beam, as geometry?

## A beam is two rectangles

Look at a beam, in a film or a photograph.
There is a wide, pale glow, and along the middle of it a narrow, bright core.
That is the whole picture.
Two bands, one on the other, both centred, in two colours:

```smalltalk
LaserGameColors class >> laserBeamSplatterColor
	"Answer the color of the wide, pale part of the laser beam."

	^Color r: 1.0 g: 1.0 b: 0.71
```

```smalltalk
LaserGameColors class >> laserBeamCenterColor
	"Answer the color of the bright core that runs along the middle of the laser beam."

	^Color r: 0.909 g: 1.0 b: 0.27
```

The pale one is almost white with a little yellow in it; the core is a yellow-green that reads as brighter than white against it.
Neither is `Color yellow`, and that is worth a moment of your time.

Pure named colours look like a diagram; two colours a few steps apart look like light.
If a glow does not look like a glow, the usual reason is that the two parts are too far apart in colour, not that they are the wrong colours.

You will be tempted to reach for a drawing program: paint a beam, save the image, load it as a picture and stretch it over the cell.
It is a reasonable instinct and it costs more than it looks:

- A picture has one size, and this game scales — cells grow, and a stretched bitmap grows soft.
- A picture has fixed colours. The two bands could never be recoloured without painting it again.
- A hand-painted band is not symmetric, so two cells laid end to end show a seam where they meet.
- And the picture has to live somewhere, which means a file, or a large literal array in the source.

Two rectangles have none of those problems.
They scale because they are computed, they take a colour as an argument, and they are symmetric to begin with, so beams in neighbouring cells join without a seam.

> **Before you reach for a picture, ask whether the thing you are drawing is made of shapes.** Glows, bars, arrows, and cross hairs usually are.

## The tests

We write the claim first: a beam crossing a cell from side to side is a pale band the whole way across, with a thinner bright bar on it, both centred.

```st
LaserGameShapesTestCase >> testABeamIsAPaleBandWithABrightCentreOnIt
	"A beam is an element holding two bars: the pale one first, the bright one on top of it, both
	running the whole length of the cell and both centred across it."

	| extent element splatter centre |
	extent := 50 @ 50.
	element := LaserGameShapes horizontalLaserBeamElementOfExtent: extent.
	self assert: (self requestedExtentOf: element) equals: extent.
	self assert: element children size equals: 2.
	splatter := element children first.
	centre := element children second.
	self
		assert: splatter background paint color
		equals: LaserGameColors laserBeamSplatterColor.
	self
		assert: centre background paint color
		equals: LaserGameColors laserBeamCenterColor.
	self assert: (self requestedExtentOf: splatter) x equals: extent x.
	self assert: (self requestedExtentOf: centre) x equals: extent x.
	self
		assert: (self requestedExtentOf: centre) y
		< (self requestedExtentOf: splatter) y.
	element children do: [ :each |
		self
			assert: each constraints position + ((self requestedExtentOf: each) / 2)
			equals: extent / 2 ]
```
> **Note.** *Laser on mirror cell*, at the end of this section, replaces the three beam builders with one that takes the lit sides of the cell, so this test asks `laserBeamElementOfExtent:fromSides:` for `#( #west #east )`.

Three things in that test are habits you should pick up rather than details.

We assert the order of the children — `children first` is the pale band, `children second` is the core — because in Bloc the order of children is the order they are drawn in.

The core is on top because we add it second.
A test that fetched the two bars by colour would pass with them the wrong way round, and the beam would be a pale band with a bright bar hidden under it.

We assert the core to be *thinner* than the band, with `<`, not thinner by some number.
We check the exact thicknesses in their own test below.
Here the claim is the relationship, and a test that states a relationship keeps holding when the numbers are tuned.

And we assert both bars to be centred the same way: the middle of the bar is the middle of the cell.
`each constraints position + (extent / 2)` is the centre of the bar, and the loop says it of both children, so neither bar can drift.

`requestedExtentOf:` is the helper the other shape tests use:

```smalltalk
LaserGameShapesTestCase >> requestedExtentOf: anElement
	"Answer the extent anElement was built with, read from its resizers. An element measures
	itself only in a layout pass, so its extent is zero until it is laid out."

	^ anElement constraints horizontal resizer size
	  @ anElement constraints vertical resizer size
```

Same lesson as the window size in the last chapter, and it comes up constantly in Bloc tests: a shape built outside a space has never been laid out, so `extent` is zero.
Read what the element was *told*, not what it currently measures.

A beam running down a cell is the same beam with its sides exchanged:

```st
LaserGameShapesTestCase >> testAVerticalBeamIsTheHorizontalOneTurned
	"A beam runs across a cell or down it. The two bars are the same two bars with their sides
	exchanged, so the two beams meet at the same thickness where a path turns."

	| extent horizontal vertical |
	extent := 50 @ 50.
	horizontal := LaserGameShapes horizontalLaserBeamElementOfExtent: extent.
	vertical := LaserGameShapes verticalLaserBeamElementOfExtent: extent.
	self assert: (self requestedExtentOf: vertical) equals: extent.
	self assert: vertical children size equals: 2.
	vertical children asArray
		with: horizontal children asArray
		do: [ :down :across |
			self
				assert: (self requestedExtentOf: down)
				equals: (self requestedExtentOf: across) transposed.
			self
				assert: down background paint color
				equals: across background paint color.
			self
				assert: down constraints position + ((self requestedExtentOf: down) / 2)
				equals: extent / 2 ]
```
> **Note.** *Laser on mirror cell* replaces this test too, for the same reason.

`with:do:` walks the two collections in step, and `transposed` on a point exchanges its two coordinates.
So you read the test as *the vertical beam is the horizontal one turned*, bar by bar, in one sentence, instead of repeating the first test with the numbers swapped.

> **When one thing is defined as a transformation of another, test the transformation, not the result.** Had this test spelled out the vertical thicknesses, a change to the thickness fractions would break two tests, and the second failure would tell you nothing the first did not.

And the beam follows the size of the cell:

```st
LaserGameShapesTestCase >> testTheBeamGetsThickerWithTheCell
	"The two thicknesses are computed from the extent of the cell: twice the cell, twice the beam.
	A beam is never thinner than one pixel, however small the cell it is drawn in."

	| small large |
	small := LaserGameShapes horizontalLaserBeamElementOfExtent: 30 @ 30.
	large := LaserGameShapes horizontalLaserBeamElementOfExtent: 60 @ 60.
	self
		assert: (self requestedExtentOf: large children first) y
		equals: (self requestedExtentOf: small children first) y * 2.
	self
		assert: (self requestedExtentOf: large children second) y
		equals: (self requestedExtentOf: small children second) y * 2.
	self
		assert: (self requestedExtentOf: small children first) y
		equals: (LaserGameShapes laserBeamSplatterThicknessFor: 30 @ 30).
	self
		assert: (self requestedExtentOf: small children second) y
		equals: (LaserGameShapes laserBeamCenterThicknessFor: 30 @ 30).
	self
		assert: (LaserGameShapes laserBeamCenterThicknessFor: 2 @ 2)
		equals: 1
```
> **Note.** *Laser on mirror cell* replaces this test too.

Two cell sizes, as in *Making larger cells*: one claim about "this follows that" needs two values of "that".

And the last assertion is the clamp — a cell of two pixels still gets a core of one pixel rather than none — which is the same kind of assertion as the mirror radius in that chapter.
A clamp is a decision, so it gets its own line in a test.

## The shapes

The two thicknesses are fractions of the cell: a third for the pale band, a sixth for the core, never below one pixel.

```smalltalk
LaserGameShapes class >> laserBeamSplatterThicknessFor: anExtent
	"Answer how thick the pale part of the beam is in a cell of anExtent: a third of the cell, and
	never less than one pixel. The thickness follows the cell size, so the beam keeps its
	proportions at any size."

	^ ((anExtent x min: anExtent y) // 3) max: 1
```

```smalltalk
LaserGameShapes class >> laserBeamCenterThicknessFor: anExtent
	"Answer how thick the bright core of the beam is in a cell of anExtent: half the pale band it
	sits on, and never less than one pixel."

	^ ((anExtent x min: anExtent y) // 6) max: 1
```

`anExtent x min: anExtent y` is the smaller side of the cell, so a cell that is not square gets a beam that fits it either way round.
`// 3` is integer division, which truncates, and `max: 1` is the clamp.
One line each, and between them they give you the entire visual proportion of the beam.

Notice that we write the core thickness as a sixth of the cell rather than as half of the band.
Both would give the same number here; the sixth says what it is measured against.
**A derived number should name the thing it derives from, and here both derive from the cell.**

One bar, centred, in a colour the caller names:

```st
LaserGameShapes class >> laserBeamBarOfExtent: aBarExtent within: anExtent color: aColor
	"Answer one bar of a beam, of aBarExtent and painted in aColor, centred in a cell of anExtent."

	^ BlElement new
		  extent: aBarExtent;
		  position: (anExtent - aBarExtent) / 2;
		  background: aColor;
		  yourself
```
> **Note.** *Laser on target cell* needs a bar that starts at a corner of the cell instead of its middle, so this method hands the work to `laserBeamBarOfExtent:at:color:` and keeps only the centring.

`(anExtent - aBarExtent) / 2` is the whole of "centred", in both directions at once.
Point arithmetic again: subtract the bar from the cell and you have the leftover space, halve it and you have the offset.

Writing it per axis — an x from the width, a y from the height — is four terms where there are two, and the second one is the one that gets mistyped.

And the two beams, which are now assemblies rather than drawings:

```st
LaserGameShapes class >> horizontalLaserBeamElementOfExtent: anExtent
	"Answer an element of anExtent drawing the beam where it crosses a cell from side to side: a
	pale band the whole way across, and a brighter, thinner bar along its middle. Two rectangles
	join without a seam where one cell meets the next."

	| splatter centre |
	splatter := self
		            laserBeamBarOfExtent:
		            anExtent x @ (self laserBeamSplatterThicknessFor: anExtent)
		            within: anExtent
		            color: LaserGameColors laserBeamSplatterColor.
	centre := self
		          laserBeamBarOfExtent:
		          anExtent x @ (self laserBeamCenterThicknessFor: anExtent)
		          within: anExtent
		          color: LaserGameColors laserBeamCenterColor.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: splatter;
		  addChild: centre;
		  yourself
```
> **Note.** *Laser on mirror cell*, at the end of this section, replaces this method with `laserBeamElementOfExtent:fromSides:`, which draws a bar the whole way across when both sides of an axis are lit.

```st
LaserGameShapes class >> verticalLaserBeamElementOfExtent: anExtent
	"Answer an element of anExtent drawing the beam where it crosses a cell from top to bottom: the
	horizontal beam with its sides exchanged."

	| splatter centre |
	splatter := self
		            laserBeamBarOfExtent:
		            (self laserBeamSplatterThicknessFor: anExtent) @ anExtent y
		            within: anExtent
		            color: LaserGameColors laserBeamSplatterColor.
	centre := self
		          laserBeamBarOfExtent:
		          (self laserBeamCenterThicknessFor: anExtent) @ anExtent y
		          within: anExtent
		          color: LaserGameColors laserBeamCenterColor.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: splatter;
		  addChild: centre;
		  yourself
```
> **Note.** *Laser on mirror cell* replaces this method too: one builder draws both axes, so the turned copy goes.

Each beam is an element of the full cell size holding two bars, and the element itself is transparent: it occupies the cell, and the cell shows through everywhere the bars are not.
Child order is draw order, so the pale band goes on first and the core over it.

The two methods are near-duplicates, and that is visible from here: the only difference is which coordinate gets the thickness and which gets the length.

The right moment for us to merge them is when a third case arrives, and it does — a beam that enters a cell and turns needs half a bar, not a whole one, which is what *Laser on mirror cell* is about.

**Two methods that differ in one axis are worth leaving alone; three are worth merging.** Merging too early means we guess at the parameter the third case will need.

## Checking it

Nothing on the board draws a beam yet.
You can look at the shapes on their own:

```smalltalk
| strip cell |
cell := 60.
strip := BlElement new
	extent: (cell * 4) @ (cell * 2);
	background: (Color r: 0.1 g: 0.1 b: 0.1);
	yourself.
0 to: 3 do: [ :i |
	strip addChild: ((LaserGameShapes horizontalLaserBeamElementOfExtent: cell @ cell)
		position: (i * cell) @ 0;
		yourself) ].
0 to: 3 do: [ :i |
	strip addChild: ((LaserGameShapes verticalLaserBeamElementOfExtent: cell @ cell)
		position: (i * cell) @ cell;
		yourself) ].
strip openInSpace
```

Four beams laid end to end make one unbroken band across the top, and you see no seam where one cell ends and the next begins.
Under it, four vertical beams show the same two bars turned.

Change `cell` to 20 and run it again: you get a thinner beam but the proportions hold.
Change it to 4 and the clamp earns its line — the core is one pixel rather than nothing at all.

# Laser on blank cell

Nobody builds the shapes of the last chapter yet.
In this chapter we put the beam on the board, starting with the easiest cell: a blank one, which the beam goes straight through.

What the beam does at a mirror and at the target is the work of the two chapters after this one, so the renderer gains one question, every cell answers it, and the element paints the answer under what is already there.

We take the three kinds of cell one chapter at a time, and that is the point rather than a convenience.
Each kind has its own question to answer, and a cell that has not learned to draw the beam yet simply draws none — which looks wrong on the screen, and is a state the tests can pin down exactly.

## One question and one child

A blank cell is crossed either from side to side or from top to bottom.
Nothing else can happen in it: the beam enters, it does not turn, it leaves.
So there is one question, and the answer is one child:

```st
BlankCellRenderer >> renderBeamOn: anElement
	"A beam goes straight through a blank cell, so it is one line: down the cell when the south
	segment is lit, across it otherwise."

	anElement addChild: ((self cell isSegmentOnFor: #south)
			 ifTrue: [
				 LaserGameShapes verticalLaserBeamElementOfExtent:
					 self class cellExtent ]
			 ifFalse: [
				 LaserGameShapes horizontalLaserBeamElementOfExtent:
					 self class cellExtent ])
```
> **Note.** *Laser on mirror cell* draws every kind of cell from one `renderBeamOn:` on `CellRenderer`, so this method goes.

Asking about the south segment alone is enough, and you should see why rather than take it on trust.
A lit blank cell has exactly two lit sides, and they are opposite each other.

If one of them is south, the other is north, and the beam runs down the cell; if neither is south, the two must be west and east, and the beam runs across.
One question distinguishes two cases because the model has already ruled out everything else.

> **Before writing a condition, work out how many cases can actually reach it.** Here it is two, so the condition is one question.
> Later, when a mirror can be lit on two sides that are *not* opposite, that reasoning stops holding, and the method that replaces this one asks a different question entirely.

## Where the cell asks for it

Two questions come before the drawing: is the laser firing at all, and does light reach this cell?
We ask both once, on the superclass:

```st
CellRenderer >> renderLaserOn: anElement
	"Draw the beam where it crosses my cell, as children of anElement. Nothing is drawn while the
	laser is off or while no light reaches my cell, which is why both questions are asked here
	rather than in each kind of cell. What a lit cell draws is the business of my subclasses, so
	#renderBeamOn: is theirs."

	self grid laserIsActive ifFalse: [ ^ self ].
	self cell isOff ifTrue: [ ^ self ].
	self renderBeamOn: anElement
```
> **Note.** *Laser on mirror cell* moves the drawing itself onto `CellRenderer`, so the last sentence of this comment changes to say that one `renderBeamOn:` serves every kind of cell.

```st
CellRenderer >> renderBeamOn: anElement
	"Draw the beam my lit cell shows, as children of anElement. Empty here: a cell whose kind has
	not learned to draw the beam yet shows none, which is how this section adds the three kinds one
	at a time."
```
> **Note.** *Laser on mirror cell* makes this the method that draws the beam of every cell, so it is no longer empty.

This is the same shape as `hintRegionAt:` several chapters ago, and we name it because it keeps recurring: **put the questions that are the same for everybody on the superclass, and leave the subclasses one thing to answer.**

Both guards are early returns, and neither is a special case.
The laser being off is the normal state of the game, and most cells are dark even while it fires.

Had we written those two questions into `BlankCellRenderer >> renderBeamOn:`, the next two chapters would have copied them, and the third copy would eventually have disagreed with the other two.

The empty method on `CellRenderer` is doing real work too, although it contains nothing.
It is what lets a mirror and the target draw no beam without raising, and the comment says that this is a stage rather than an oversight.

**An empty hook with a comment saying why it is empty is a design; an empty hook with no comment is a loose end.**

Two places build a cell, and both gain a line.
A cell built for the first time:

```st
CellRenderer >> newElement
	"Answer a new element rendering my cell. The element is square, keeps me as its renderer,
	carries the cell background and border, and holds whatever my subclass draws as children:
	the contents of the cell first, then the beam over them."

	| element |
	element := LaserGameCellElement new.
	element renderer: self.
	element extent: self class cellExtent.
	element geometry: BlRectangleGeometry new.
	self renderBackgroundOn: element.
	self renderBorderOn: element.
	self renderContentsOn: element.
	self renderLaserOn: element.
	^ element
```
> **Note.** *Laser on target cell* swaps the last two lines: the beam is drawn first and the contents over it.

and a cell drawn again after something changed:

```st
LaserGameCellElement >> redraw
	"Draw my cell again after the model changed. The cell standing at my location may be another
	one than before, since a push swaps two cells, so the renderer is chosen again — and so is
	the hint, at the point the pointer was last seen at, because an arrow kept across a redraw
	is the arrow of the cell that has moved away. A blank cell offers no push, so the arrow of
	the mirror that left goes with it, and the cross hair with the arrow. The beam is drawn here
	too, since firing the laser changes no cell but lights many of them."

	| grid location point |
	grid := self renderer grid.
	location := self gridLocation.
	point := hintPosition.
	self removeChildren.
	hintElement := nil.
	hintRegion := nil.
	crossHairElement := nil.
	self renderer: (CellRenderer rendererFor: (grid at: location) grid: grid).
	self renderer renderBackgroundOn: self.
	self renderer renderBorderOn: self.
	self renderer renderContentsOn: self.
	point ifNotNil: [ self showPositionHintAt: point ]
```
> **Note.** *Laser on target cell* swaps the two render lines at the end, so that the beam is drawn first and the contents over it.

Read the sentence about firing the laser, because it is the reason the beam has to be drawn in `redraw` and not only in `newElement`.
Firing the laser changes *no cell*: the cells were always there, and lighting them sets a flag on each.

So nothing is added or removed, and the only way the screen can follow is for every cell of the board to draw itself again.
`toggleLaser` already refreshed the game and `moveMade` already redrew every cell, so we need no new wiring here — both paths go through `redraw`, and `redraw` now draws the beam.

We add the beam after the contents and before the hint, so a hint arrow and its cross hair stay on top of it.
On a blank cell the two orders look the same, since a blank cell draws no contents; *Laser on target cell* finds a reason to prefer the other order and swaps them there.

## The tests

The demo grid runs the beam east along the bottom row and then north up the fourth column, so it has a blank cell of each kind.
One crossed from side to side:

```smalltalk
CellRendererTestCase >> testTheBeamCrossesABlankCellFromSideToSide
	"The beam goes straight through a blank cell, so it is one line. The demo grid sends the beam
	along the bottom row from west to east, and the blank cell at 2@5 is one the beam crosses that
	way."

	| element beam |
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid)
		           newElement.
	self assert: element children size equals: 1.
	beam := element children first.
	self
		assert: (self requestedExtentOf: beam)
		equals: CellRenderer cellExtent.
	self
		assert: (self requestedExtentOf: beam children first)
		equals: CellRenderer cellExtent x
			@ (LaserGameShapes laserBeamSplatterThicknessFor: CellRenderer cellExtent).
	self
		assert: beam children second background paint color
		equals: LaserGameColors laserBeamCenterColor
```

and one crossed from top to bottom, which is the same question answered the other way:

```smalltalk
CellRendererTestCase >> testTheBeamCrossesABlankCellFromTopToBottom
	"One question chooses between the two drawings: is the south segment lit. The demo grid turns
	the beam north at 4@5, so the blank cell at 4@4 is crossed from top to bottom."

	| element beam |
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 4) grid: grid)
		           newElement.
	self assert: element children size equals: 1.
	beam := element children first.
	self
		assert: (self requestedExtentOf: beam)
		equals: CellRenderer cellExtent.
	self
		assert: (self requestedExtentOf: beam children first)
		equals: (LaserGameShapes laserBeamSplatterThicknessFor: CellRenderer cellExtent)
			@ CellRenderer cellExtent y.
	self
		assert: beam children second background paint color
		equals: LaserGameColors laserBeamCenterColor
```

Both tests name the cell they use and say in the comment why that cell is the case being tested.
On a hand-made board that is the difference between a test you can maintain and a test full of coordinates nobody dares touch.

`2@5` means nothing on its own; you can find "the blank cell the beam crosses from west to east" again on any board.

Both also assert `element children size equals: 1` before looking at the child.
That assertion is what makes it safe for you to read `children first`, and it is the one that fails usefully: if a later change adds a second child to a lit blank cell, the failure says *one child expected, two found*, rather than a puzzling assertion about an extent somewhere further down.

And the two cases that draw nothing at all:

```smalltalk
CellRendererTestCase >> testABlankCellDrawsNoBeamUnlessTheLaserReachesIt
	"A cell draws a beam only while the laser is firing and only where the beam runs. Both
	questions are asked in #renderLaserOn:, before anything is drawn."

	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid) newElement
				children.
	grid fireLaser.
	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid) newElement
				children.
	grid stopLaser.
	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid) newElement
				children
```

One test, three states: the laser never fired, the laser firing at a cell it does not reach, and the laser stopped again at a cell it did reach.
The third one is the interesting one, and it is the test that catches the bug you get when lighting a cell sets a flag that stopping the laser forgets to clear.

> **When a thing can be turned on, test it off, on, and off again.** The second "off" goes through different code from the first.

## One line in the Picture tab

The *Picture* tab of `Cell`, written back in *A tab that draws one cell*, draws a cell through the renderer the game draws with.
The renderer now asks the grid whether the laser is on, and the grid that tab builds has it off, so the tab draws every cell dark.
The line it was promised is one line:

```smalltalk
Cell >> inspectionPicture: aBuilder
	"Show me as the board draws me, through the renderer the game itself uses, so that a model
	fault and a drawing fault can be told apart without opening the game. The renderer reads a
	copy of me standing in a grid of its own, because a view must not change what it shows."

	<inspectorPresentationOrder: 2 title: 'Picture'>
	| location grid renderer |
	location := self gridLocation ifNil: [ 1 @ 1 ].
	grid := Grid newOfSize: location.
	grid at: location put: self copy.
	grid laserIsActive: true.
	renderer := CellRenderer rendererFor: (grid at: location) grid: grid.
	^ aBuilder newMorph
		  morph: renderer newElement asPreviewMorph;
		  yourself
```

`grid laserIsActive: true` is the whole change, and it is the right change rather than a convenience.
A tab that showed the unlit cell would be showing a state the player never sees: the laser is on for as long as the game is being played.
The cell it draws is still a `copy` standing in a grid of its own, so lighting that grid lights nothing that belongs to the board.

That last sentence is the one worth a test, because it is the sentence a future change can break without the picture looking any different:

```smalltalk
MirrorCellTestCase >> testThePictureTabShowsMeAsTheBoardDrawsMe
	"The Picture tab draws me with my own renderer, mirror and all, and leaves my lean and my
	exit sides as they were."

	| cell builder |
	cell := MirrorCell leanRight.
	cell gridLocation: 4 @ 1.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	self
		assert: (cell inspectionPicture: builder) class
		equals: SpMorphPresenter.
	self assert: cell gridLocation equals: 4 @ 1.
	self assert: cell isRight.
	self assert: (cell exitSideFor: #north) equals: #west
```

The test asserts the tab answers a presenter, and then asserts the cell is exactly as it was: same location, same lean, same exit side.
A view that reads its subject has to be asked whether it also wrote to it, and the only way to ask is to look at the subject afterwards.

## Checking it

The board example already fires the laser: `LaserGameBoardExample openExampleWithLaserFired`, promoted in *Drawing the target*, opens the demo board with the beam drawn.
It shows the lit target now without a line of it being changed.

```smalltalk
LaserGameBoardExample openExampleWithLaserFired
```

The beam comes in at the bottom left corner, runs east across two blank cells, and goes up the fourth column through three more.
There are gaps where it turns and where it ends: the mirrors draw no beam yet, and neither does the target.

Those gaps are what we fill in the next two chapters, and they are worth looking at first — a beam that stops at every mirror makes it very clear how much of the picture the mirrors own.

# Laser on target cell

The target is the cell the beam ends in.
It swallows the light, so the beam covers only half the cell, and the target has to stay visible through it.

Two differences from the blank cell of the last chapter, and both of them are about the half of the picture that is *not* drawn: in this chapter we build a bar that fills half a cell, ask the cell which side the light arrives from, and put the beam under the target rather than over it.

## Half a beam

A beam that stops in the middle of a cell is a bar half as long, placed against the side the light arrives from.
The shapes gain a pair of methods that take that side:

```st
LaserGameShapes class >> horizontalLaserBeamElementOfExtent: anExtent enteringFrom: aSymbol
	"Answer an element of anExtent drawing the beam where it enters a cell from the side aSymbol
	names, west or east, and stops in the middle of it, which is what a cell that swallows the
	light shows. The bars are as thick as the ones of a whole beam, since the cell they cross is
	the same size."

	| length left splatter centre |
	length := anExtent x // 2.
	left := aSymbol = #west
		        ifTrue: [ 0 ]
		        ifFalse: [ anExtent x - length ].
	splatter := self laserBeamSplatterThicknessFor: anExtent.
	centre := self laserBeamCenterThicknessFor: anExtent.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: (self
			   laserBeamBarOfExtent: length @ splatter
			   at: left @ ((anExtent y - splatter) / 2)
			   color: LaserGameColors laserBeamSplatterColor);
		  addChild: (self
			   laserBeamBarOfExtent: length @ centre
			   at: left @ ((anExtent y - centre) / 2)
			   color: LaserGameColors laserBeamCenterColor);
		  yourself
```
> **Note.** *Laser on mirror cell* replaces this method with `laserBeamElementOfExtent:fromSides:`, where a single lit side gives the same half beam.

```st
LaserGameShapes class >> verticalLaserBeamElementOfExtent: anExtent enteringFrom: aSymbol
	"Answer an element of anExtent drawing the beam where it enters a cell from the side aSymbol
	names, north or south, and stops in the middle of it. The same picture turned a quarter, with
	one question to choose which half it keeps."

	| length top splatter centre |
	length := anExtent y // 2.
	top := aSymbol = #north
		       ifTrue: [ 0 ]
		       ifFalse: [ anExtent y - length ].
	splatter := self laserBeamSplatterThicknessFor: anExtent.
	centre := self laserBeamCenterThicknessFor: anExtent.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: (self
			   laserBeamBarOfExtent: splatter @ length
			   at: (anExtent x - splatter) / 2 @ top
			   color: LaserGameColors laserBeamSplatterColor);
		  addChild: (self
			   laserBeamBarOfExtent: centre @ length
			   at: (anExtent x - centre) / 2 @ top
			   color: LaserGameColors laserBeamCenterColor);
		  yourself
```
> **Note.** *Laser on mirror cell* replaces this method for the same reason as the one above it.

The one line you should read closely is the placement:

```st
	left := aSymbol = #west ifTrue: [ 0 ] ifFalse: [ anExtent x - length ]
```

A half-length bar in a cell can be at one of two places: hard against the left edge, or hard against the right one.
`0` and `anExtent x - length` are those two places.

We write the second as a subtraction from the cell rather than as `anExtent x // 2`, and that matters when the cell size is odd: with a cell of 51, `length` is 25, and a bar at 25 would leave a pixel of light showing past the middle, while `51 - 25` puts the bar flush with the right edge where the player can see whether it is right.

> **Place a thing by the edge it has to touch, not by the arithmetic that happens to land there.**

And the thicknesses are the same ones a whole beam uses.
We compute them from the cell, not from the length of the bar, so half a beam meeting a whole beam in the next cell meets it without a step.
That is a property worth protecting, and it gets its own test below.

Placing a bar at a corner of the cell rather than in its middle is the one thing the bar builder of *Drawing the laser beam* could not do, so a method goes under it:

```smalltalk
LaserGameShapes class >> laserBeamBarOfExtent: aBarExtent at: aPoint color: aColor
	"Answer one bar of a beam, of aBarExtent and painted in aColor, at aPoint of the cell."

	^ BlElement new
		  extent: aBarExtent;
		  position: aPoint;
		  background: aColor;
		  yourself
```

```st
LaserGameShapes class >> laserBeamBarOfExtent: aBarExtent within: anExtent color: aColor
	"Answer one bar of a beam, of aBarExtent and painted in aColor, centred in a cell of anExtent."

	^ self
		  laserBeamBarOfExtent: aBarExtent
		  at: (anExtent - aBarExtent) / 2
		  color: aColor
```
> **Note.** *Laser on mirror cell* places every bar with `laserBeamBarOfExtent:at:color:`, which leaves this method without a sender, so it goes.

This is the ordinary way to generalize a method, and you want to do it exactly this way round.
The new method is the general one, taking a position; the old method keeps its name and its callers, and becomes one line that computes the position it always computed.

No caller changes, nothing is renamed, and the centring is still written down in exactly one place.

> **Generalize by putting the general method underneath, not by adding a parameter to the method everybody calls.** A new parameter means touching every call site, and every call site then says something that used to be implied.

## The side the light comes from

The renderer has two questions to answer — which pair of drawings applies, and which half of the cell the beam covers — and one fact answers both:

```st
TargetCellRenderer >> renderBeamOn: anElement
	"The target swallows the light, so the beam stops in the middle of my cell: half a beam,
	running from the side the light arrives by. That side says both which way the beam lies and
	which half of the cell it covers."

	| side |
	side := #( #west #east #north #south ) detect: [ :each |
		        self cell isSegmentOnFor: each ].
	anElement addChild: ((#( #west #east ) includes: side)
			 ifTrue: [
				 LaserGameShapes
					 horizontalLaserBeamElementOfExtent: self class cellExtent
					 enteringFrom: side ]
			 ifFalse: [
				 LaserGameShapes
					 verticalLaserBeamElementOfExtent: self class cellExtent
					 enteringFrom: side ])
```
> **Note.** *Laser on mirror cell* draws every kind of cell from one `renderBeamOn:` on `CellRenderer`, so this method goes.

A `detect:` with no `ifNone:` again, and this time it is defensible for the reason we gave in *Making larger cells*: it is an assertion.
A lit target has exactly one lit side, because it absorbs the light instead of passing it on.

If none of the four is lit, the cell should not have been drawn at all, and the two guards of the last chapter — laser off, cell dark — are what make sure of that.
The raise would mean the guards are broken, which is precisely when you want a walkback rather than a blank cell.

Compare that with the `detect:` in the click regions, where a point outside the cell was a thing that *could* happen and needed `ifNone:`.
The rule is not "always use `ifNone:`"; it is to know which of the two you are writing.

## Under the target, not over it

The beam has to go under the target, or the light covers the ring it is supposed to be hitting.
That is one line we move, in each of the two places that build a cell:

```smalltalk
CellRenderer >> newElement
	"Answer a new element rendering my cell. The element is square, keeps me as its renderer,
	carries the cell background and border, and holds whatever my subclass draws as children: the
	beam first, then the contents of the cell over it, so that the light does not hide what it
	hits."

	| element |
	element := LaserGameCellElement new.
	element renderer: self.
	element extent: self class cellExtent.
	element geometry: BlRectangleGeometry new.
	self renderBackgroundOn: element.
	self renderBorderOn: element.
	self renderLaserOn: element.
	self renderContentsOn: element.
	^ element
```

```smalltalk
LaserGameCellElement >> redraw
	"Draw my cell again after the model changed. The cell standing at my location may be another
	one than before, since a push swaps two cells, so the renderer is chosen again — and so is
	the hint, at the point the pointer was last seen at, because an arrow kept across a redraw
	is the arrow of the cell that has moved away. A blank cell offers no push, so the arrow of
	the mirror that left goes with it, and the cross hair with the arrow. The beam is drawn here
	too, since firing the laser changes no cell but lights many of them, and it is drawn under
	the contents."

	| grid location point |
	grid := self renderer grid.
	location := self gridLocation.
	point := hintPosition.
	self removeChildren.
	hintElement := nil.
	hintRegion := nil.
	crossHairElement := nil.
	self renderer: (CellRenderer rendererFor: (grid at: location) grid: grid).
	self renderer renderBackgroundOn: self.
	self renderer renderBorderOn: self.
	self renderer renderLaserOn: self.
	self renderer renderContentsOn: self.
	point ifNotNil: [ self showPositionHintAt: point ]
```

Child order is draw order, and that is the whole mechanism: swap two lines and you get the beam underneath.
We paint nothing twice, mask nothing, and introduce no third element to repair the overlap.

It is worth noticing what this buys you over the alternative.
If a cell were one picture, "the target must stay visible" would mean drawing the target, drawing the beam over it, and then drawing the target *again* — the same four shapes, a second time, in the right order.

Here the ordering *is* the statement, it lives in one line, and the comment on both methods says why that line is where it is.

A blank cell draws no contents, so nothing about the last chapter changes.
A mirror will draw its line over the beam in the next chapter.
And we add the hint arrow with its cross hair after all of it, so it stays on top.

## The tests

We test the half beam on its own first, for both sides:

```st
LaserGameShapesTestCase >> testAHalfBeamCrossesHalfTheCellFromTheSideItComesFrom
	"A cell that swallows the light shows the beam only as far as its middle: the west half when
	the west segment is lit, the east half otherwise."

	| extent half |
	extent := 40 @ 40.
	half := extent x // 2.
	{ #west -> 0. #east -> half } do: [ :each |
		| beam |
		beam := LaserGameShapes
			        horizontalLaserBeamElementOfExtent: extent
			        enteringFrom: each key.
		self assert: (self requestedExtentOf: beam) equals: extent.
		self assert: beam children size equals: 2.
		beam children do: [ :bar |
			self assert: (self requestedExtentOf: bar) x equals: half.
			self assert: bar constraints position x equals: each value.
			self
				assert: bar constraints position y + ((self requestedExtentOf: bar) y / 2)
				equals: extent y / 2 ] ]
```
> **Note.** *Laser on mirror cell* asks `laserBeamElementOfExtent:fromSides:` with the one lit side instead of the pair of builders this test was written against.

`{ #west -> 0.
#east -> half }` is a table: each side paired with the position its bar must take.

One loop, two cases, and you see the expected value next to the input it belongs to.
Written as two blocks of assertions instead, the second block is a copy of the first with two numbers changed, which is the shape that rots.

Two more tests go with it.
`testAHalfBeamGoingUpOrDownKeepsTheHalfTheLightComesFrom` asks the same of the vertical pair, and `testAHalfBeamIsAsThickAsAWholeOne` compares a half beam with a whole one bar by bar — same thickness, same colours — which is the property that makes a beam look continuous as it crosses from one cell into the next.

Then the renderer, on the board.
The demo grid ends its beam in the target at `5@1`, entered from the west:

```smalltalk
TargetCellRendererTestCase >> testTheBeamStopsInTheMiddleOfTheTargetItReaches
	"The target swallows the light, so the beam stops in the middle of the cell. The demo grid
	sends the beam into the target at 5@1 from the west, so the beam covers the west half of the
	cell."

	| element beam half |
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid)
		           newElement.
	beam := element children first.
	half := CellRenderer cellExtent x // 2.
	self assert: (self requestedExtentOf: beam) equals: CellRenderer cellExtent.
	self assert: beam children size equals: 2.
	beam children do: [ :bar |
		self assert: (self requestedExtentOf: bar) x equals: half.
		self assert: bar constraints position x equals: 0 ]
```

The demo board only ever lights its target from the west, so the other three ways in need a board that does.
Rather than build one, we change the one we have:

```smalltalk
TargetCellRendererTestCase >> testTheBeamReachesTheTargetFromTheSideItTravelsBy
	"The beam can reach the target from any side, so the grid is asked to hold a target where the
	beam runs upwards, and the beam covers the south half of the cell it now ends in."

	| element beam half |
	grid at: 4 @ 3 put: TargetCell new.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 3) grid: grid)
		           newElement.
	beam := element children first.
	half := CellRenderer cellExtent y // 2.
	self assert: ((grid at: 4 @ 3) isSegmentOnFor: #south).
	self assert: beam children size equals: 2.
	beam children do: [ :bar |
		self assert: (self requestedExtentOf: bar) y equals: half.
		self assert: bar constraints position y equals: half ]
```

`grid at: 4 @ 3 put: TargetCell new` drops a second target into the middle of the beam's path up the fourth column, and then fires.
The cell is lit from the south, so the beam covers the bottom half.

The third assertion is again the premise stated as an assertion: *the cell really is lit from the south*.
Without it, a change to the demo board that moved the beam would leave this test asserting things about a dark cell, and the failure would point you at the beam rather than at the board.

Note too that the test needs no window, no hovering, and no repainting.
A renderer is built from the model whenever one is asked for, so changing the grid and asking again is the whole experiment.

That is worth more than it sounds: a view that caches what it drew has to be *told* to redraw, and you end up pretending to be a mouse to test it.

And the ordering the chapter is about:

```smalltalk
TargetCellRendererTestCase >> testTheTargetIsDrawnOverTheBeam
	"The beam is drawn first and the target over it, so that the light does not hide what it hits:
	the beam is the first child, and the four pieces of the target come after it."

	| element children |
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid)
		           newElement.
	children := element children.
	self assert: children size equals: 5.
	self assert: (children at: 1) children size equals: 2.
	self assert: (children at: 2) geometry class equals: BlLineGeometry.
	self assert: (children at: 3) geometry class equals: BlLineGeometry.
	self assert: (children at: 4) geometry class equals: BlCircleGeometry.
	self assert: (children at: 5) geometry class equals: BlCircleGeometry
```

Five children in order: the beam, two cross hair lines, the ring, the centre disc.
The test asserts the *list*, which is the only way to test a drawing order, and it is a reminder of something you forget easily — "is drawn over" is not a property of an element, it is a property of where that element sits among its siblings.

One consequence to be aware of: three tests we wrote in earlier chapters read the disc of the target as the fourth child of the cell element, and a lit target now has five children.
Those tests ask for the last child instead.

When the shape of a drawing changes, the tests that index into it are the ones that break, which is an argument for asking for `children last` wherever the thing you want is in fact the last thing drawn.

## Checking it

```smalltalk
LaserGameBoardExample openExampleWithLaserFired
```

The beam now ends where the light does: it comes in at the west edge of the target and stops under the ring, with the ring and its cross hairs plainly on top of it.

Look closely at where the beam meets the cross hair of the target — or open the game and magnify that corner.
The beam is centred on the cell, at 25 of 50; the cross hair is drawn along `cellExtent - 1 // 2`, which is 24.

One pixel out.
It is hard to see here and you will see it at the mirrors, where two half beams have to meet each other, so that is where we settle it.

# Laser on mirror cell

The mirror is the cell that turns the light.
It is lit on two sides at a right angle to each other, so two half beams have to meet in the middle of the cell, and the two quarters of the cell the light never reaches have to stay empty.

In this chapter we ask the cell which sides are lit, build one bar per axis from that answer, and end with a single method that draws the beam for every kind of cell there is.

That sounds like a third case of beam drawing, after the whole beam of the blank cell and the half beam of the target.
It is not.
Writing the mirror properly means noticing that all three cases are one case, and we end this chapter with a single method that draws the beam on every kind of cell there is.

## The lit sides say the whole picture

Look at what each kind of cell has in common.
A cell the beam goes straight through is lit on two opposite sides.
A mirror is lit on two sides at a right angle.
A target is lit on one side.
A cell the beam crosses twice is lit on all four.

In every one of those cases the sides that carry light are exactly what is drawn, and nothing else about the cell matters: not its class, not the lean of its mirror, not whether it is the target.

So we ask the cell for its lit sides, and for nothing else:

```smalltalk
Cell >> litSides
	"Answer the sides of me that carry light, in a fixed order. A cell the beam crosses is lit on
	the side it arrives by and on the side it leaves by, a cell that swallows the light is lit on
	one side, and a cell the beam crosses twice is lit on all four. Nothing else is needed to draw
	the beam, which is why the renderers ask this and nothing else."

	^ #( #north #east #south #west ) select: [ :each |
		  self isSegmentOnFor: each ]
```

Four lines of comment for two lines of code, and the comment is the more important half: it is the claim we build the rest of the chapter on.

The literal array fixes the order, which matters more than you would think.
`select:` keeps the order of what it is given, so `litSides` always answers north before east before south before west.

A method that answers a collection in an order nobody wrote down invites a test that passes for the wrong reason, and later a bug when the order changes.

This is also the move that makes the single beam method possible.
**Ask an object for the fact you need, not for its class.** `cell litSides` is a fact; `cell class = MirrorCell` is a guess about which facts follow from a class, and it stops working the day a fourth kind of cell is added.

## One bar for each axis

Light runs along two axes in a cell: across it, west to east, and down it, north to south.
We draw one bar for each axis that carries any light, and the only question per axis is how long the bar is and where it starts.

A bar runs the whole way across when both sides of its axis are lit, and from the lit side to the middle when only one of them is.
That is the whole of the geometry:

```smalltalk
LaserGameShapes class >> horizontalLaserBeamBarOfExtent: anExtent sides: aCollection thickness: aThickness color: aColor
	"Answer the bar of a beam that runs across a cell of anExtent, as thick as aThickness and
	painted in aColor. It runs the whole way when both the west and the east side of the cell are
	lit, and half the way, from the lit side to the middle, when only one of them is."

	| length left |
	length := ((aCollection includes: #west) and: [
		           aCollection includes: #east ])
		          ifTrue: [ anExtent x ]
		          ifFalse: [ anExtent x // 2 ].
	left := (aCollection includes: #west)
		        ifTrue: [ 0 ]
		        ifFalse: [ anExtent x - length ].
	^ self
		  laserBeamBarOfExtent: length @ aThickness
		  at: left @ ((anExtent y - aThickness) / 2)
		  color: aColor
```

Read the two assignments as two independent questions.
`length` asks how far the light goes: the whole width, or half of it.

`left` asks which end it starts at: the west edge at `0`, or `anExtent x - length`, which is the east edge when the bar is half long and `0` again when it is whole.
Neither question needs to know the answer to the other, which is why we need no case of four branches here.

The vertical bar is the same method with the axes exchanged:

```smalltalk
LaserGameShapes class >> verticalLaserBeamBarOfExtent: anExtent sides: aCollection thickness: aThickness color: aColor
	"Answer the bar of a beam that runs up and down a cell of anExtent, as thick as aThickness and
	painted in aColor. It runs the whole way when both the north and the south side of the cell are
	lit, and half the way, from the lit side to the middle, when only one of them is."

	| length top |
	length := ((aCollection includes: #north) and: [
		           aCollection includes: #south ])
		          ifTrue: [ anExtent y ]
		          ifFalse: [ anExtent y // 2 ].
	top := (aCollection includes: #north)
		       ifTrue: [ 0 ]
		       ifFalse: [ anExtent y - length ].
	^ self
		  laserBeamBarOfExtent: aThickness @ length
		  at: (anExtent x - aThickness) / 2 @ top
		  color: aColor
```

The last chapter said that two methods differing in one axis are worth leaving alone and three are worth merging.
These are the two, and they stay two.
Merging them would mean we pass in which axis is meant, and then every line would have to ask that question again.

Above them sits the method that draws the beam of a cell, and it is the only one anything else calls:

```smalltalk
LaserGameShapes class >> laserBeamElementOfExtent: anExtent fromSides: aCollection
	"Answer an element of anExtent drawing the beam of a cell lit on the sides aCollection names.
	One bar is drawn for each of the two axes light runs along: the whole way across when both
	sides of that axis are lit, and from the lit side to the middle otherwise. Two opposite sides
	are a cell the beam goes straight through, two sides at a right angle are the turn at a mirror,
	one side is the half beam a cell that swallows the light shows, and four sides are a beam that
	crosses its own path. The pale bands are drawn first and the bright cores over them, so a
	crossing shows both cores."

	| element across down |
	across := aCollection select: [ :each | #( #west #east ) includes: each ].
	down := aCollection select: [ :each | #( #north #south ) includes: each ].
	element := BlElement new
		           extent: anExtent;
		           background: Color transparent;
		           yourself.
	{
		(self laserBeamSplatterThicknessFor: anExtent)
		-> LaserGameColors laserBeamSplatterColor.
		(self laserBeamCenterThicknessFor: anExtent)
		-> LaserGameColors laserBeamCenterColor } do: [ :each |
		across ifNotEmpty: [
			element addChild: (self
					 horizontalLaserBeamBarOfExtent: anExtent
					 sides: across
					 thickness: each key
					 color: each value) ].
		down ifNotEmpty: [
			element addChild: (self
					 verticalLaserBeamBarOfExtent: anExtent
					 sides: down
					 thickness: each key
					 color: each value) ] ].
	^ element
```

Three things in there are worth your time.

The two `select:` lines split the lit sides into the sides that belong to each axis.
`across` holds whichever of `#west` and `#east` are lit, `down` whichever of `#north` and `#south` are lit, and from there we hand each bar builder only the sides that concern it.

`ifNotEmpty:` is what makes the empty quarters of a mirror empty.
An axis no light runs along contributes no bar at all, so nothing is drawn there and nothing has to be taken away again.

The target cell draws one bar per colour because only one of its axes is lit; the mirror draws two, one per axis; a cell crossed twice draws two whole ones.

The literal array of two associations — thickness pointing at colour — is the drawing order.
The loop runs twice: once for the pale wide band, once for the bright narrow core.

Both bands are added before either core, so where two beams cross, both cores lie on top and the crossing looks like two beams rather than one beam cut by the other.

Pair the numbers with the colours in a collection and loop, rather than writing the four `addChild:` sends out by hand; you then see the order in one place and the four sends cannot drift apart.

Three builders from the last two chapters are now special cases of this one: the whole beam of *Laser on blank cell* and the two half beams of *Laser on target cell*.

They go, and so does `laserBeamBarOfExtent:within:color:`, which centred a bar in a cell — the two new builders place every bar themselves, with `laserBeamBarOfExtent:at:color:`.

**When several methods turn out to be cases of one, write the one and delete the several.** The time to do it is when you can see the general method, not before: we could only see the general shape of this one once we had looked at the mirror.

## One method for every kind of cell

`renderBeamOn:` was a method each kind of renderer answered differently.
It is now one method on `CellRenderer`, and no subclass overrides it:

```smalltalk
CellRenderer >> renderBeamOn: anElement
	"Draw the beam my lit cell shows, as one child of anElement. The sides of my cell that carry
	light say the whole of what is drawn, so every kind of cell is drawn here: a blank cell the
	beam crosses, the target it ends in, the mirror it turns at, and any of them crossed twice."

	anElement addChild: (LaserGameShapes
			 laserBeamElementOfExtent: self class cellExtent
			 fromSides: self cell litSides)
```

```smalltalk
CellRenderer >> renderLaserOn: anElement
	"Draw the beam where it crosses my cell, as children of anElement. Nothing is drawn while the
	laser is off or while no light reaches my cell, which is why both questions are asked here
	rather than in each kind of cell. What a lit cell draws is #renderBeamOn:, which is the same
	for every kind of cell."

	self grid laserIsActive ifFalse: [ ^ self ].
	self cell isOff ifTrue: [ ^ self ].
	self renderBeamOn: anElement
```

Two chapters ago `renderBeamOn:` was an empty hook with a comment saying why it was empty.
Now it is a real method with no overrides at all, which is a better outcome than you would guess: an empty hook is a promise that the subclasses will disagree, and here they stopped disagreeing.

> **A method belongs in the superclass as soon as the subclasses agree about it.** Watch for the shape of that agreement while writing the subclasses.
> Three overrides that read differently but compute the same thing from the same question are one method waiting to be written.

And the mirror needs no drawing code of its own at all.
`MirrorCellRenderer >> renderContentsOn:` already draws the mirror line, and the order we settled in the last chapter adds the beam before the contents, so the mirror lies over the light it turns.

The chapter that was going to be about the mirror turns out to add nothing to the mirror.

## The one pixel from the last chapter

The last chapter left a pixel unaccounted for, and the mirror is where we settle it, because the mirror is where two bars have to meet each other.

The cell is fifty pixels wide, and a fifty-pixel cell has no middle pixel.
Its middle is the boundary between pixel 24 and pixel 25.
The two shapes that have to agree answer that differently on purpose.

We place a bar by `(anExtent - aThickness) / 2`, which puts the bright core of the beam at 21 and makes it eight pixels tall: rows 21 to 28, centred exactly on the boundary.

The cross hair of the target is a line one pixel wide, and a line has to be *on* a pixel rather than on a boundary, so it is drawn along `cellExtent - 1 // 2`, which is 24 — the pixel just above the middle.

So nothing is wrong, and nothing moves.
The line sits inside the core of the beam with three pixels of core above it and four below, which no player will ever see, and both formulas are right about the shape they place.

What the mirror needed, and now has, is the other half of that: we place the horizontal bar and the vertical bar by *the same* formula, so they share a centre and overlap in the middle square of the cell.
The elbow of a turn is square, with no notch where one bar ends and the other begins, and it took no pixel correction to get there.

> **Two shapes centred by the same arithmetic meet exactly; two shapes centred by different arithmetic meet nearly.** When two shapes have to touch, place them with one method, or at least with one expression written once.
> And when a shape is centred in an even-sized space, decide whether it wants a pixel or a boundary, and let the comment say which.

## The tests

We ask the shapes for the two new cases: the turn, and the beam that crosses its own path.

```smalltalk
LaserGameShapesTestCase >> testABeamThatArrivesFromTwoSidesTurnsInTheMiddle
	"A mirror sends the beam on by another side, so two half beams meet in the middle of the cell:
	one from the side the light arrives by, one to the side it leaves by."

	| extent beam half |
	extent := 40 @ 40.
	half := extent x // 2.
	beam := LaserGameShapes
		        laserBeamElementOfExtent: extent
		        fromSides: #( #west #north ).
	self assert: beam children size equals: 4.
	self assert: (self requestedExtentOf: beam children first) x equals: half.
	self assert: beam children first constraints position x equals: 0.
	self assert: (self requestedExtentOf: beam children second) y equals: half.
	self assert: beam children second constraints position y equals: 0.
	(beam children asArray first: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamSplatterColor ].
	(beam children asArray last: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamCenterColor ]
```

Four children, two of them half the width and starting at the west edge, two of them half the height and starting at the north edge: that is the turn.

The two loops at the end are the drawing order, and they are the assertion that matters most in the chapter, because the order is the only thing in `laserBeamElementOfExtent:fromSides:` that you cannot check by looking at a shape.

```smalltalk
LaserGameShapesTestCase >> testABeamThatCrossesItsOwnPathDrawsBothCoresOverBothBands
	"A cell all four sides of which are lit is crossed twice. Both bands run the whole way across,
	and both bright cores are drawn after them, so neither core is buried under the other band."

	| extent beam |
	extent := 40 @ 40.
	beam := LaserGameShapes
		        laserBeamElementOfExtent: extent
		        fromSides: #( #north #east #south #west ).
	self assert: beam children size equals: 4.
	beam children do: [ :bar |
		self
			assert: ((self requestedExtentOf: bar) x max: (self requestedExtentOf: bar) y)
			equals: extent x ].
	(beam children asArray first: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamSplatterColor ].
	(beam children asArray last: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamCenterColor ]
```

The `max:` is a small trick you should borrow.
Each bar is long on one axis and thin on the other, and the test does not care which; asking for the larger of the two numbers says "the long side of this bar" without a case for horizontal and vertical.

### The beam tests of the last chapters, rewritten

Six tests we wrote in the last three chapters asked the three builders that have just gone.
They now ask the one builder, with `#( #west #east )` for a whole beam across, `#( #north #south )` for a whole beam down, two sides at a right angle for a turn, and one side for a half beam.

What each of them claims is unchanged, which is the point: a test that has to be rewritten because the code was merged should still assert the same thing afterwards.

```smalltalk
LaserGameShapesTestCase >> testABeamIsAPaleBandWithABrightCentreOnIt
	"A beam is an element holding two bars: a pale wide one first, a bright narrow one on top of
	it, both running the whole length of the cell and both centred across it."

	| extent element splatter centre |
	extent := 50 @ 50.
	element := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #west #east ).
	self assert: (self requestedExtentOf: element) equals: extent.
	self assert: element children size equals: 2.
	splatter := element children first.
	centre := element children second.
	self
		assert: splatter background paint color
		equals: LaserGameColors laserBeamSplatterColor.
	self
		assert: centre background paint color
		equals: LaserGameColors laserBeamCenterColor.
	self assert: (self requestedExtentOf: splatter) x equals: extent x.
	self assert: (self requestedExtentOf: centre) x equals: extent x.
	self
		assert: (self requestedExtentOf: centre) y
		< (self requestedExtentOf: splatter) y.
	element children do: [ :each |
		self
			assert: each constraints position + ((self requestedExtentOf: each) / 2)
			equals: extent / 2 ]
```

```smalltalk
LaserGameShapesTestCase >> testAVerticalBeamIsTheHorizontalOneTurned
	"A beam runs across a cell or down it, and the two are the same two bars with their sides
	exchanged, so the two beams meet at the same thickness where a path turns."

	| extent horizontal vertical |
	extent := 50 @ 50.
	horizontal := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #west #east ).
	vertical := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #north #south ).
	self assert: (self requestedExtentOf: vertical) equals: extent.
	self assert: vertical children size equals: 2.
	vertical children asArray
		with: horizontal children asArray
		do: [ :down :across |
			self
				assert: (self requestedExtentOf: down)
				equals: (self requestedExtentOf: across) transposed.
			self
				assert: down background paint color
				equals: across background paint color.
			self
				assert: down constraints position + ((self requestedExtentOf: down) / 2)
				equals: extent / 2 ]
```

```smalltalk
LaserGameShapesTestCase >> testTheBeamGetsThickerWithTheCell
	"Both thicknesses are computed from the extent, so the beam keeps its proportions: twice the
	cell, twice the beam. A beam of a cell too small to halve is still one pixel thick."

	| small large |
	small := LaserGameShapes laserBeamElementOfExtent: 30 @ 30 fromSides: #( #west #east ).
	large := LaserGameShapes laserBeamElementOfExtent: 60 @ 60 fromSides: #( #west #east ).
	self
		assert: (self requestedExtentOf: large children first) y
		equals: (self requestedExtentOf: small children first) y * 2.
	self
		assert: (self requestedExtentOf: large children second) y
		equals: (self requestedExtentOf: small children second) y * 2.
	self
		assert: (self requestedExtentOf: small children first) y
		equals: (LaserGameShapes laserBeamSplatterThicknessFor: 30 @ 30).
	self
		assert: (self requestedExtentOf: small children second) y
		equals: (LaserGameShapes laserBeamCenterThicknessFor: 30 @ 30).
	self
		assert: (LaserGameShapes laserBeamCenterThicknessFor: 2 @ 2)
		equals: 1
```

```smalltalk
LaserGameShapesTestCase >> testAHalfBeamCrossesHalfTheCellFromTheSideItComesFrom
	"A cell that swallows the light shows the beam only as far as its middle: the west half when
	the west segment is lit, the east half otherwise."

	| extent half |
	extent := 40 @ 40.
	half := extent x // 2.
	{ #west -> 0. #east -> half } do: [ :each |
		| beam |
		beam := LaserGameShapes
			        laserBeamElementOfExtent: extent
			        fromSides: { each key }.
		self assert: (self requestedExtentOf: beam) equals: extent.
		self assert: beam children size equals: 2.
		beam children do: [ :bar |
			self assert: (self requestedExtentOf: bar) x equals: half.
			self assert: bar constraints position x equals: each value.
			self
				assert: bar constraints position y + ((self requestedExtentOf: bar) y / 2)
				equals: extent y / 2 ] ]
```

```smalltalk
LaserGameShapesTestCase >> testAHalfBeamGoingUpOrDownKeepsTheHalfTheLightComesFrom
	"The same half beam turned a quarter: the bottom half when the south segment is lit, the top
	half otherwise."

	| extent half |
	extent := 40 @ 40.
	half := extent y // 2.
	{ #north -> 0. #south -> half } do: [ :each |
		| beam |
		beam := LaserGameShapes
			        laserBeamElementOfExtent: extent
			        fromSides: { each key }.
		self assert: (self requestedExtentOf: beam) equals: extent.
		self assert: beam children size equals: 2.
		beam children do: [ :bar |
			self assert: (self requestedExtentOf: bar) y equals: half.
			self assert: bar constraints position y equals: each value.
			self
				assert: bar constraints position x + ((self requestedExtentOf: bar) x / 2)
				equals: extent x / 2 ] ]
```

```smalltalk
LaserGameShapesTestCase >> testAHalfBeamIsAsThickAsAWholeOne
	"Half a beam is half as long and no thinner, so a beam that stops in the middle of a cell
	meets a beam that crosses one without a step in it."

	| extent whole |
	extent := 40 @ 40.
	whole := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #west #east ).
	#( #west #east ) do: [ :side |
		| half |
		half := LaserGameShapes
			        laserBeamElementOfExtent: extent
			        fromSides: { side }.
		half children asArray with: whole children asArray do: [ :bar :wholeBar |
			self
				assert: (self requestedExtentOf: bar) y
				equals: (self requestedExtentOf: wholeBar) y.
			self
				assert: bar background paint color
				equals: wholeBar background paint color ] ]
```

### On the board

The demo grid turns the beam north at the mirror of 4@5, which is the mirror we built the board around:

```smalltalk
MirrorCellRendererTestCase >> testTheBeamTurnsAtAMirror
	"The demo grid turns the beam north at the mirror of 4@5, which is lit on its west side, where
	the light arrives, and on its north side, where it leaves. The cell shows two half beams, and
	nothing at all in the two quadrants the light never reaches."

	| grid element beam half extent |
	grid := GridExample demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 5) grid: grid)
		           newElement.
	extent := CellRenderer cellExtent.
	half := extent x // 2.
	beam := element children first.
	self assert: beam children size equals: 4.
	self assert: (self requestedExtentOf: beam children first) x equals: half.
	self assert: beam children first constraints position x equals: 0.
	self assert: (self requestedExtentOf: beam children second) y equals: half.
	self assert: beam children second constraints position y equals: 0
```

That is the shape test again, this time through a real cell of a real grid that has been fired.
Both are worth having.
The shapes test says the builder draws a turn; this one says the mirror of a played board asks for one.

```smalltalk
MirrorCellRendererTestCase >> testTheMirrorIsDrawnOverTheBeam
	"The mirror is drawn after the beam, so the light does not hide the thing that turns it: the
	beam is the first child and the mirror is the last."

	| grid element |
	grid := GridExample demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 5) grid: grid)
		           newElement.
	self assert: element children size equals: 2.
	self assert: element children first children size equals: 4.
	self
		assert: element children last geometry class
		equals: BlLineGeometry
```

You can find a cell crossed twice by playing the game, but a test does not have to look for one.
We can tell a cell that the light enters it, and tell a grid that its laser is on:

```smalltalk
MirrorCellRendererTestCase >> testAMirrorCrossedTwiceShowsBothBeamsWhole
	"A mirror can be lit on all four of its sides, where the beam crosses its own path. Both beams
	then run the whole way across, and the turn needs no case of its own."

	| grid cell element beam extent |
	grid := Grid new.
	cell := MirrorCell new.
	cell leanLeft.
	grid at: 1 @ 1 put: cell.
	cell laserEntersFrom: #west.
	cell laserEntersFrom: #north.
	grid laserIsActive: true.
	extent := CellRenderer cellExtent.
	element := (CellRenderer rendererFor: cell grid: grid) newElement.
	beam := element children first.
	self assert: beam children size equals: 4.
	beam children do: [ :bar |
		self
			assert: ((self requestedExtentOf: bar) x max: (self requestedExtentOf: bar) y)
			equals: extent x ]
```

```smalltalk
CellRendererTestCase >> testABlankCellCrossedTwiceShowsBothBeams
	"A blank cell can be crossed twice as well, which lights all four of its sides. Nothing extra
	is asked for: both bands are drawn the whole way across and both cores go over them."

	| cell element beam extent |
	grid := Grid new.
	cell := BlankCell new.
	grid at: 1 @ 1 put: cell.
	cell laserEntersFrom: #west.
	cell laserEntersFrom: #north.
	grid laserIsActive: true.
	extent := CellRenderer cellExtent.
	element := (CellRenderer rendererFor: cell grid: grid) newElement.
	beam := element children first.
	self assert: beam children size equals: 4.
	beam children do: [ :bar |
		self
			assert: ((self requestedExtentOf: bar) x max: (self requestedExtentOf: bar) y)
			equals: extent x ].
	self
		assert: beam children last background paint color
		equals: LaserGameColors laserBeamCenterColor
```

Those last two tests cost four lines each to set up and they cover the case a player hits once in a while and never reports properly.

**A state that is awkward to reach by playing is a state to build directly in a test.** Building it by hand is not cheating: `laserEntersFrom:` and `laserIsActive:` are the same messages the game itself sends.

## Checking it

```smalltalk
LaserGameBoardExample openExampleWithLaserFired
```

The beam leaves the laser, turns at the mirror of 4@5, turns again at 4@1 and stops in the middle of the target.

Look at the two elbows: you see square corners, with no notch between the end of one bar and the side of the other, because the two bars overlap in the middle of the cell instead of being cut apart there.

The beam is now drawn for every cell it can cross, by one method that asks each cell one question, and the game is complete: a board of any size, dealt at random, played with the mouse, counted, and lit.
The two chapters that close this section are about the window it lives in rather than the game itself — making it resize, and making its counters readable.

# A window the player can resize

The board can be any size since the last chapter, but the window it opens in cannot.
`openOn:` gives the space the extent the grid asks for, and dragging the corner of that window leaves the game the size it was, with the desktop colour filling the rest of the frame.

In this chapter we give the game a natural extent and a scale, so that it grows to fill whatever window it is given and keeps its shape in a window of another shape.

That is worth fixing, and it is cheap to fix, for a reason that goes back to the first drawing chapter.
A cell is a set of geometries rather than a picture, so it is drawn from its own coordinates every frame and has no resolution of its own.

And an element carries a transformation that the whole of its subtree is drawn and hit-tested through.
So we scale the game by setting one of those transformations, and the beam, the arrows and the LED digits all follow it at full sharpness.

Nothing in the drawing code changes, and no number we wrote down in the earlier chapters moves: the cell is still fifty pixels, the panel still a hundred and ten, and the margin still ten.

## The size the game is drawn at

The extent the board asks for stops being the size of the window and becomes the size the drawing is scaled *from*, which we give a name of its own:

```smalltalk
LaserGameElement >> naturalExtent
	"Answer the extent the game is drawn at: the board, the panel and the margins, in pixels. The
	window can be any size; this one is the size the drawing is scaled from."

	^ self class extentForGrid: self grid
```

A method whose whole body forwards to another one may look like waste to you, and is not.
The name is the point: `naturalExtent` says what the number means here, while `extentForGrid:` says only how it is computed.

> **When a value starts meaning something new, give it a name before you give it a user.**

A window of another size wants a scale factor, and a window of another shape wants the tighter of the two directions, so that the cells stay square:

```smalltalk
LaserGameElement >> scaleToFitIn: anExtent
	"Answer how much the game has to be scaled by to fill a window of anExtent without changing
	its shape: the tighter of the two directions, so the whole board stays in view and the cells
	stay square."

	| natural |
	natural := self naturalExtent.
	^ ((anExtent x / natural x) min: (anExtent y / natural y)) asFloat
```

Two ratios, and the smaller of them wins.
Take the larger and you get a game that fills the window in one direction and runs off the edge in the other.

`asFloat` is there because the two ratios are fractions.
Pharo divides integers exactly, so `760 / 380` is the fraction `2` and `761 / 380` is the fraction `761/380`, not `2.00263...`.

Exact arithmetic is a gift everywhere else in this game — it is why the beam is centred to the pixel — but a scale factor goes into a transformation matrix, which wants a float, and a chain of unreduced fractions through a matrix is slower than it is worth.
Convert where the number leaves the arithmetic.

Taking the tighter direction leaves the looser one with a strip of space over, and the game looks least out of place when we split that strip between the two sides:

```smalltalk
LaserGameElement >> positionToCenterIn: anExtent
	"Answer where the scaled game sits in a window of anExtent: in the middle of it, with the
	leftover of the looser direction split between the two sides."

	^ (anExtent - (self naturalExtent * (self scaleToFitIn: anExtent))) / 2
```

One line, and you read it as the sentence it is: the window less the scaled game, halved.
Both of its terms are points, so the subtraction, the multiplication, and the halving all happen on both axes at once; the axis that was scaled to fit contributes zero and the looser axis contributes the strip.

The two together are the whole of the feature:

```smalltalk
LaserGameElement >> fitIn: anExtent
	"Scale the game to a window of anExtent and centre it there. Scaling costs nothing here,
	because every cell is drawn from geometries rather than from a bitmap. A window of no size is
	left alone, since a space announces one while it opens."

	(anExtent x > 0 and: [ anExtent y > 0 ]) ifFalse: [ ^ self ].
	self transformDo: [ :aBuilder |
		aBuilder
			topLeftOrigin;
			scaleBy: (self scaleToFitIn: anExtent) ].
	self position: (self positionToCenterIn: anExtent)
```

`transformDo:` hands out a builder rather than a matrix, and `topLeftOrigin` says which point of the element the scale keeps still — the top left corner, since the position set on the next line is where that corner goes.

A builder *replaces* the transformation rather than adding to it, which is what makes `fitIn:` safe to send again: a second call scales from the natural size once more and not from the size the game is already at.

A method that doubles the effect when it is called twice is a bug waiting for a player who drags a corner, and dragging a corner sends a stream of these.

The guard on the first line is not defensive programming either.
A space announces its extent while it is opening, and the first extent it announces is `0@0`.

Scaling by zero collapses the game to a point it never comes back from, because the next scale is computed from the natural extent and multiplied into a matrix that is already zero in both directions.

## Following the window

Bloc puts the root element of a space under a resizer that matches the space, so the root extent is the window extent, and the root announces a `BlElementExtentChangedEvent` whenever the player drags the corner.
`openOn:` subscribes to it:

```smalltalk
LaserGameElement class >> openOn: aGrid
	"Open a space showing a game on aGrid and answer it. The space starts at the size the game is
	drawn at, and the game follows it from there: a window the player resizes scales the game to
	match.

	LaserGameElement openOn: GridFactory defaultGrid"

	| space element |
	space := BlSpace new.
	element := self on: aGrid.
	space extent: (self extentForGrid: aGrid).
	space title: 'Laser Game'.
	space root addChild: element.
	space root
		addEventHandlerOn: BlElementExtentChangedEvent
		do: [ :anEvent | element fitIn: space root extent ].
	element fitIn: space extent.
	space show.
	^ space
```

Three details in there are the chapter.

We still open the space at the natural extent, so a game nobody resizes looks exactly as it did in every earlier chapter.

The `fitIn:` before `show` is there for the same reason the guard is.
It sets the scale once, from the extent the space was given, rather than waiting for a resize that may never come.

**Subscribing to an event tells you about changes; it does not tell you the state you started in.** Whenever you add a handler for "this changed", ask whether the first value needs to be handled as well.

And the game is no longer added and forgotten: `openOn:` keeps it in a temporary so that the handler block can reach it.
The block holds on to `element` and to `space`, which is why we name both here rather than chaining them into one expression.

## The tests

Four tests, all headless.
None of them opens a space.
We ask `fitIn:` of a detached element, and read back what it did from the transformation matrix and from `constraints position`, which is where `position:` writes and what a layout pass later reads.

The `position` and the `extent` of a detached element are both still `0@0`, which is why we assert neither.

A window of exactly twice the extent is the simple case:

```st
LaserGameElementTestCase >> testAGameScalesToFillTheWindowItIsGiven
	"The game is drawn at the size the board asks for and scaled to whatever the window is, so a
	window of twice the extent shows the same game twice as big, filling it."

	| game |
	game := LaserGameElement on: GridExample demoGrid.
	self assert: game naturalExtent equals: 380 @ 270.
	game fitIn: 760 @ 540.
	self assert: (game scaleToFitIn: 760 @ 540) equals: 2.0.
	self assert: game transformation matrix sx equals: 2.0.
	self assert: game transformation matrix sy equals: 2.0.
	self assert: game constraints position equals: 0 @ 0
```
> **Note.** *A missed bug*, the second chapter of the next section, reads the natural extent from the game instead of writing it down, so that the test holds at any cell size.

A window of another shape is the case the `min:` is there for.
The demo board is 380 by 270.
Twice as wide but no taller scales by 1.0 and leaves 380 pixels over, so the game sits 190 in; as tall as the doubled board but no wider scales by 1.0 again and leaves 270, so it sits 135 down:

```st
LaserGameElementTestCase >> testAGameKeepsItsShapeInAWindowOfAnotherShape
	"A board is as wide and as tall as it is. A window of another shape scales the game by the
	tighter of the two directions and centres what is left over, so the cells stay square and the
	game is never stretched."

	| game |
	game := LaserGameElement on: GridExample demoGrid.
	game fitIn: 760 @ 270.
	self assert: (game scaleToFitIn: 760 @ 270) equals: 1.0.
	self assert: game transformation matrix sx equals: 1.0.
	self assert: game constraints position equals: 190 @ 0.
	game fitIn: 380 @ 540.
	self assert: game transformation matrix sx equals: 1.0.
	self assert: game constraints position equals: 0 @ 135
```
> **Note.** *A missed bug* rewrites this test the same way, and the two windows become twice the natural extent in one direction only.

Shrinking is the same arithmetic in the other direction, and we give it a test of its own, because the alternative — a window that cuts the board off at its edge — is what a fixed drawing in a resizable window usually does:

```st
LaserGameElementTestCase >> testAGameShrinksWithASmallerWindow
	"A window smaller than the board scales the game down rather than cutting it off, so the whole
	board is always in view."

	| game |
	game := LaserGameElement on: GridExample demoGrid.
	game fitIn: 190 @ 135.
	self assert: game transformation matrix sx equals: 0.5.
	self assert: game constraints position equals: 0 @ 0
```
> **Note.** Rewritten in *A missed bug* as half the natural extent.

And the opening extent, which asserts that a window of no size changes nothing — not that it scales to nothing:

```st
LaserGameElementTestCase >> testAGameIgnoresAWindowOfNoSize
	"A space announces its extent while it is being opened, and that extent can be nothing at all.
	Scaling by zero would take the game off the screen, so a window of no size is left alone."

	| game |
	game := LaserGameElement on: GridExample demoGrid.
	game fitIn: 760 @ 540.
	game fitIn: 0 @ 0.
	self assert: game transformation matrix sx equals: 2.0.
	self assert: game constraints position equals: 0 @ 0
```
> **Note.** Rewritten in *A missed bug* in the same way as the three above it.

Read that last test once more.
It scales to a real window first, and *then* passes `0@0`.
A test that only passed `0@0` would pass against a `fitIn:` that did nothing at all.
**Test a guard by doing the thing it protects first, so that a method which ignores everything cannot pass.**

The four tests also share a shape worth your notice: each one sends `fitIn:` and asserts on two things, the matrix and the position.
Those are the two things the method sets.
A test that checks one of them and not the other leaves half the method uncovered, and the half it leaves out is the half that will break.

## Checking it

```smalltalk
LaserGameElementExample openStandardExample
```

Drag the corner of the window.
You get the board, the panel, the buttons, and the counters growing and shrinking together, the cells staying square, and the game sitting in the middle of whatever shape the window is left in.

Clicking still works where you see the cells, and we did nothing to make that happen: Bloc runs its hit test through the same transformation it draws through, so a mirror at twice the size is clicked at twice the coordinates without a line of the click code knowing that anything was scaled.

# Counters the player can read

Open the game and the two counters read `88E`.
Three faults are sitting on top of each other there, and we separate them before fixing any of them: an unlit segment painted in a colour that still shows, a highlight nobody can see, and a display too narrow for the digit on its right.

Nothing is broken, which is what makes this interesting.
Both counters hold the right number — `updateCounters` sets them on every move and every shot, and the tests of the counter chapter say so and pass.
The model is right, the wiring is right, and the screen is unreadable.

In this chapter we hunt one bug from the symptom to the three faults behind it.
It is the last chapter of the section, and the most useful one for you to read twice, because a display that shows the wrong thing while holding the right thing is the hardest kind of fault to think about.

## Where the fault is not

Start by ruling things out, cheaply, in a playground:

```smalltalk
| game |
game := LaserGameElementExample openExample.
game movesCounter value
```

That answers `0`, and it goes up as you click mirrors.
So the counter holds the right number and the only thing left is the drawing.

> **When a screen is wrong, ask the model what it holds before you read a line of drawing code.** Half of all drawing bugs are model bugs, and the question costs one line.
> Here the answer sends us to the drawing, and it also tells us something about the tests: the counter tests assert on values and on colours of individual segments, and all of them pass.
> A display can be made of correct parts and still be unreadable, because readability is a fact about the parts *together*.

## A zero that reads as an eight

A seven-segment digit shows a zero by lighting six of its segments and leaving the middle bar dark.
It shows an eight by lighting all seven.

So a zero that reads as an eight means the dark segment is not dark — every digit is showing all seven of its segments, the lit ones in pale lavender and the unlit ones in a dark lavender, and both of them plainly visible.

Which raises the question of what an unlit segment is supposed to look like.
Paint it in nothing at all and you get a hole in the digit, showing whatever is behind the counter.
Behind the counter is the bright ramp of the control panel, so a hole would be as visible as a lit segment, and brighter.

The answer is that a display is not a row of digits floating on the panel.
It is a dark slab with digits on it, and an unlit segment is painted the colour of that slab, so it vanishes into it.

In the counter chapter we wrote the colour and forgot the slab: `counterDigitOffColor` was a dark lavender we chose to disappear into a background nothing ever drew, so it sat on bright cyan instead, where a dark lavender is the most visible thing on the panel.

So the slab gets a colour of its own, and we define the unlit segment to be that colour rather than a colour that happens to match it:

```smalltalk
LaserGameColors class >> counterBodyColor
	"Answer the color of the slab a counter shows its digits on: a dark lavender. A segment that
	is not lit is painted this same color, so only the lit segments are seen."

	^ Color r: 0.33 g: 0.33 b: 0.52
```

```smalltalk
LaserGameColors class >> counterDigitOffColor
	"Answer the color of a segment that is not lit: the slab behind it, which is how a segment is
	hidden."

	^ self counterBodyColor
```

That second method is the fix, and it is three words long.
Note what it is *not*: it is not the same literal colour written a second time.

**When two colours have to be equal, write one of them as the other.** Two identical literals are two numbers that will drift apart the first time somebody adjusts one of them, and the drift shows up as exactly the bug this chapter is about.

Then the display carries the slab:

```smalltalk
LaserGameLedElement >> initialize
	"A display is a dark slab with a row of digits on it, one gap apart. The slab is the colour an
	unlit segment takes too, so that only the lit segments are seen. The gap is a margin on each
	digit but the first rather than the cell spacing of the layout, since a linear layout spaces
	the cells from its own edges as well and the last digit would then be clipped."

	super initialize.
	value := 0.
	digitCount := 0.
	highlighted := false.
	digitElements := #(  ).
	self background: LaserGameColors counterBodyColor.
	self layout: BlLinearLayout horizontal
```

One line of that method is the whole of the visibility fix.
An unlit segment is still painted, still in its own place, and still the colour it always was — only now the thing behind it is that colour too.

## A highlight nobody can see

The same look at the screen settles a second colour.
The counter of the beam is meant to brighten while the laser fires, and it did change colour: the highlight was the LED lavender, and the normal state was that same lavender darkened by a few per cent.

Two shades of the same thing, side by side, on a dark slab.
The code was doing exactly what we told it and the effect was invisible.

A highlight has to be a difference your eye reads without being asked to compare:

```smalltalk
LaserGameColors class >> counterDigitHighlightColor
	"Answer the color a counter lights its segments in while it is highlighted. The counter of the
	beam is highlighted while the laser fires, so this is almost white, against the lavender of
	the counter beside it."

	^ Color r: 0.95 g: 1.0 b: 1.0
```

```smalltalk
LaserGameLedElement >> onColor
	"Answer the color of a lit segment: almost white while I am highlighted, the lavender of the
	LED otherwise."

	^ highlighted
		  ifTrue: [ LaserGameColors counterDigitHighlightColor ]
		  ifFalse: [ LaserGameColors counterDigitColor ]
```

Only the lit segments change.
The unlit ones keep the colour of the slab, because an unlit segment of a highlighted counter is still an unlit segment.

## The last digit was outside the display

When we read the digit positions in the inspector we turned up a third fault, and this one is arithmetic rather than colour.

A display of three digits is thirty-four pixels wide: three digits of ten, and two gaps of two.
Its digits stood at 2, 14, and 26.

Ten pixels from 26 is 36, which is two pixels past the right edge of a thirty-four-pixel element — and Bloc clips a child to the bounds of its parent, so the third digit lost its last two columns.
That is the `E` at the end of `88E`: a clipped eight.

The gap was the `cellSpacing` of the row, and a `BlLinearLayout` puts its cell spacing *around* the cells as well as between them: one gap before the first digit, one between each pair, and one after the last.
Four gaps for three digits, where we computed the width for two.

The same fault appeared in the row of buttons in *Add move counter and randomizer*, and we fix it the same way.
A gap between things belongs to the things that have one in front of them:

```smalltalk
LaserGameLedElement >> rebuildDigits
	"Replace my digits with digitCount fresh ones and take the size they need. Every digit but the
	first carries the gap in front of it as a margin."

	self removeChildren.
	digitElements := (1 to: digitCount) collect: [ :each | self newDigitElement ].
	digitElements allButFirst do: [ :each |
		each margin: (BlInsets left: self class digitGap) ].
	digitElements do: [ :each | self addChild: each ].
	self extent: (self class extentForDigits: digitCount).
	self updateDigits
```

`allButFirst` is the whole of it: every digit except the first carries the gap on its left as a margin, the layout spaces nothing of its own, and `extentForDigits:` is now the width it always claimed to be.

> **Twice is a pattern.** The second time a framework default surprises you in the same way, stop treating it as a surprise and write down the rule: `cellSpacing` is for a layout whose own size follows its cells; a layout with a width of its own wants margins on the cells.

## The tests

Three tests hold the three facts, and all three are tests we could not have written before we looked at the screen.
That is the honest order of events, and it is worth saying plainly: these are tests we wrote *after* the bug, to hold the fix.

Tests written first catch the faults you can imagine.
Reading the screen catches the rest, and then you write the test.

What is behind an unlit segment is as much a part of the display as the segment itself:

```smalltalk
LaserGameLedElementTestCase >> testUnlitSegmentsVanishIntoTheBody
	"A display is a dark slab, and a segment that is not lit is the colour of that slab, so only
	the lit ones are seen. The display has to carry the slab as its own background: on the ramp
	behind the window an unlit segment would otherwise read as a lit one."

	| led unlit |
	led := LaserGameLedElement digits: 1.
	led value: 1.
	unlit := led digitElements first children first.
	self
		assert: led background paint color
		equals: LaserGameColors counterBodyColor.
	self
		assert: unlit background paint color
		equals: LaserGameColors counterBodyColor.
	self
		assert: LaserGameColors counterDigitOffColor
		equals: LaserGameColors counterBodyColor
```

The last assertion looks to you like a test of nothing — one method answers another, and the test says so.
It is the one assertion in the chapter that would have caught this fault before a player saw it.

The other two say the slab and the segment are the same colour *today*; this one says they are the same colour by construction.

The arithmetic that was wrong is the arithmetic the next test does: the width the row claims, against the width its cells, their margins, and its own spacing actually take.

```smalltalk
LaserGameLedElementTestCase >> testTheDigitsFitInsideTheDisplay
	"Every digit has to be inside the display, which clips what sticks out of it. A linear layout
	adds its cell spacing around the cells as well as between them, so the gap between two digits
	is a margin on each digit but the first, and the row comes to exactly the width the display
	takes."

	| led spacing used |
	led := LaserGameLedElement digits: 3.
	spacing := led layout cellSpacing.
	used := (led digitElements size + 1 * spacing)
	        + (led digitElements inject: 0 into: [ :sum :each |
			         sum + each constraints horizontal resizer size + each margin left
			         + each margin right ]).
	self assert: used equals: (LaserGameLedElement extentForDigits: 3) x.
	self assert: led digitElements first margin left equals: 0.
	self
		assert: led digitElements second margin left
		equals: LaserGameLedElement digitGap
```

Read the expression for `used`.
It counts the spacing the way the layout counts it — `size + 1` gaps, not `size - 1` — and then adds every cell with its own margins.

If you put the gap back into `cellSpacing`, `used` grows by four and the first assertion fails, which is the clipping caught in arithmetic instead of in pixels.

Note also that the test asks `led layout cellSpacing` rather than assuming it is zero.
A test that spells out the value it expects would have to be edited if we ever used the spacing for something else; this one keeps holding the claim that matters, which is that the parts add up to the whole.

And the highlight test we wrote in the counter chapter keeps its name and its shape, with the two colours it now expects:

```smalltalk
LaserGameLedElementTestCase >> testHighlightingBrightensTheLitSegments
	"The counter is highlighted while the laser fires. Highlighting changes the colour of the
	segments that are lit and leaves the others alone: the counter of the beam is almost white
	while the laser fires, and the move counter beside it stays the lavender of a dim segment."

	| led digit lit unlit |
	led := LaserGameLedElement digits: 1.
	led value: 1.
	digit := led digitElements first.
	lit := digit children second.
	unlit := digit children first.
	self deny: led highlighted.
	self
		assert: lit background paint color
		equals: LaserGameColors counterDigitColor.
	led highlighted: true.
	self assert: led highlighted.
	self
		assert: lit background paint color
		equals: LaserGameColors counterDigitHighlightColor.
	self
		assert: unlit background paint color
		equals: LaserGameColors counterDigitOffColor
```

It asserts the state before the highlight, then the state after it, then that the unlit segment was not touched.
Three assertions for a method of three lines, and the third is the one that keeps the next change honest.

## Checking it

```smalltalk
LaserGameElementExample openExample
```

You get both counters reading `0` on a dark slab, with two blank digits in front of it.
Fire the laser: the counter of the beam turns almost white and shows the length of the path.

Stop it and it goes back to zero and to lavender.
Click a mirror and the move counter follows, one digit at a time, up to three digits.

That closes the game as we first sketched it: a board, a laser, mirrors that turn it, counters you can read, and a window you can resize.

The next section is about what happens afterwards — the bug our tests in this section did not catch, the features a player asks for once the game works, and the cleaning up that each of them turns out to need.