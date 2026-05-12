"
This class represents a specific type of difference where a relation to another entity has been modified.

The expected value is the target entity or collection from the original model.
The actual value is the new target entity or collection from the modified model.
"
Class {
	#name : 'FamixSimpleDifferenceRelationChanged',
	#superclass : 'FamixSimpleDifference',
	#category : 'Famix-Simple-Diff',
	#package : 'Famix-Simple-Diff'
}

{ #category : 'accessing' }
FamixSimpleDifferenceRelationChanged >> changeTypeName [
	^ 'Relation Changed'
]
