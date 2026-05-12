"
This class represents a specific type of difference where a property of an entity has been modified.

The expected value is the property value from the original model.
The actual value is the new property value from the modified model.
"
Class {
	#name : 'FamixSimpleDifferencePropertyChanged',
	#superclass : 'FamixSimpleDifference',
	#category : 'Famix-Simple-Diff',
	#package : 'Famix-Simple-Diff'
}

{ #category : 'accessing' }
FamixSimpleDifferencePropertyChanged >> changeTypeName [
	^ 'Property Changed'
]
