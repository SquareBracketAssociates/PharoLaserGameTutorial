"
I offer single cells to look at.

Most of my examples answer one cell read off a board, so the inspector opens on the Sides tab, which says where light entering each side leaves, and on the Picture tab, which draws the cell the way the board draws it. `mirrorOnNoBoard` stands on no board at all, because it is the only cell you can build before a grid deals one.

A mirror adds the Lean tab, which turns it and shows what every turn does.
"
Class {
	#name : 'CellExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
CellExample class >> blankCell [
	"A blank cell of the demo board, at 1@1: the one cell the Sides tab has nothing to bend.
	CellExample blankCell"

	<sampleInstance>
	^ GridExample demoGrid at: 1 @ 1
]

{ #category : 'examples' }
CellExample class >> litMirrorCell [
	"The first mirror the beam crosses on the demo board, so the Picture tab draws it the bright way.
	CellExample litMirrorCell"

	<sampleInstance>
	| grid |
	grid := GridExample demoGrid.
	grid fireLaser.
	^ (grid laserBeamPath detect: [ :each | each cell class = MirrorCell ]) cell
]

{ #category : 'examples' }
CellExample class >> litTargetCell [
	"The target of the demo board with the beam in it: the board as it looks when the game is won.
	CellExample litTargetCell"

	<sampleInstance>
	| grid |
	grid := GridExample demoGrid.
	grid fireLaser.
	^ grid at: 5 @ 1
]

{ #category : 'examples' }
CellExample class >> mirrorCell [
	"The mirror at 1@2 of the demo board, dark and leaning one way.
	CellExample mirrorCell"

	<sampleInstance>
	^ GridExample demoGrid at: 1 @ 2
]

{ #category : 'examples' }
CellExample class >> mirrorOnNoBoard [
	"A mirror leaning right that stands on no board. It is the only cell you can build before a
	grid deals one: its Sides tab answers the four questions a cell is asked, and its Lean tab
	turns it.
	CellExample mirrorOnNoBoard"

	<sampleInstance>
	^ MirrorCell leanRight
]

{ #category : 'examples' }
CellExample class >> targetCell [
	"The target of the demo board, at 5@1, before the beam reaches it.
	CellExample targetCell"

	<sampleInstance>
	^ GridExample demoGrid at: 5 @ 1
]
