"
I name the move that takes another move back. One subclass of mine stands for each move the grid records: it answers the symbol that move is stacked under, and the selector that undoes it. Nothing registers and nothing lists my subclasses, so a new kind of move is a new subclass of mine and no change anywhere else.
"
Class {
	#name : 'ReverseLaserGameAction',
	#superclass : 'Object',
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'accessing' }
ReverseLaserGameAction class >> reverseActionClassFor: aSymbol [
	"Answer the subclass of mine that undoes the move aSymbol stands for. Each of them claims one
	symbol, so a new kind of move means a new subclass and no change here."

	^self subclasses detect: [:cls | cls actionSymbol = aSymbol]
]

{ #category : 'accessing' }
ReverseLaserGameAction class >> reverseActionSymbolFor: aSymbol [
	"Answer the selector that undoes the move aSymbol stands for. The grid performs it with the
	location the move was recorded at."

	| cls |
	cls := self reverseActionClassFor: aSymbol.
	^cls reverseActionSymbol
]
