"
I am the root of the click regions of a cell: the three concentric areas a click can fall in, told apart by where the click is within the cell.

My subclasses are CellClickRegionInside, CellClickRegionOutside and CellClickRegionIgnore. Each answers a `regionRectangle` in cell coordinates and a `sortIndex`. `clickRegionForPoint:` asks the subclasses in `sortIndex` order — inside first, ignore last — and answers the first one whose rectangle holds the point. Without that order the three would all claim a point near the centre, since each rectangle contains the ones inside it.

Every rectangle is derived from `CellRenderer class >> cellExtent`, `insideRegionExtent` and `ignoreRegionOffset`, so a cell of another size needs no new numbers here.

I am a class-side hierarchy: no instance is ever created. The region a point falls in decides what a click does — the inside region pushes a cell, the outside region rotates it, the ignore region does nothing.

"
Class {
	#name : 'CellClickRegion',
	#superclass : 'Object',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'interaction' }
CellClickRegion class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	"Answer whether a click at aPoint can do anything to aCell. Nothing can be done in me: the
	ignore margin is a region where a click is a click on nothing, and the inside and outside
	regions each answer for the region the point really falls in."

	^ false
]

{ #category : 'classifying' }
CellClickRegion class >> clickRegionForPoint: aPoint [
	"Answer the region of a cell aPoint falls in. My subclasses are tried innermost first, and the
	ignore region covers the whole cell, so any point within a cell finds one. A point outside the
	cell finds none, and is ignored: a click there can do nothing, which is what the ignore region
	already means. A mouse event carries such a point whenever the element under the pointer is
	larger than the cell the regions are computed from, and answering it here keeps the case out of
	every mouse handler."

	^self sortedSubclasses
		detect: [ :cls | cls regionRectangle containsPoint: aPoint ]
		ifNone: [ CellClickRegionIgnore ]
]

{ #category : 'hints' }
CellClickRegion class >> hintElementOfExtent: anExtent [
	"Answer an element drawing my hint at anExtent, or nil when I have no picture to show. The four
	push regions answer a straight arrow and the two rotate regions a curved one; the inside and
	outside regions never answer this themselves, since each refines itself first, and the ignore
	region shows nothing."

	^ nil
]

{ #category : 'hints' }
CellClickRegion class >> hintRegionForPoint: aPoint [
	"Answer the region whose hint applies at aPoint, which I already contain. I have nothing
	finer to say than my own name, so I answer myself; the inside region answers one of its four
	push regions."

	^ self
]

{ #category : 'inspecting' }
CellClickRegion class >> inspectionColorFor: aRegionClass [
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
]

{ #category : 'inspecting' }
CellClickRegion class >> inspectionMap: aBuilder [
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
]

{ #category : 'inspecting' }
CellClickRegion class >> inspectionMapContext: aContext [
	"Show the Map table on the root of the hierarchy only, for the reason the picture is shown
	there only: a region can answer for its own points, not for every region's."

	aContext active: self superclass = Object
]

{ #category : 'inspecting' }
CellClickRegion class >> inspectionRegionAt: aPoint [
	"Answer the region a click at aPoint really lands in. The point is claimed by one of my three
	subclasses and then refined, since the inside region answers one of its four push regions and
	the outside region one of its two rotate regions."

	^ (self clickRegionForPoint: aPoint) hintRegionForPoint: aPoint
]

{ #category : 'inspecting' }
CellClickRegion class >> inspectionRegionCounts [
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
]

{ #category : 'inspecting' }
CellClickRegion class >> inspectionRegions: aBuilder [
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
]

{ #category : 'inspecting' }
CellClickRegion class >> inspectionRegionsContext: aContext [
	"Show the Regions picture on the root of the hierarchy only. It is the one class that can ask
	every region in turn, since clickRegionForPoint: tries the subclasses of whichever class is
	asked, and a region asked for a picture of itself would paint a cell it does not own."

	aContext active: self superclass = Object
]

{ #category : 'inspecting' }
CellClickRegion class >> inspectionSamplePoints [
	"Answer every point of a cell the Regions picture and the Map table are built from, one per
	inspectionSampleStep in each direction, read in the order a picture is painted."

	| extent points |
	extent := CellRenderer cellExtent.
	points := OrderedCollection new.
	0 to: extent y - 1 by: self inspectionSampleStep do: [ :y |
		0 to: extent x - 1 by: self inspectionSampleStep do: [ :x |
			points add: x @ y ] ].
	^ points
]

{ #category : 'inspecting' }
CellClickRegion class >> inspectionSampleStep [
	"Answer the distance, in cell pixels, between two points the Regions picture and the Map table
	are built from. Two is fine enough to put every boundary of a fifty pixel cell on the screen,
	and it leaves a picture of six hundred and twenty five squares."

	^ 2
]

{ #category : 'interaction' }
CellClickRegion class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	^aCell
]

{ #category : 'accessing' }
CellClickRegion class >> regionRectangle [
	"Answer the rectangle, in cell coordinates, that I claim. Every concrete region answers one."

	^ self subclassResponsibility
]

{ #category : 'accessing' }
CellClickRegion class >> sortIndex [
	"Answer where I come in the order regions are asked in. The innermost region answers the
	smallest number, so that it claims a point the wider regions also contain."

	^ self subclassResponsibility
]

{ #category : 'classifying' }
CellClickRegion class >> sortedSubclasses [
	^self subclasses asSortedCollection: [:a :b | a sortIndex < b sortIndex]
]
