"
This is a class that represents and creates a single difference between two Famix entities or models. 

The subclasses represent specific types of modifications (such as addition, deletion, property change, etc.). 

This class uses a target entity, which is an entity from the second model that we are comparing, on which the change occurred.

Thanks to the target, we always have an expected value (from the original model) and an actual value (from the new model).
"
Class {
	#name : 'FamixSimpleDifference',
	#superclass : 'Object',
	#instVars : [
		'entity',
		'expectedValue',
		'actualValue',
		'indexInParent'
	],
	#category : 'Famix-Simple-Diff',
	#package : 'Famix-Simple-Diff'
}

{ #category : 'accessing' }
FamixSimpleDifference >> actualValue [

	^ actualValue
]

{ #category : 'accessing' }
FamixSimpleDifference >> actualValue: anObject [

	actualValue := anObject
]

{ #category : 'accessing' }
FamixSimpleDifference >> changeTypeName [
	"the name have to be defined by the subclass"
	^ self subclassResponsibility 
]

{ #category : 'accessing' }
FamixSimpleDifference >> entity [

	^ entity
]

{ #category : 'accessing' }
FamixSimpleDifference >> entity: anObject [

	entity := anObject
]

{ #category : 'accessing' }
FamixSimpleDifference >> expectedValue [

	^ expectedValue
]

{ #category : 'accessing' }
FamixSimpleDifference >> expectedValue: anObject [

	expectedValue := anObject
]

{ #category : 'accessing' }
FamixSimpleDifference >> indexInParent [

	^ indexInParent
]

{ #category : 'accessing' }
FamixSimpleDifference >> indexInParent: anObject [

	indexInParent := anObject
]

{ #category : 'printing' }
FamixSimpleDifference >> printOn: aStream [
	"Will build a string that represent our differences"

	aStream
		nextPutAll: '['; nextPutAll: self changeTypeName; nextPutAll: '] '.

	"entity"
	aStream nextPutAll: 'On: '.
	self entity
		ifNotNil: [ aStream nextPutAll: self entity name asString ]
		ifNil: [ aStream nextPutAll: 'Unknown' ].


	"subclass responsibility"
	self printPropertyOn: aStream.
	self printValuesOn: aStream
]

{ #category : 'printing' }
FamixSimpleDifference >> printPropertyOn: aStream [

	"We don't have to print the properties in this class"
]

{ #category : 'printing' }
FamixSimpleDifference >> printValuesOn: aStream [
	" By default we give the expected value and the actual value"

	aStream nextPutAll: ' | Expected: '.
	aStream print: self expectedValue.
	aStream nextPutAll: ' | Actual: '.
	aStream print: self actualValue
]
