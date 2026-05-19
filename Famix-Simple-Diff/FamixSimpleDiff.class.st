"
This is a class that performs the comparison between two Famix models to detect differences (addition, deletion, changes).

We traverse all the entities of the model and use the Moose meta-description to compare their types, properties, and relations.

This class will create a list that gathers all the differences between the models.
"
Class {
	#name : 'FamixSimpleDiff',
	#superclass : 'Object',
	#instVars : [
		'roots',
		'childrenCache',
		'debug',
		'differences',
		'relationCounter',
		'propertiesCounter',
		'inspectedClasses'
	],
	#category : 'Famix-Simple-Diff',
	#package : 'Famix-Simple-Diff'
}

{ #category : 'accessing' }
FamixSimpleDiff >> addDifference: aFamixDiff [
	differences add: aFamixDiff
]

{ #category : 'comparing' }
FamixSimpleDiff >> compareEntity: aFamixEntity to: otherFamixEntity [

	| properties relations diff isEquals allProperties |
	isEquals := true.
	allProperties := aFamixEntity mooseDescription allProperties.

	"we compare the type of the entities. If we have not the same type, we add the difference in the list"
	aFamixEntity class = otherFamixEntity class ifFalse: [
			diff := FamixSimpleDifference
				        createEntityChanged: otherFamixEntity
				        expectedValue: aFamixEntity class name
				        actualValue: otherFamixEntity class name.
			self addDifference: diff.
			^ self fail ].

	"Comparing properties using Moose meta models" 
	"We focus on entity with a primitive type (Boolean, Number, String). We exclude derived properties to not pollute difference list" 
	properties := allProperties select: [ :property |
			              property type isPrimitive and: [
				              property isDerived not and: [
					              (property name beginsWith: 'numberOf') not ] ] ].

	"we read property values, and create a difference if they are not equals"
	properties do: [ :p |
		| property1 property2 |
		propertiesCounter := propertiesCounter + 1.
		property1 := p getRawFrom: aFamixEntity.
		property2 := p getRawFrom: otherFamixEntity.
		property1 = property2 ifFalse: [
				diff := FamixSimpleDifference
					        createPropertyChanged: otherFamixEntity
					        expectedValue: property1
					        actualValue: property2.
				self addDifference: diff.
				isEquals := false ] ].

	"Comparing relations using Moose meta models"
	"We focus on non primitive property (objects), and we exclude source anchors and derived property because they are not relevant to model comparison"
	relations := allProperties select: [ :property |
			             property type isPrimitive not and: [
					             property name ~= 'sourceAnchor' and: [
						             self shouldCompareRelation: property ] ] ].
			
	"debug, si clé pas dans dico on ajoute"
	"key -> classe"
	"value -> property et relation"
	inspectedClasses at: aFamixEntity class name ifAbsentPut: 
	[ 
		Dictionary new
		at: 'properties' put: (properties);
		at: 'relations' put: (relations);
		yourself 
	].
		
	relations do: [ :r |
			(self compareRelation: r from: aFamixEntity to: otherFamixEntity)
				ifFalse: [ isEquals := false ] ].

	"we stop the execution here if models are differents"
	isEquals ifFalse: [ ^ self fail ].

	"Every slot value are equal, the entities are identical"
	^ true
]

{ #category : 'comparing' }
FamixSimpleDiff >> compareModel: aFamixJavaModel to: aFamixJavaModel2 [

	relationCounter := 0.
	propertiesCounter := 0.

	(self entityRoots: aFamixJavaModel) do: [ :root |
			| correspondingRoot |
			correspondingRoot := self
				                     correspondingEntityTo: root
				                     in: aFamixJavaModel2.
			(self recursiveCompareEntity: root with: correspondingRoot)
				ifFalse: [ ^ self fail ] ].

	^ true
]

{ #category : 'comparing' }
FamixSimpleDiff >> compareRelation: aRelationDescription from: aFamixEntity to: otherFamixEntity [

	| val1 val2 sortBlock |
	relationCounter := relationCounter + 1.
	aRelationDescription isMultivalued
		ifFalse: ["toOne relation"
				val1 := aRelationDescription getRawFrom: aFamixEntity.
				val2 := aRelationDescription getRawFrom: otherFamixEntity ]
		ifTrue: ["toMany relation"
				| rejectBlock |
				val1 := (aRelationDescription getRawFrom: aFamixEntity) asOrderedCollection.
				val2 := (aRelationDescription getRawFrom: otherFamixEntity) asOrderedCollection.

				sortBlock := val1
					             ifEmpty: [ self sortBlock ]
					             ifNotEmpty: [ self sortBlockFor: val1 anyOne ].

				rejectBlock := [ :e | e name = 'clone' ].

				val1 := val1 reject: rejectBlock.
				val2 := val2 reject: rejectBlock.

				val1 := val1 sorted: sortBlock.
				val2 := val2 sorted: sortBlock ].

	"Sometimes, parent relations are duplicated and are nil.
	This guards for that..."
	val1 == val2 ifTrue: [ ^ true ].

	^ aRelationDescription isMultivalued
		  ifFalse: [
			  self
				  compareToOneRelation: val1
				  actual: val2
				  target: otherFamixEntity ]
		  ifTrue: [
			  self
				  compareToManyRelation: val1
				  actual: val2
				  target: otherFamixEntity ]
]

{ #category : 'comparing' }
FamixSimpleDiff >> compareToManyRelation: val1 actual: val2 target: anEntity [
	"We use two pointer to browse the differences of the model using Moose name. val1 and val2 must be sorted collections.
	- If the name are identical, we advance both pointers.
	- If name1 < name2, so its a deletion (pointer1 go forward).
	- If name1 > name2, so its an addition (pointer2 go forward).
	If one stream is empty, we finish the remaining additions/ deletions.
	Return true if models are equals, false otherwise.
	"

	| stream1 stream2 isEquals diff |
	isEquals := true.

	stream1 := val1 readStream.
	stream2 := val2 readStream.

	"looking the streams"
	[ stream1 atEnd or: [ stream2 atEnd ] ] whileFalse: [
			| element1 element2 name1 name2 |
			
			"setup name"
			element1 := stream1 peek.
			element2 := stream2 peek.

			name1 := element1 mooseName.
			name2 := element2 mooseName.

			name1 = name2
				ifTrue: ["move forward both ptr if identicals"
						stream1 next.
						stream2 next ]
				ifFalse: [
						name1 < name2
							ifTrue: ["deletion case"
									diff := FamixSimpleDifference
										        createEntityDeletion: anEntity
										        expectedValue: element1.
									self addDifference: diff.
									isEquals := false.
									stream1 next "ptr1++" ]
								
							ifFalse: ["addition case"
									diff := FamixSimpleDifference
										        createEntityAdded: anEntity
										        actualValue: element2.
									self addDifference: diff.
									isEquals := false.
									stream2 next "ptr2++" ] ] ].

	"cleaning end of pointers, checking if they have clean something"
	"if they have deleted/added something, so the models are not equals"
	(self finishRemainingDeletionOf: stream1 target: anEntity) ifTrue: [isEquals := false ].
	(self finishRemainingAdditionOf: stream2 target: anEntity) ifTrue: [isEquals := false ].

	^ isEquals
]

{ #category : 'comparing' }
FamixSimpleDiff >> compareToOneRelation: val1 actual: val2 target: anEntity [

	| areEquals diff |
	"if we dont have the same relations, so it changed, we have to record it"
	areEquals := (self pathesForMaybeMultiRelation: val1) = (self pathesForMaybeMultiRelation: val2).
	areEquals ifFalse: [
			diff := FamixSimpleDifference
				        createRelationChanged: anEntity
				        expectedValue: val1
				        actualValue: val2.
			self addDifference: diff ].

	^ areEquals
]

{ #category : 'path-computing' }
FamixSimpleDiff >> computePathOfEntity: anEntity [
	"We only work for single parent entities... And we hope this is the case always.
	If not, talk to Guille, he has a point.
	Read about lexical definition"

	self assert: anEntity containers asSet size <= 1.
	
	"If we have a container, we continue recursively"
	anEntity containers asSet do: [ :c |
			^ (self pathOfEntity: c) copyWith:
				  ((self sortedChildren: c) indexOf: anEntity) ].

	"We don't have a container, this is the root. Return the index of this entity in the root collection"
	^ { ((self entityRoots: anEntity mooseModel) indexOf: anEntity) }
]

{ #category : 'accessing' }
FamixSimpleDiff >> correspondingEntityTo: entity in: model [

	| path |
	path := self pathOfEntity: entity.
	^ self entityAtPath: path inModel: model
]

{ #category : 'debug' }
FamixSimpleDiff >> debugOn [

	debug := true
]

{ #category : 'accessing' }
FamixSimpleDiff >> differences [

	^ differences
]

{ #category : 'path-computing' }
FamixSimpleDiff >> entityAtPath: indexPath fromEntity: entity [

	indexPath ifEmpty: [ ^ entity ].

	^ self
		  entityAtPath: indexPath allButFirst
		  fromEntity: ((self sortedChildren: entity) at: indexPath first)
]

{ #category : 'path-computing' }
FamixSimpleDiff >> entityAtPath: indexPath inModel: model [

	| rootEntity |
	rootEntity := (self entityRoots: model) at: indexPath first.
	^ self entityAtPath: indexPath allButFirst fromEntity: rootEntity
]

{ #category : 'accessing' }
FamixSimpleDiff >> entityRoots: aFamixJavaModel [

	| goodSortBlock excludedClasses |
	excludedClasses := {
		                   FamixJavaWildcard.
		                   FamixJavaAnnotationInstance.
		                   FamixJavaAnnotationInstanceAttribute }.

	^ (roots ifNil: [ roots := Dictionary new ])
		  at: aFamixJavaModel
		  ifAbsentPut: [
				  | rootEntities |
				  rootEntities := aFamixJavaModel rootEntities reject: [ :entity |
						                  entity name = '<Default Package>' or: [
							                  excludedClasses includes: entity class ] ].
				  goodSortBlock := self sortBlockFor: rootEntities anyOne.
				  rootEntities sorted: goodSortBlock ]
]

{ #category : 'asserting' }
FamixSimpleDiff >> fail [

	debug ifTrue: [ self halt ].
	^ false
]

{ #category : 'accessing' }
FamixSimpleDiff >> finishRemaining: aStream diffCreation: aDifferenceCreation [

	| modelsAreDifferents diff |
	modelsAreDifferents := false.

	[ aStream atEnd ] whileFalse: [
			diff := aDifferenceCreation value: aStream next.
			self addDifference: diff.
			modelsAreDifferents := true ].

	^ modelsAreDifferents
]

{ #category : 'accessing' }
FamixSimpleDiff >> finishRemainingAdditionOf: aStream target: anEntity [

	^ self finishRemaining: aStream diffCreation: [ :val |
		  FamixSimpleDifference createEntityAdded: anEntity actualValue: val ]
]

{ #category : 'accessing' }
FamixSimpleDiff >> finishRemainingDeletionOf: aStream target: anEntity [

	^ self finishRemaining: aStream diffCreation: [ :val |
			FamixSimpleDifference createEntityDeletion: anEntity expectedValue: val ]
]

{ #category : 'initialization' }
FamixSimpleDiff >> initialize [

	super initialize.
	debug := false.
	childrenCache := LRUCache new maximumWeight: 100.
	differences := OrderedCollection new.
	relationCounter := 0.
	propertiesCounter := 0.
	inspectedClasses := Dictionary new.
]

{ #category : 'path-computing' }
FamixSimpleDiff >> pathOfEntity: anEntity [

	^ anEntity
		  cacheAt: #path
		  ifAbsentPut: [ self computePathOfEntity: anEntity ]
]

{ #category : 'path-computing' }
FamixSimpleDiff >> pathesForMaybeMultiRelation: multiRelationTargetOrCollectionOrSmellingThing [

	| target targettedEntities |
	target := multiRelationTargetOrCollectionOrSmellingThing isAssociation
		          ifTrue: [ multiRelationTargetOrCollectionOrSmellingThing target ]
		          ifFalse: [ multiRelationTargetOrCollectionOrSmellingThing ].

	targettedEntities := target isCollection
		                     ifTrue: [ target ]
		                     ifFalse: [ { target } ].

	^ targettedEntities collect: [ :e |
		"Please e be an entity please please plz"
		  self pathOfEntity: e ]
]

{ #category : 'comparing' }
FamixSimpleDiff >> recursiveCompareEntity: entity1 with: entity2 [

	"Parametric entities and inner classes are not used in the comparison process, so we return true by default"
	entity1 mooseName = entity2 mooseName ifTrue: [
			(entity1 isParametricEntity and: [ entity2 isParametricEntity ])
				ifTrue: [ ^ true ].
			(entity1 isType and: [ entity1 isAnonymousClass ]) ifTrue: [
				^ true ] ].

	"Clone methods have an issue (potentially due to JDT) which isn't easy to fix, so we skip those."
	entity1 name = 'clone' ifTrue: [ ^ true ].

	(self compareEntity: entity1 to: entity2) ifFalse: [ ^ false ].

	(self sortedChildren: entity1)
		with: (self sortedChildren: entity2)
		do: [ :child1 :child2 |
			(self recursiveCompareEntity: child1 with: child2) ifFalse: [
				^ false ] ].

	^ true
]

{ #category : 'comparing' }
FamixSimpleDiff >> shouldCompareRelation: aFM3Property [
	"We use this filter to avoid comparing the same relation. Here is the idea:
	. A relation without opposite is important, so we keep it.
	. If we have a multivalued relation on a side, and a non multivalued relation on the other side, we keep the multivalued one.
	. If both are multivalued, we check if one side is derived. In this case we keep the derived one."

	| oppositeRelation |
	aFM3Property hasOpposite ifFalse: [ ^ true ].

	oppositeRelation := aFM3Property opposite.

	^ aFM3Property isMultivalued ~= oppositeRelation isMultivalued
		  ifTrue: [ aFM3Property isMultivalued ]
		  ifFalse: [ aFM3Property isDerived ]
]

{ #category : 'sorting' }
FamixSimpleDiff >> sortBlock [

	^ [ :a :b | a mooseName > b mooseName ]
]

{ #category : 'sorting' }
FamixSimpleDiff >> sortBlockFor: anEntity [

	^ anEntity hasUniqueMooseNameInModel
		  ifTrue: [ [ :a :b | a mooseName < b mooseName ] ]
		  ifFalse: [
				  [ :a :b |
					  | valA valB |
					  valA := String streamContents: [ :s | a printOn: s ].
					  valB := String streamContents: [ :s | b printOn: s ].
					  valA < valB ] ]
]

{ #category : 'sorting' }
FamixSimpleDiff >> sortedChildren: entity [

	| res |
	res := childrenCache at: entity ifAbsentPut: [
			       (entity containedEntities reject: [ :e |
				        e isStub or: [ e name = '<Initializer>' ] ]) sorted: [ :a :b |
					       | valA valB |
					       valA := String streamContents: [ :s | a printOn: s ].
					       valB := String streamContents: [ :s | b printOn: s ].
					       valA = valB
						       ifTrue: [
								       a sourceAnchor
									       ifNotNil: [
											       b sourceAnchor
												       ifNotNil: [ "case for two entities with identical printing string but different source anchor (several inner classes in the same parent for example)"
													       a sourceAnchor endPos < b sourceAnchor endPos ]
												       ifNil: [ valA < valB ] ]
									       ifNil: [ valA < valB ] ]
						       ifFalse: [ valA < valB ] ] ].


	^ res
]
