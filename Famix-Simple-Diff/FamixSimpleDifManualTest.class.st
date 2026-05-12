"
This test class contains all the test cases where we manually build models and entities. 
This approach allows us to isolate and test specific cases that are too complicated to test in a large, automatically generated model.
"
Class {
	#name : 'FamixSimpleDifManualTest',
	#superclass : 'TestCase',
	#category : 'Famix-Simple-Diff',
	#package : 'Famix-Simple-Diff'
}

{ #category : 'running' }
FamixSimpleDifManualTest >> setUp [
	super setUp.

	"fix here to limit window's performances problems"
	self timeLimit: 30 seconds.
	"Put here a common initialization logic for tests" 
]

{ #category : 'tests' }
FamixSimpleDifManualTest >> testClearRemainingAdditionWhenMultipleMethodHaveToBeCleaned [
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
FamixSimpleDifManualTest >> testClearRemainingSuppressionWhenMultipleMethodHaveToBeCleaned [
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
FamixSimpleDifManualTest >> testCompareEntityToReturnsFalseAndRecordsDiffWhenDifferentClasses [
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
FamixSimpleDifManualTest >> testCompareEntityToReturnsFalseAndRecordsDiffWhenDifferentType [
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
FamixSimpleDifManualTest >> testCompareEntityToReturnsFalseWhenAMethodIsAddedBeforeExisting [
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
FamixSimpleDifManualTest >> testCompareEntityToReturnsFalseWhenSameClassesAndAMethodIsAdded [
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
FamixSimpleDifManualTest >> testCompareEntityToReturnsFalseWhenSameClassesAndAMethodIsDeleted [
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
FamixSimpleDifManualTest >> testCompareEntityToReturnsTrueAndEmptyDiffListWhenSameClasses [
	| sd class1 class2 |
	sd := FamixSimpleDiff new.
	
	"same classes"
	class1 := FamixJavaClass new name: 'MyClass'.
	class2 := FamixJavaClass new name: 'MyClass'.
	
	self assert: (sd compareEntity: class1 to: class2).
	self assert: sd differences isEmpty.
]

{ #category : 'tests' }
FamixSimpleDifManualTest >> testCompareEntityToReturnsTrueWhenSameClassesAndSameMethods [
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
FamixSimpleDifManualTest >> testSortedChildrenFiltersStubsAndInitializers [
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
FamixSimpleDifManualTest >> testSortedChildrenSortsAlphabeticallyWhenNotSameName [
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
FamixSimpleDifManualTest >> testSortedChildrenSortsAlphabeticallyWhenNotSameNameNotSameAnchors [
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
FamixSimpleDifManualTest >> testSortedChildrenUseSourceAnchorWhenFirstAnchorIsMissing [
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
FamixSimpleDifManualTest >> testSortedChildrenUseSourceAnchorWhenSameName [
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
FamixSimpleDifManualTest >> testSortedChildrenUseSourceAnchorWhenSecondAnchorIsMissing [
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
