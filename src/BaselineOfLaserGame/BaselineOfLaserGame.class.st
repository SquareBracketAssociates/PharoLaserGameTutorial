Class {
	#name : 'BaselineOfLaserGame',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfLaserGame',
	#package : 'BaselineOfLaserGame'
}

{ #category : 'baselines' }
BaselineOfLaserGame >> baseline: spec [
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
]
