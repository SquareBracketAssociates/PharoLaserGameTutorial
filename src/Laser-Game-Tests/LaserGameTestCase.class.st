"
I am the test case that tests which have to run at more than one cell size inherit from.

Every size in this package is derived from `CellRenderer cellExtent`, and a test that writes a pixel number down instead of deriving it fails when that one number changes, although the code it checks is still right. The guard is to write each point relative to the rectangle a region answers, and then to prove the table at more than one size rather than trust it: `withCellExtent:do:` sets the cell size of the whole package for the duration of a block and puts the old size back afterwards, so one test can run the same table at thirty, forty and eighty pixels.

I hold nothing else and I am abstract. A test that never looks at a cell size has no reason to be here.
"
Class {
	#name : 'LaserGameTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'testing' }
LaserGameTestCase class >> isAbstract [
	"Answer whether I am abstract. I hold what my subclasses share and no test of my own."

	^ self = LaserGameTestCase
]

{ #category : 'support' }
LaserGameTestCase class >> withCellExtent: anExtent do: aBlock [
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
]

{ #category : 'support' }
LaserGameTestCase >> withCellExtent: anExtent do: aBlock [
	"Run aBlock with the cell size of the whole package set to anExtent, and put the old size
	back afterwards. Raising the cell size and asking the geometry whether it followed is the
	experiment this makes cheap. The click tables ask the same question, so the answer lives on
	my class side and this method passes it on."

	^ self class withCellExtent: anExtent do: aBlock
]
