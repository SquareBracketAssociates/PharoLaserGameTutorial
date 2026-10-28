"
I check the examples of the package Laser-Game-Examples.

Every example is a class-side method marked `<sampleInstance>`, which the browser offers as one click: it answers an object and opens an inspector on it.
I hold that promise to four rules.
Every method of the package is such an example.
Every example that answers an object answers one the inspector has a tab of our own for, and between them the examples reach every tab the game defines on the instance side of a class.
A tab on the class side is not asked for: inspecting the class shows it, and demanding an example for it only breeds methods whose whole body answers a class. I check instead that the inspector really shows each one there.
Only an example whose selector begins with `open` opens a window, so running the others costs nothing.
"
Class {
	#name : 'LaserGameExamplesTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'support' }
LaserGameExamplesTestCase >> classSideTabMethods [
	"Answer every inspector tab the game defines on the class side of a class, the tabs you see by inspecting the class."

	| package |
	package := (self class environment at: #PackageOrganizer) default
		           packageNamed: 'Laser-Game'.
	^ (self tabMethodsDefinedBy: package) select: [ :each |
		  each methodClass isMeta ]
]

{ #category : 'support' }
LaserGameExamplesTestCase >> exampleMethods [
	"Answer every example, sorted, so a failure always names the same one first."

	^ (self examplePackage methods select: [ :each |
		   each pragmas anySatisfy: [ :pragma | pragma selector = #sampleInstance ] ])
		  asSortedCollection: [ :one :other |
		  one methodClass name , one selector
		  <= (other methodClass name , other selector) ]
]

{ #category : 'support' }
LaserGameExamplesTestCase >> examplePackage [
	"Answer the package the examples live in."

	^ (self class environment at: #PackageOrganizer) default packageNamed: 'Laser-Game-Examples'
]

{ #category : 'support' }
LaserGameExamplesTestCase >> instanceSideTabNames [
	"Answer the name of every inspector tab the game defines on the instance side of a class.
	The class-side tabs are not here: inspecting the class itself shows them, which needs no example."

	| package |
	package := (self class environment at: #PackageOrganizer) default
		           packageNamed: 'Laser-Game'.
	^ (((self tabMethodsDefinedBy: package) reject: [ :each |
		    each methodClass isMeta ]) collect: [ :each |
		   each methodClass name , ' >> ' , each selector ]) asSet
]

{ #category : 'support' }
LaserGameExamplesTestCase >> opensAWindow: aCompiledMethod [
	"Answer whether aCompiledMethod puts a window on screen. It does if it sends openOn:, which opens a space on an element, or show, which opens a space it built itself. Read off the sends, so that asking puts up no window."

	^ aCompiledMethod messages anySatisfy: [ :each |
		  #( openOn: show ) includes: each ]
]

{ #category : 'support' }
LaserGameExamplesTestCase >> quietExampleMethods [
	"Answer the examples that answer an object without opening a window: everything but the openers."

	^ self exampleMethods reject: [ :each | each selector beginsWith: 'open' ]
]

{ #category : 'support' }
LaserGameExamplesTestCase >> runExample: aCompiledMethod [
	"Answer what the example answers. An example is a class-side method, so it is the class itself that is asked."

	^ aCompiledMethod methodClass instanceSide perform: aCompiledMethod selector
]

{ #category : 'support' }
LaserGameExamplesTestCase >> tabMethodsDefinedBy: aClassOrPackage [
	"Answer the inspector tabs of our own packages among the methods of aClassOrPackage."

	^ aClassOrPackage methods select: [ :each |
		  (each pragmas anySatisfy: [ :pragma |
			   pragma selector = #inspectorPresentationOrder:title: ]) and: [
			  each package notNil and: [
				  each package name beginsWith: 'Laser-Game' ] ] ]
]

{ #category : 'support' }
LaserGameExamplesTestCase >> tabsShownFor: anObject [
	"Answer the names of the tabs of our own that the inspector shows for anObject.
	Asking the class of anObject covers both sides: a cell answers the tabs its class and its superclasses define, and a class answers the ones defined on its metaclass."

	^ (anObject class withAllSuperclasses flatCollect: [ :each |
		   self tabMethodsDefinedBy: each ]) collect: [ :each |
		  each methodClass name , ' >> ' , each selector ]
]

{ #category : 'tests' }
LaserGameExamplesTestCase >> testEveryClassSideTabIsShownByInspectingItsClass [
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
]

{ #category : 'tests' }
LaserGameExamplesTestCase >> testEveryMethodOfThePackageIsAnExample [
	"The package holds examples and nothing else, so everything in it is one click the browser offers."

	| strays |
	strays := self examplePackage methods reject: [ :each |
		          each pragmas anySatisfy: [ :pragma |
			          pragma selector = #sampleInstance ] ].
	self assertEmpty: (strays collect: [ :each |
			 each methodClass name , ' >> ' , each selector ]) asArray.
	self denyEmpty: self exampleMethods
]

{ #category : 'tests' }
LaserGameExamplesTestCase >> testEveryQuietExampleAnswersAnObjectWithATabOfOurOwn [
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
]

{ #category : 'tests' }
LaserGameExamplesTestCase >> testOnlyAnExampleNamedOpenOpensAWindow [
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
]

{ #category : 'tests' }
LaserGameExamplesTestCase >> testTheExamplesReachEveryInstanceSideTabTheGameDefines [
	"Whatever tab the game grows on the instance side, one click of the examples opens an inspector that shows it.
	A tab on the class side is not asked for here: inspecting the class shows it, and demanding an example for it only breeds methods whose whole body answers a class."

	| reached |
	reached := Set new.
	self quietExampleMethods do: [ :each |
		reached addAll: (self tabsShownFor: (self runExample: each)) ].
	self assertEmpty:
		(self instanceSideTabNames difference: reached) asSortedCollection asArray
]
