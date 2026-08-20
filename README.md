# Famix-Simple-Diff
Simple implementation to compare two models and return whether they are identical or not.
The tool also provides a list of differences that you can find between models.

## Baseline

```Smalltalk
Metacello new
  baseline: 'FamixSimpleDiff';
  repository: 'github://moosetechnology/Famix-Simple-Diff:main/src';
  load
```
## How to use Famix-Simple-Diff

```Smalltalk
model1 := '/path/to/my/original_model.json' asFileReference readStreamDo: [ :st | FamixJavaModel new importFromJSONStream: st ].
model2 := '/path/to/my/modified_model.json' asFileReference readStreamDo: [ :st | FamixJavaModel new importFromJSONStream: st ].

diff := FamixSimpleDiff new.

"Run the comparison"
diff compareModel: model1 to: model2.

" Gives the differences between models"
diff differences.
```
## How does it work
The tool will traverse all the entities of the model and use the Moose meta-description and a worklist algorithm to compare their types, properties, and relations. All comparisons are made from the perspective of the second model, which is the target of the changes.

You have 5 possible differences: 
- `FSDEntityAddition`: An entity has been added to the target model.
- `FSDEntityDeletion`: An entity has been removed from the target model.
- `FSDEntityChanged`: An entity changed between the models.
- `FSDPropertyChanged`: A property of an entity has been modified.
- `FSDRelationChanged`: A relation to another entity has been modified.

For all these types of changes, the difference object contains the value that was expected and the value that we got.
