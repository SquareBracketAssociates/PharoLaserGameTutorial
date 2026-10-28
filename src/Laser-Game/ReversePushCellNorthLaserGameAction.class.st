Class {
	#name : 'ReversePushCellNorthLaserGameAction',
	#superclass : 'ReverseLaserGameAction',
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'accessing' }
ReversePushCellNorthLaserGameAction class >> actionSymbol [
	^#north
]

{ #category : 'accessing' }
ReversePushCellNorthLaserGameAction class >> reverseActionSymbol [
	^#pushCellSouthFromLocation:
]
