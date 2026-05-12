"
This test class contains all the test cases that do not require building models.
"
Class {
	#name : 'FamixSimpleDiffOtherTest',
	#superclass : 'TestCase',
	#category : 'Famix-Simple-Diff',
	#package : 'Famix-Simple-Diff'
}

{ #category : 'tests' }
FamixSimpleDiffOtherTest >> testDebugIsOn [
	| sd |
	sd := FamixSimpleDiff new.
	sd debugOn.
	
	"debug mode should be activated"
	self assert: (sd instVarNamed: 'debug').
]

{ #category : 'tests' }
FamixSimpleDiffOtherTest >> testDifferenceDetectedWhenToOneRelationChanged [

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
