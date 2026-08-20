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
		'shouldCompareOppositeRelation'
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

	| diff isEquals |
	isEquals := true.
	differences ifNil: [ differences := OrderedCollection new ].
	
	"we compare the type of the entities. If we have not the same type, we add the difference in the list"
	aFamixEntity class = otherFamixEntity class ifFalse: [
			diff := FSDEntityChanged
				        createDifference: otherFamixEntity
				        expectedValue: aFamixEntity class name
				        actualValue: otherFamixEntity class name.
			self addDifference: diff.
			^ self fail ].

	aFamixEntity metadescription allPropertiesDo: [ :prop |
			isEquals := isEquals
			            &
			            (self
				             compareEntity: aFamixEntity
				             to: otherFamixEntity
				             property: prop) ].

	"we stop the execution here if models are differents"
	isEquals ifFalse: [ ^ self fail ].

	"Every slot value are equal, the entities are identical"
	^ true
]

{ #category : 'comparing' }
FamixSimpleDiff >> compareEntity: aFamixEntity to: otherFamixEntity property: property [
	"Compare property or relation using Moose meta models"

	"We focus on entity with a primitive type (Boolean, Number, String). We exclude derived properties to not pollute difference list"
	^ property type isPrimitive
		ifTrue: [ self comparePrimitiveProperties: property from: aFamixEntity to: otherFamixEntity ]
		ifFalse: [ self compareRelationProperties: property from: aFamixEntity  to: otherFamixEntity ]
]

{ #category : 'comparing' }
FamixSimpleDiff >> compareModel: aFamixModel to: aFamixModel2 [
	"Will compare two models iteratively using the worklist algorithm"

	| worklist visited |
	"Initalization"
	worklist := self initializeWorklistFrom: aFamixModel to: aFamixModel2.
	visited := IdentitySet new.
	differences := OrderedCollection new.

	"doing tasks until the tasklist is empty"
	^ self processWorklist: worklist visited: visited 
]

{ #category : 'comparing' }
FamixSimpleDiff >> comparePrimitiveProperties: property from: aFamixEntity to: otherFamixEntity [
	"Is used for the properties comparisons"

	"We focus on entity with a primitive type (Boolean, Number, String). We exclude derived properties to not pollute difference list"

	| diff property1 property2 |
	"filter derived properties"
	(property isDerived or: [ property name beginsWith: 'numberOf' ])
		ifTrue: [ ^ true ].

	"comparing values"
	property1 := property getRawFrom: aFamixEntity.
	property2 := property getRawFrom: otherFamixEntity.
	property1 = property2 ifTrue: [ ^ true ].

	"We create a propety change differrences if our properties are not equals"
	diff := FSDPropertyChanged
	        createDifference: property name
	        entity: otherFamixEntity
	        expectedValue: property1
	        actualValue: property2.
	
	self addDifference: diff.
	^ false
]

{ #category : 'comparing' }
FamixSimpleDiff >> compareRelation: aRelationDescription from: aFamixEntity to: otherFamixEntity [

	| val1 val2 sortBlock |
	aRelationDescription isMultivalued
		ifFalse: [ "toOne relation"
				val1 := aRelationDescription getRawFrom: aFamixEntity.
				val2 := aRelationDescription getRawFrom: otherFamixEntity ]
		ifTrue: [ "toMany relation"
				| rejectBlock |
				val1 := (aRelationDescription getRawFrom: aFamixEntity)
					        asOrderedCollection.
				val2 := (aRelationDescription getRawFrom: otherFamixEntity)
					        asOrderedCollection.

				rejectBlock := [ :e | e name = 'clone' ].
				val1 := val1 reject: rejectBlock.
				val2 := val2 reject: rejectBlock.

				sortBlock := self sort.
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
					  target: otherFamixEntity
					  relation: aRelationDescription ]
		  ifTrue: [
			  self
				  compareToManyRelation: val1
				  actual: val2
				  target: otherFamixEntity ]
]

{ #category : 'comparing' }
FamixSimpleDiff >> compareRelationProperties: property from: aFamixEntity to: otherFamixEntity [
	"Is used for the relations comparisons"

	(property name = 'sourceAnchor' or: [
		 (self shouldCompareRelation: property) not ]) ifTrue: [ ^ true ].

	^ self
		  compareRelation: property
		  from: aFamixEntity
		  to: otherFamixEntity
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

			"We use the personalised signature to prevent from 'nonameEntities' "
			name1 := self sortNameFor: element1.
			name2 := self sortNameFor: element2.

			name1 = name2
				ifTrue: [ "move forward both ptr if identicals"
						stream1 next.
						stream2 next ]
				ifFalse: [
						name1 < name2
							ifTrue: [ "deletion case"
									diff := FSDEntityDeletion
							        	createDifference: anEntity
							        	expectedValue: element1.
							      diff indexInParent: stream1 position.
									
									self addDifference: diff.
									isEquals := false.
									stream1 next "ptr1++" ]
							ifFalse: [ "addition case"
									diff := FSDEntityAddition
										        createDifference: anEntity
										        actualValue: element2.
									diff indexInParent: stream2 position.

									self addDifference: diff.
									isEquals := false.
									stream2 next "ptr2++" ] ] ].

	"cleaning end of pointers, checking if they have clean something"
	"if they have deleted/added something, so the models are not equals"
	(self finishRemainingDeletionOf: stream1 target: anEntity) ifTrue: [
		isEquals := false ].
	(self finishRemainingAdditionOf: stream2 target: anEntity) ifTrue: [
		isEquals := false ].

	^ isEquals
]

{ #category : 'comparing' }
FamixSimpleDiff >> compareToOneRelation: val1 actual: val2 target: anEntity relation: aRelationDescription [

	| areEquals diff |
	"if we dont have the same relations, so it changed, we have to record it"
	areEquals := (self pathesForMaybeMultiRelation: val1)
	             = (self pathesForMaybeMultiRelation: val2).
	areEquals ifFalse: [
			diff := FSDRelationChanged
				        createDifference: aRelationDescription name
				        entity: anEntity
				        expectedValue: val1
				        actualValue: val2.
			self addDifference: diff ].

	^ areEquals
]

{ #category : 'path-computing' }
FamixSimpleDiff >> computePathOfEntity: anEntity [

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

	^ differences ifNil: [
		  self error: ' Comparison not executed yet. Please compare two models before accessing to the differences.' ]
]

{ #category : 'comparing' }
FamixSimpleDiff >> enqueueRemainingTasksOf: entity1 and: entity2 into: worklist [

	(self sortedChildren: entity1)
		with: (self sortedChildren: entity2)
		do: [ :child1 :child2 |
				worklist add: { child1. child2 } ]
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

	| theRoots rootEntity |
	"checking non-existent index"
	theRoots := self entityRoots: model.
	(indexPath first between: 1 and: theRoots size) ifFalse: [ ^ nil ].

	rootEntity := (self entityRoots: model) at: indexPath first.
	^ self entityAtPath: indexPath allButFirst fromEntity: rootEntity
]

{ #category : 'accessing' }
FamixSimpleDiff >> entityRoots: aFamixJavaModel [

	| excludedClasses |
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
				  rootEntities sorted: self sort ]
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
			  | diff |
			  diff := FSDEntityAddition
				          createDifference: anEntity
				          actualValue: val.
			  diff indexInParent: aStream position.
			  diff ]
]

{ #category : 'accessing' }
FamixSimpleDiff >> finishRemainingDeletionOf: aStream target: anEntity [

	^ self finishRemaining: aStream diffCreation: [ :val |
			  | diff |
			  diff := FSDEntityDeletion
				          createDifference: anEntity
				          expectedValue: val.
			  diff indexInParent: aStream position.
			  diff ]
]

{ #category : 'initialization' }
FamixSimpleDiff >> initialize [

	super initialize.
	debug := false.
	childrenCache := LRUCache new maximumWeight: 100.
	
	"By default we assume that opposite relations are ok if the main relation is ok.
	This makes diffing faster, but less precise.
	However, some model bugs come appear here, so check it optionally"
	shouldCompareOppositeRelation := false
]

{ #category : 'comparing' }
FamixSimpleDiff >> initializeWorklistFrom: aFamixJavaModel to: aFamixJavaModel2 [
	"worklist initialisation"

	| worklist |
	worklist := OrderedCollection new.
	(self entityRoots: aFamixJavaModel) do: [ :root |
			| correspondingRoot |
			correspondingRoot := self correspondingEntityTo: root in: aFamixJavaModel2.
			worklist addLast: {root . correspondingRoot } ].
		
	^ worklist 
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
FamixSimpleDiff >> processNextTaskFrom: worklist visited: visited [

	| currentTask entity1 entity2 |
	currentTask := worklist removeFirst.
	entity1 := currentTask first.
	entity2 := currentTask second.

	"new task case"
	(visited includes: entity1) ifFalse: [
			visited add: entity1.

			"filter for strange cases"
			(self shouldSkipComparisonEntity: entity1 with: entity2) ifTrue: [^ true ].

			(self compareEntity: entity1 to: entity2) ifFalse: [ ^ false ].

			"complete worklist"
			self enqueueRemainingTasksOf: entity1 and: entity2 into: worklist ].
	^ true
]

{ #category : 'comparing' }
FamixSimpleDiff >> processTimerDuring: aWorklistBlock [
	"Will update the timer of models comparison in a dedicated Job"

	| time update |
	time := Time millisecondClockValue.
	update := time.

	^ [ :job |
		  job title: 'Comparison of models : 0 s'.
		  job min: 0.
		  job max: 100.

		  aWorklistBlock value: [
				  | now |
				  now := Time millisecondClockValue.

				  "update every seconds"
				  now - update >= 1000 ifTrue: [
						  update := now.
						  job title: 'Comparison of models : ' , (now - time // 1000) asString , ' s'.
						  job currentValue: ((now - time // 50) \\ 100).
						
						  "updating UI"
						  UIManager default currentWorld ifNotNil: [ :world |
							  world doOneCycleNow ] ] ] ] asJob run
]

{ #category : 'comparing' }
FamixSimpleDiff >> processWorklist: worklist visited: visited [
	"Process the worklist using a progress bar to show the comparison progress"

	| timeCounter |
	timeCounter := 0.

	"start the timer and process the worklist"
	^ self processTimerDuring: [ :timerTick |
			  [ worklist isEmpty ] whileFalse: [
					  (self processNextTaskFrom: worklist visited: visited) ifFalse: [^ self fail ].
					  timeCounter := timeCounter + 1.

					  "update tick"
					  timeCounter \\ 1000 = 0 ifTrue: [ timerTick value ] ].
			  differences isEmpty ]
]

{ #category : 'accessing' }
FamixSimpleDiff >> shouldCompareOppositeRelation [

	^ shouldCompareOppositeRelation
]

{ #category : 'accessing' }
FamixSimpleDiff >> shouldCompareOppositeRelation: anObject [

	shouldCompareOppositeRelation := anObject
]

{ #category : 'comparing' }
FamixSimpleDiff >> shouldCompareRelation: aFM3Property [
	"We use this filter to avoid comparing the same relation. Here is the idea:
	. A relation without opposite is important, so we keep it.
	. If we have a multivalued relation on a side, and a non multivalued relation on the other side, we keep the multivalued one.
	. If both are multivalued, we check if one side is derived. In this case we keep the derived one."

	"we want to skip derived relations without opposites"
	
	(shouldCompareOppositeRelation and: [ aFM3Property hasOpposite ]) ifTrue: [ ^ true ].

	(aFM3Property isDerived and: [ aFM3Property hasOpposite not ]) ifTrue: [ ^ false ].

	^ aFM3Property isMultivalued ~= aFM3Property opposite isMultivalued
		  ifTrue: [ aFM3Property isMultivalued ]
		  ifFalse: [ aFM3Property isDerived ]
]

{ #category : 'comparing' }
FamixSimpleDiff >> shouldSkipComparisonEntity: entity1 with: entity2 [
	"Evaluates if an entities should be skiped due to edge case (parametric entities, anonymous classes, clone."

	"Parametric entities and inner classes are not used in the comparison process, so we return true by default"
	entity1 mooseName = entity2 mooseName ifTrue: [
			(entity1 isParametricEntity and: [ entity2 isParametricEntity ])
				ifTrue: [ ^ true ].
			(entity1 isType and: [ entity1 isAnonymousClass ]) ifTrue: [
				^ true ] ].

	"Clone methods have an issue (potentially due to JDT) which isn't easy to fix, so we skip those."
	entity1 name = 'clone' ifTrue: [ ^ true ].
	
	^false
]

{ #category : 'sorting' }
FamixSimpleDiff >> sort [
	"We use mooseName to sort the entities.
	We use the string builded by the method sortNameFor: to sort the relation having 'noname' as a mooseName
	If names are identical, we use sorceAnchor"

	^ [ :a :b |
		  | nameA nameB |
		  nameA := self sortNameFor: a.
		  nameB := self sortNameFor: b.

		  nameA = nameB
			  ifTrue: [
					  (a sourceAnchor notNil and: [ b sourceAnchor notNil ])
						  ifTrue: [ a sourceAnchor endPos < b sourceAnchor endPos ] "sorting the source anchors"
						  ifFalse: [ a sourceAnchor notNil ] ]
			  ifFalse: [ nameA < nameB ] ] "alphabetical order sorting"
]

{ #category : 'sorting' }
FamixSimpleDiff >> sortNameFor: aFamixEntity [
	"Creates and put in cache a specific name for generic entities
	Some entities like the relations have 'noname' as a name
	To avoid that, we generate an unique name following the form : 'noname-source-target' "

	^ aFamixEntity cacheAt: #fsdRelationalName ifAbsentPut: [
		| name |
		name := aFamixEntity mooseName asString.

		"we have a relation"
		name = 'noname'
			ifTrue: [
					String streamContents: [ :stream |
							| properties |
							stream << 'noname'.

							"We get all properties that point to other entities"
							properties := aFamixEntity metadescription allProperties select: [ :prop |
								              prop isMultivalued not and: [
									              prop type isPrimitive not ] ].

							"We sort the properties to build the string"
							(properties sorted: [ :p1 :p2 | p1 name < p2 name ]) do: [ :prop |
									(prop getRawFrom: aFamixEntity) ifNotNil: [ :linkedEntity |
											stream
												<< '-';
												<< linkedEntity mooseName asString ] ] ] ]
			ifFalse: [ name ]
		]
]

{ #category : 'sorting' }
FamixSimpleDiff >> sortedChildren: entity [

	^ childrenCache at: entity ifAbsentPut: [
			  (entity containedEntities reject: [ :e |
				   e isStub or: [ e name = '<Initializer>' ] ]) sorted: self sort ]
]
