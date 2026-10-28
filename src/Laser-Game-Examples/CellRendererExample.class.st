"
I offer one cell renderer open in a space of its own, with no board around it.

My example opens a window on the element a `CellRenderer` draws and answers the `BlSpace` it opened, which is how the rendering chapters look at a single cell before there is a board to put it on.
"
Class {
	#name : 'CellRendererExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
CellRendererExample class >> openExample [
	"Open one blank cell in a space of its own, to look at it and change it.
	CellRendererExample openExample"

	<sampleInstance>
	| grid renderer space |
	grid := Grid new.
	renderer := CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid.
	space := BlSpace new.
	space extent: CellRenderer cellExtent * 3.
	space title: 'Laser Game cell'.
	space root addChild: renderer newElement.
	space show.
	^ space
]
