Class {
	#name : 'FamixSimpleDiffAutoTest',
	#superclass : 'TestCase',
	#instVars : [
		'mainModel1',
		'mainModel2',
		'libraryModel'
	],
	#category : 'Famix-Simple-Diff',
	#package : 'Famix-Simple-Diff'
}

{ #category : 'running' }
FamixSimpleDiffAutoTest >> setUp [
	super setUp.

	"fix here to limit window's performances problems"
	self timeLimit: 15 seconds.
	"Put here a common initialization logic for tests"
	mainModel1 := TestJavaModelBuilder loadMainModel.
	mainModel2 := TestJavaModelBuilder loadMainModel.
	libraryModel := TestJavaModelBuilder loadLibraryModel 
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testClassesWithDifferentNamesAreNotEqual [

	| sd entity1 entity2 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	entity2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass'.
	entity2 name: 'NewName'. 
	
	self assert: (sd compareEntity: entity1 to: entity2) equals: false 
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testClassesWithDifferentSuperclassesAreNotEqual [

	| sd entity1 entity2 newInheritance |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	entity2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass'.
	
	newInheritance := mainModel2 newInheritance
		superclass: entity2;
		subclass: entity2.
	entity2 superInheritances: { newInheritance }. 
	
	self assert: (sd compareEntity: entity1 to: entity2) equals: false
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testCorrespondingClassesAreEqual [

	| sd entity1 entity2 path |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	path := sd pathOfEntity: entity1.
	entity2 := sd entityAtPath: path inModel: mainModel2.
	
	self assert: (sd compareEntity: entity1 to: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testCorrespondingClassesInSameModelIsSameEntity [

	| sd entity1 entity2 path |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	path := sd pathOfEntity: entity1.
	entity2 := sd entityAtPath: path inModel: mainModel1.
	
	self assert: entity1 == entity2
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testCorrespondingMethodsAreEqual [

	| sd entity1 entity2 path |
	sd := FamixSimpleDiff new.
	
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	path := sd pathOfEntity: entity1.
	entity2 := sd entityAtPath: path inModel: mainModel2.
	
	self assert: (sd compareEntity: entity1 to: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testCorrespondingMethodsInSameModelIsSameEntity [

	| sd entity1 entity2 path |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	path := sd pathOfEntity: entity1.
	entity2 := sd entityAtPath: path inModel: mainModel1.
	
	self assert: entity1 == entity2
]

{ #category : 'as yet unclassified' }
FamixSimpleDiffAutoTest >> testCorrespondingPrimitiveTypesAreEqual [

	| sd entity1 entity2 path |
	sd := FamixSimpleDiff new.

	entity1 := (mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()') declaredType.
	path := sd pathOfEntity: entity1.
	entity2 := sd entityAtPath: path inModel: mainModel2.
	
	self assert: (sd compareEntity: entity1 to: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testEntityWithDifferentRelationsSizesAreNotEquals [

	| sd entity1 entity2 newMethod methodList |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	entity2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass'.
	
	"adding a new method to set a difference between the two models"
	newMethod := FamixJavaMethod new name: 'newMethod()'.
	
	"adding the method in the current method list"
	methodList := entity2 methods asOrderedCollection.
	methodList add: newMethod.
	
	"changing the method list"
	entity2 methods: methodList.
	
	self deny: (sd compareEntity: entity1 to: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testEqualClassesAreEqual [

	| sd entity1 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	
	self assert: (sd compareEntity: entity1 to: entity1)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testEqualMethodsAreEqual [

	| sd entity1 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	
	self assert: (sd compareEntity: entity1 to: entity1)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testEqualModelsAreEqual [

	| sd |
	sd := FamixSimpleDiff new.
	
	self assert: (sd compareModel: mainModel1 to: mainModel2)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testMethodsWithDifferentNamesAreNotEqual [

	| sd entity1 entity2 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	entity2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	entity2 name: 'NewName'. 
	
	self assert: (sd compareEntity: entity1 to: entity2) equals: false
]

{ #category : 'as yet unclassified' }
FamixSimpleDiffAutoTest >> testNotEqualModelsAreNotEqual [

	| sd |
	sd := FamixSimpleDiff new.
	self deny: (sd compareModel: mainModel1 to: libraryModel)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testRecursiveCompareEntityReturnFalseOnDeepDifferentModels [

	| sd childMethod2 |
	sd := FamixSimpleDiff new.
	
	"modify a child"
	childMethod2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	childMethod2 name: 'getIntAttributeWithDifferentName'.
	
	"the models should not be equals"
	self deny: (sd compareModel: mainModel1 to: mainModel2)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testSameClassesAreEqual [

	| sd entity1 entity2 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	entity2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass'.
	
	self assert: (sd compareEntity: entity1 to: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testSameMethodsAreEqual [

	| sd entity1 entity2 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	entity2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	
	self assert: (sd compareEntity: entity1 to: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testSameModelsAreEqual [

	| sd |
	sd := FamixSimpleDiff new.
	
	self assert: (sd compareModel: mainModel1 to: mainModel1)
]

{ #category : 'tests' }
FamixSimpleDiffAutoTest >> testSortBlockOrdersByName [

	| sd block entity1 entity2 |
	sd := FamixSimpleDiff new.
	
	block := sd sortBlock.
	
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	entity2 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	
	self assert: (block value: entity2 value: entity1).
	self deny: (block value: entity1 value: entity2)
]
