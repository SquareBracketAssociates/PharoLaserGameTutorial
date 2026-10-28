"
I test the palette. LaserGameColors answers one colour per name and nothing else, so what is worth testing is the inspector tab that shows the palette: every name I answer has a swatch of its own colour, which is what makes the tab readable and what tells a reader a new colour was added.
"
Class {
	#name : 'LaserGameColorsTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'tests - inspecting' }
LaserGameColorsTestCase >> testThePaletteTabShowsASwatchOfEveryColourIName [
	"The Palette tab is the whole class on one page: a swatch beside its name, in the order the
	names sort. Every colour I answer has to appear, so a colour added tomorrow appears without
	anyone touching the tab."

	| selectors palette swatches builder presenter |
	selectors := LaserGameColors inspectionColorSelectors.
	self assert: (selectors includes: #mirrorColor).
	self deny: (selectors includes: #windowColorRampDirection).
	palette := LaserGameColors inspectionPaletteElement.
	swatches := palette children select: [ :each |
		            each background paint isNotNil ].
	self assert: swatches size equals: selectors size.
	selectors doWithIndex: [ :selector :index |
			self
				assert: (swatches at: index) background paint color
				equals: (LaserGameColors perform: selector) ].
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	presenter := LaserGameColors inspectionPalette: builder.
	self assert: presenter class equals: SpMorphPresenter
]
