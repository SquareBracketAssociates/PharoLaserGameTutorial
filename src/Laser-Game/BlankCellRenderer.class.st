"
I render a BlankCell: a background and a border, and nothing inside.

I am selected for a cell by `CellRenderer class >> rendererFor:`, which matches my modelClass against the class of the cell.
"
Class {
	#name : 'BlankCellRenderer',
	#superclass : 'CellRenderer',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'accessing' }
BlankCellRenderer class >> modelClass [
	^ BlankCell
]
