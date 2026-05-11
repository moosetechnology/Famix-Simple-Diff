Class {
	#name : 'FamixSimpleDifferenceTest',
	#superclass : 'TestCase',
	#category : 'Famix-Simple-Diff',
	#package : 'Famix-Simple-Diff'
}

{ #category : 'tests' }
FamixSimpleDifferenceTest >> testChangeTypeNameEntityAddition [
	| entityAddition |
	entityAddition := FamixSimpleDifference createEntityAdded: 'Entity' actualValue: 'Actual'.
	
	self assert: entityAddition changeTypeName equals: 'Entity Addition'.
]

{ #category : 'tests' }
FamixSimpleDifferenceTest >> testChangeTypeNameEntityChanged [
	| entityChanged |
	entityChanged := FamixSimpleDifference createEntityChanged: 'Entity' expectedValue: 'Expected'  actualValue: 'Actual'.
	
	self assert: entityChanged changeTypeName equals: 'Entity Changed'.
]

{ #category : 'tests' }
FamixSimpleDifferenceTest >> testChangeTypeNameEntityDeletion [
	| entityDeletion |
	entityDeletion := FamixSimpleDifference createEntityDeletion: 'Entity' expectedValue: 'Expected'.
	
	self assert: entityDeletion changeTypeName equals: 'Entity Deletion'.
]

{ #category : 'tests' }
FamixSimpleDifferenceTest >> testChangeTypeNamePropertyChanged [
	| propertyChanged |
	propertyChanged := FamixSimpleDifference createPropertyChanged: 'Entity' expectedValue: 'Expected' actualValue: 'Actual'.
	
	self assert: propertyChanged changeTypeName equals: 'Property Changed'.
]

{ #category : 'tests' }
FamixSimpleDifferenceTest >> testChangeTypeNameRelationChanged [
	| relationChanged |
	relationChanged := FamixSimpleDifference createRelationChanged: 'Entity' expectedValue: 'Expected' actualValue: 'Actual'.
	
	self assert: relationChanged changeTypeName equals: 'Relation Changed'.
]

{ #category : 'tests' }
FamixSimpleDifferenceTest >> testInstanceCreation [
	| difference expectedValue actualValue |
	
	"testing a code modification"
	expectedValue := 'private int money;'.
	actualValue := 'private int age;'.
	
	difference := FamixSimpleDifference 
						createEntityChanged: 'testEntity' 
						expectedValue: expectedValue 
						actualValue: actualValue.
						
	"checking instance creation"
	self assert: difference entity equals: 'testEntity'.
	self assert: difference class equals: FamixSimpleDifferenceEntityChanged.
	self assert: difference expectedValue equals: expectedValue.
	self assert: difference actualValue equals: actualValue.
]

{ #category : 'accessing' }
FamixSimpleDifferenceTest >> testNullValues [
	| nullPattern |
	nullPattern := FamixSimpleDifferenceNullValue new.
	
	self assert: nullPattern name equals: 'Nothing'. 
	self assert: nullPattern mooseName equals: 'Nothing'.
	self assert: nullPattern printString equals: 'Nothing'. 
]

{ #category : 'accessing' }
FamixSimpleDifferenceTest >> testPrintOn [
	| additionDiff output expectedString |
	
	additionDiff := FamixSimpleDifference createEntityAdded: 'Entity' actualValue: 'Actual'.
	output := additionDiff printString.
	expectedString := 'a FamixSimpleDifferenceEntityAddition(''Entity Addition'' -> Expected: Nothing | Actual: ''Actual'' | On: ''Entity'')'.
	
	"strings should be equals"
	self assert: output equals: expectedString.
]
