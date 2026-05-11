Class {
	#name : 'FamixSimpleDiffTest',
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
FamixSimpleDiffTest >> setUp [
	super setUp.

	"fix here to limit window's performances problems"
	self timeLimit: 15 seconds.
	"Put here a common initialization logic for tests"
	mainModel1 := TestJavaModelBuilder loadMainModel.
	mainModel2 := TestJavaModelBuilder loadMainModel.
	libraryModel := TestJavaModelBuilder loadLibraryModel 
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testClassesWithDifferentNamesAreNotEqual [

	| sd entity1 entity2 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	entity2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass'.
	entity2 name: 'NewName'. 
	
	self assert: (sd compareEntity: entity1 to: entity2) equals: false 
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testClassesWithDifferentSuperclassesAreNotEqual [

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
FamixSimpleDiffTest >> testClearRemainingAdditionWhenMultipleMethodHaveToBeCleaned [
	| sd class1 class2 model1 model2 diff methodA1 methodA2 methodB methodC |
	sd := FamixSimpleDiff new.

	"we need to create a model to contain our entities"
	model1 := FamixJavaModel new.
	model2 := FamixJavaModel new.	
	
	"same classes"
	class1 := FamixJavaClass new name: 'MyClass'.
	class2 := FamixJavaClass new name: 'MyClass'.
	
	"same methods"
	methodA1 := FamixJavaMethod new name: 'methodA'.
	methodA1 signature: 'methodA()'.
	methodA2 := FamixJavaMethod new name: 'methodA'.
	methodA2 signature: 'methodA()'.
	methodB := FamixJavaMethod new name: 'methodB'.
	methodB signature: 'methodB()'.
	methodC := FamixJavaMethod new name: 'methodC'.
	methodC signature: 'methodC()'.
		
	class1 methods: { methodA1 }.
	class2 methods: { methodA2 . methodB . methodC }.
	
	model1 add: class1.
	model2 add: class2.
	
	self deny: (sd compareEntity: class1 to: class2).
	self assert: sd differences size equals: 2.
		
	diff := sd differences.
	
	self assert: diff first class equals: FamixSimpleDifferenceEntityAddition.
	self assert: diff first expectedValue class equals: FamixSimpleDifferenceNullValue.
	self assert: diff first actualValue name equals: 'methodB'.
	
	self assert: diff second class equals: FamixSimpleDifferenceEntityAddition.
	self assert: diff first expectedValue class equals: FamixSimpleDifferenceNullValue.
	self assert: diff second actualValue name equals: 'methodC'.
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testClearRemainingSuppressionWhenMultipleMethodHaveToBeCleaned [
	| sd class1 class2 model1 model2 diff methodA1 methodA2 methodB methodC |
	sd := FamixSimpleDiff new.

	"we need to create a model to contain our entities"
	model1 := FamixJavaModel new.
	model2 := FamixJavaModel new.	
	
	"same classes"
	class1 := FamixJavaClass new name: 'MyClass'.
	class2 := FamixJavaClass new name: 'MyClass'.
	
	"same methods"
	methodA1 := FamixJavaMethod new name: 'methodA'.
	methodA1 signature: 'methodA()'.
	methodA2 := FamixJavaMethod new name: 'methodA'.
	methodA2 signature: 'methodA()'.
	methodB := FamixJavaMethod new name: 'methodB'.
	methodB signature: 'methodB()'.
	methodC := FamixJavaMethod new name: 'methodC'.
	methodC signature: 'methodC()'.
		
	class1 methods: { methodA2 . methodB . methodC }.
	class2 methods: { methodA1 }.
	
	model1 add: class1.
	model2 add: class2.
	
	self deny: (sd compareEntity: class1 to: class2).
	self assert: sd differences size equals: 2.
		
	diff := sd differences.
	
	self assert: diff first class equals: FamixSimpleDifferenceEntityDeletion.
	self assert: diff first expectedValue name equals: 'methodB'.
	self assert: diff first actualValue class equals: FamixSimpleDifferenceNullValue.
	
	self assert: diff second class equals: FamixSimpleDifferenceEntityDeletion.
	self assert: diff second expectedValue name equals: 'methodC'.
	self assert: diff second actualValue class equals: FamixSimpleDifferenceNullValue.
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testCompareEntityToReturnsFalseAndRecordsDiffWhenDifferentClasses [
    | sd class1 class2 diff |
    sd := FamixSimpleDiff new.
    
    "different classes"
    class1 := FamixJavaClass new name: 'MyClass'.
    class2 := FamixJavaClass new name: 'MyOtherClass'.
    
    "checking the list of diff"
    self deny: (sd compareEntity: class1 to: class2).
    self deny: sd differences isEmpty.
    self assert: sd differences size equals: 1.
    
    diff := sd differences first.
    
    self assert: diff class equals: FamixSimpleDifferencePropertyChanged. 
    self assert: diff expectedValue equals: 'MyClass'.
    self assert: diff actualValue equals: 'MyOtherClass'.
    
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testCompareEntityToReturnsFalseAndRecordsDiffWhenDifferentType [
	| sd class method diff |
	sd := FamixSimpleDiff new.
	
	"different classes"
	class := FamixJavaClass new name: 'MyClass'.
	method := FamixJavaMethod new name: 'MyMethod'.
	
	"checking the list of diff"
	self deny: (sd compareEntity: class to: method).
	self deny: sd differences isEmpty.
	self assert: sd differences size equals: 1.
	
	diff := sd differences first.
	
	self assert: diff class equals: FamixSimpleDifferenceEntityChanged.
	self assert: diff expectedValue equals: 'FamixJavaClass'.
	self assert: diff actualValue equals: 'FamixJavaMethod'.
	
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testCompareEntityToReturnsFalseWhenAMethodIsAddedBeforeExisting [
	| sd class1 class2 methodA methodB1 methodB2 model1 model2 diff |
	sd := FamixSimpleDiff new.

	model1 := FamixJavaModel new.
	model2 := FamixJavaModel new.	
	
	class1 := FamixJavaClass new name: 'MyClass'.
	class2 := FamixJavaClass new name: 'MyClass'.
	
	methodA := FamixJavaMethod new name: 'methodA'.
	methodA signature: 'methodA()'.
	methodB1 := FamixJavaMethod new name: 'methodB'.
	methodB1 signature: 'methodB()'.
	methodB2 := FamixJavaMethod new name: 'methodB'.
	methodB2 signature: 'methodB()'.
	
	class1 methods: { methodB1 }.
	class2 methods: { methodA . methodB2 }.
	
	model1 add: class1.
	model2 add: class2.
	
	self deny: (sd compareEntity: class1 to: class2).
	self assert: sd differences size equals: 1.
		
	diff := sd differences.
	
	self assert: diff first class equals: FamixSimpleDifferenceEntityAddition.
	self assert: diff first expectedValue class equals: FamixSimpleDifferenceNullValue.
	self assert: diff first actualValue equals: methodA.
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testCompareEntityToReturnsFalseWhenSameClassesAndAMethodIsAdded [
	| sd class1 class2 method1 method2 method3 model1 model2 diff |
	sd := FamixSimpleDiff new.

	"we need to create a model to contain our entities"
	model1 := FamixJavaModel new.
	model2 := FamixJavaModel new.	
	
	"same classes"
	class1 := FamixJavaClass new name: 'MyClass'.
	class2 := FamixJavaClass new name: 'MyClass'.
	
	"same methods"
	method1 := FamixJavaMethod new name: 'myMethod'.
	method1 signature: 'myMethod()'.
	method2 := FamixJavaMethod new name: 'myMethod'.
	method2 signature: 'myMethod()'.
	method3 := FamixJavaMethod new name: 'newMethod'.
	method3 signature: 'newMethod()'.
		
	class1 methods: { method1 }.
	class2 methods: { method2 . method3 }.
	
	model1 add: class1.
	model2 add: class2.
	
	self deny: (sd compareEntity: class1 to: class2).
	self assert: sd differences size equals: 1.
		
	diff := sd differences first.
	
	self assert: diff class equals: FamixSimpleDifferenceEntityAddition.
	self assert: diff expectedValue class equals: FamixSimpleDifferenceNullValue.
	self assert: diff actualValue name equals: 'newMethod'.
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testCompareEntityToReturnsFalseWhenSameClassesAndAMethodIsDeleted [
	| sd class1 class2 method1 method2 method3 model1 model2 diff |
	sd := FamixSimpleDiff new.

	"we need to create a model to contain our entities"
	model1 := FamixJavaModel new.
	model2 := FamixJavaModel new.	
	
	"same classes"
	class1 := FamixJavaClass new name: 'MyClass'.
	class2 := FamixJavaClass new name: 'MyClass'.
	
	"methods"
	method1 := FamixJavaMethod new name: 'myMethod'.
	method1 signature: 'myMethod()'.
	method2 := FamixJavaMethod new name: 'myMethod'.
	method2 signature: 'myMethod()'.
	method3 := FamixJavaMethod new name: 'deletedMethod'.
	method3 signature: 'deletedMethod()'.
	class1 methods: { method3 . method1 }.
	class2 methods: { method2 }.
	
	model1 add: class1.
	model2 add: class2.
	"self halt."
	self deny: (sd compareEntity: class1 to: class2).
	self assert: sd differences size equals: 1.
		
	diff := sd differences first.
	
	self assert: diff class equals: FamixSimpleDifferenceEntityDeletion.
	self assert: diff expectedValue name equals: 'deletedMethod'.
	self assert: diff actualValue class equals: FamixSimpleDifferenceNullValue.
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testCompareEntityToReturnsTrueAndEmptyDiffListWhenSameClasses [
	| sd class1 class2 |
	sd := FamixSimpleDiff new.
	
	"same classes"
	class1 := FamixJavaClass new name: 'MyClass'.
	class2 := FamixJavaClass new name: 'MyClass'.
	
	self assert: (sd compareEntity: class1 to: class2).
	self assert: sd differences isEmpty.
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testCompareEntityToReturnsTrueWhenSameClassesAndSameMethods [
	| sd class1 class2 method1 method2 model1 model2 |
	sd := FamixSimpleDiff new.
	
	"we need to create a model to contain our entities"
	model1 := FamixJavaModel new.
	model2 := FamixJavaModel new.
	
	"same classes"
	class1 := FamixJavaClass new name: 'MyClass'.
	class2 := FamixJavaClass new name: 'MyClass'.
	
	"same methods"
	method1 := FamixJavaMethod new name: 'myMethod'.
	method2 := FamixJavaMethod new name: 'myMethod'.
		
	class1 methods: { method1 }.
	class2 methods: { method2 }.
	
	model1 add: class1.
	model2 add: class2.
	
	self assert: (sd compareEntity: class1 to: class2).
	self assert: sd differences isEmpty.
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testCorrespondingClassesAreEqual [

	| sd entity1 entity2 path |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	path := sd pathOfEntity: entity1.
	entity2 := sd entityAtPath: path inModel: mainModel2.
	
	self assert: (sd compareEntity: entity1 to: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testCorrespondingClassesInSameModelIsSameEntity [

	| sd entity1 entity2 path |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	path := sd pathOfEntity: entity1.
	entity2 := sd entityAtPath: path inModel: mainModel1.
	
	self assert: entity1 == entity2
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testCorrespondingMethodsAreEqual [

	| sd entity1 entity2 path |
	sd := FamixSimpleDiff new.
	
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	path := sd pathOfEntity: entity1.
	entity2 := sd entityAtPath: path inModel: mainModel2.
	
	self assert: (sd compareEntity: entity1 to: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testCorrespondingMethodsInSameModelIsSameEntity [

	| sd entity1 entity2 path |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	path := sd pathOfEntity: entity1.
	entity2 := sd entityAtPath: path inModel: mainModel1.
	
	self assert: entity1 == entity2
]

{ #category : 'as yet unclassified' }
FamixSimpleDiffTest >> testCorrespondingPrimitiveTypesAreEqual [

	| sd entity1 entity2 path |
	sd := FamixSimpleDiff new.

	entity1 := (mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()') declaredType.
	path := sd pathOfEntity: entity1.
	entity2 := sd entityAtPath: path inModel: mainModel2.
	
	self assert: (sd compareEntity: entity1 to: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testDebugIsOn [
	| sd |
	sd := FamixSimpleDiff new.
	sd debugOn.
	
	"debug mode should be activated"
	self assert: (sd instVarNamed: 'debug').
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testDifferenceDetectedWhenToOneRelationChanged [

^ true
"TODO: This test have to be fixed"

"""
    | sd class1 class2 model1 model2 diff method1 method2 |
    sd := FamixSimpleDiff new.

    model1 := FamixJavaModel new.
    model2 := FamixJavaModel new.

    class1 := FamixJavaClass new name: 'ClassA'.
    class2 := FamixJavaClass new name: 'ClassB'.

    method1 := FamixJavaMethod new name: 'myMethod'.
    method1 signature: 'myMethod()'.
    method2 := FamixJavaMethod new name: 'myMethod'.
    method2 signature: 'myMethod()'.

    method1 parentType: class1.
    method2 parentType: class2.

    model1 add: class1.
    model2 add: class2.

    self deny: (sd compareEntity: method1 to: method2).
    self assert: sd differences size equals: 1.

    diff := sd differences.

    self assert: diff first class equals: FamixSimpleDifferenceRelationChanged.
    self assert: diff first expectedValue equals: class1.
    self assert: diff first actualValue equals: class2

"""
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testEntityWithDifferentRelationsSizesAreNotEquals [

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
FamixSimpleDiffTest >> testEqualClassesAreEqual [

	| sd entity1 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	
	self assert: (sd compareEntity: entity1 to: entity1)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testEqualMethodsAreEqual [

	| sd entity1 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	
	self assert: (sd compareEntity: entity1 to: entity1)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testEqualModelsAreEqual [

	| sd |
	sd := FamixSimpleDiff new.
	
	self assert: (sd compareModel: mainModel1 to: mainModel2)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testMethodsWithDifferentNamesAreNotEqual [

	| sd entity1 entity2 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	entity2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	entity2 name: 'NewName'. 
	
	self assert: (sd compareEntity: entity1 to: entity2) equals: false
]

{ #category : 'as yet unclassified' }
FamixSimpleDiffTest >> testNotEqualModelsAreNotEqual [

	| sd |
	sd := FamixSimpleDiff new.
	self deny: (sd compareModel: mainModel1 to: libraryModel)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testRecursiveCompareEntityReturnFalseOnDeepDifferentModels [

	| sd childMethod2 |
	sd := FamixSimpleDiff new.
	
	"modify a child"
	childMethod2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	childMethod2 name: 'getIntAttributeWithDifferentName'.
	
	"the models should not be equals"
	self deny: (sd compareModel: mainModel1 to: mainModel2)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testSameClassesAreEqual [

	| sd entity1 entity2 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	entity2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass'.
	
	self assert: (sd compareEntity: entity1 to: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testSameMethodsAreEqual [

	| sd entity1 entity2 |
	sd := FamixSimpleDiff new.
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	entity2 := mainModel2 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	
	self assert: (sd compareEntity: entity1 to: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testSameModelsAreEqual [

	| sd |
	sd := FamixSimpleDiff new.
	
	self assert: (sd compareModel: mainModel1 to: mainModel1)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testSortBlockOrdersByName [

	| sd block entity1 entity2 |
	sd := FamixSimpleDiff new.
	
	block := sd sortBlock.
	
	entity1 := mainModel1 entityNamed: 'some.thing.whatever.MainClass'.
	entity2 := mainModel1 entityNamed: 'some.thing.whatever.MainClass.getIntAttribute()'.
	
	self assert: (block value: entity2 value: entity1).
	self deny: (block value: entity1 value: entity2)
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testSortedChildrenFiltersStubsAndInitializers [
	| sd parent normalMethod stubMethod initializeMethod res |
	sd := FamixSimpleDiff new.
	
	"init parent and stubs methods"
	parent := FamixJavaClass new name: 'ParentClass'.
	normalMethod := FamixJavaMethod new name: 'normalMethod'; 
	isStub: false.
	stubMethod  := FamixJavaMethod new name: 'stubMethod'; 
	isStub: true.
	initializeMethod := FamixJavaMethod new name: '<Initializer>';
	isStub: false.
	
	"testing the sort"
	parent methods: { normalMethod . stubMethod . initializeMethod }.
	res := sd sortedChildren: parent.
	
	"the filter keep just 1 method"
	self assert: res size equals: 1.
	self assert: res first equals: normalMethod .
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testSortedChildrenSortsAlphabeticallyWhenNotSameName [
	| sd parent aBeginMethod bBeginMethod res |
	sd := FamixSimpleDiff new.
	
	"init parent and child methods"
	parent := FamixJavaClass new name: 'ParentClass'.
	aBeginMethod := FamixJavaMethod new name: 'aBeginMethod'.
	bBeginMethod := FamixJavaMethod new name: 'bBeginMethod'.
	
	"testing the sort"
	parent methods: { bBeginMethod . aBeginMethod}.
	res := sd sortedChildren: parent. 
	self assert: res first equals: aBeginMethod.
	self assert: res second equals: bBeginMethod.
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testSortedChildrenSortsAlphabeticallyWhenNotSameNameNotSameAnchors [
	| sd parent aBeginMethod bBeginMethod anchor1 anchor2 res |
	sd := FamixSimpleDiff new.
	
	"init parent and child methods"
	parent := FamixJavaClass new name: 'ParentClass'.
	aBeginMethod := FamixJavaMethod new name: 'aBeginMethod';
	signature: 'aBeginMethod()'.
	bBeginMethod := FamixJavaMethod new name: 'bBeginMethod';
	signature: 'bBeginMethod()'.
	
	"init file anchor, must be different for this test"
	anchor1 := FamixJavaIndexedFileAnchor new endPos: 20.
	anchor2 := FamixJavaIndexedFileAnchor new endPos: 10.
	
	"giving created anchors to the methods"
	aBeginMethod sourceAnchor: anchor1.
	bBeginMethod sourceAnchor: anchor2.
	
	"testing the sort"
	parent methods: { bBeginMethod . aBeginMethod}.
	res := sd sortedChildren: parent. 
	
	self assert: res first equals: aBeginMethod.
	self assert: res second equals: bBeginMethod.
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testSortedChildrenUseSourceAnchorWhenFirstAnchorIsMissing [
	| sd parent method1 method2 anchor2 res |
	sd := FamixSimpleDiff new.
	
	"init parent and child methods"
	parent := FamixJavaClass new name: 'ParentClass'.
	
	"init same method"
	method1 := FamixJavaMethod new name: 'SameMethod'.
	method2 := FamixJavaMethod new name: 'SameMethod'.
	
	"init anchor"
	anchor2 := FamixJavaIndexedFileAnchor new endPos: 20.
	method2 sourceAnchor: anchor2.
	
	"testing the sort"
	parent methods: { method2 . method1}.
	res := sd sortedChildren: parent. 
	
	self assert: res size equals: 2.
	self assert: res first equals: method1.
	self assert: res second equals: method2.
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testSortedChildrenUseSourceAnchorWhenSameName [
	| sd parent method1 method2 anchor1 anchor2 res |
	sd := FamixSimpleDiff new.
	
	"init parent and child methods, must be the same for this test"
	parent := FamixJavaClass new name: 'ParentClass'.
	method1 := FamixJavaMethod new name: 'SameMethod'.
	method2 := FamixJavaMethod new name: 'SameMethod'.
	
	"init file anchor, must be different for this test"
	anchor1 := FamixJavaIndexedFileAnchor new endPos: 10.
	anchor2 := FamixJavaIndexedFileAnchor new endPos: 20.
	
	"giving created anchors to the methods"
	method1 sourceAnchor: anchor1.
	method2 sourceAnchor: anchor2.
	
	"testing the sort"
	parent methods: { method2 . method1}.
	res := sd sortedChildren: parent. 
	self assert: res first equals: method1.
	self assert: res second equals: method2. 
	 
	
	
]

{ #category : 'tests' }
FamixSimpleDiffTest >> testSortedChildrenUseSourceAnchorWhenSecondAnchorIsMissing [
	| sd parent method1 method2 anchor1 res |
	sd := FamixSimpleDiff new.
	
	"init parent and child methods"
	parent := FamixJavaClass new name: 'ParentClass'.
	
	"init methods"
	method1 := FamixJavaMethod new name: 'SameMethod'.
	method2 := FamixJavaMethod new name: 'SameMethod'.
	
	anchor1 := FamixJavaIndexedFileAnchor new endPos: 10.
	method1 sourceAnchor: anchor1.
	
	"testing the sort"
	parent methods: { method2 . method1}.
	res := sd sortedChildren: parent. 
	
	self assert: res size equals: 2.
	self assert: res first equals: method1.
	self assert: res second equals: method2.
]
