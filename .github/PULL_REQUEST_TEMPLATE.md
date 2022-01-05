## Description
<!-- Please provide a short description about what this PR changes -->


<!-- The Q2 and Q3 criteria are intended for merges to the main-branch. During the model development, for instance when merging to a feature branch, you may decide to not fill out the checklists. However, we recommend to follow the Q2 checklist during the development. The Q3 checklist becomes relevant for merges to the main-branch which implicitly is a release of the model. -->
## Q2 Criteria
(to be filled out by PR reviewer)
- [ ] use **Camel-Case** (e.g., MyModelElement)
- [ ] the identifiers for all model elements **start with a capital letter** except for properties
- [ ] the identifier for **properties starts with a small letter**
- [ ] all model elements **at least contain the fields "name" and "description"** in English language. 
- [ ] the versioning in the URN **follows semantic versioning**, where minor version bumps are backwards compatible and major version bumps are not backwards compatible. 
- [ ] use **abbreviations only when necessary** and if these are sufficiently common
- [ ] **avoid redundant prefixes in property names** (consider adding properties to an enclosing Entity or even adapt the namespace of the model elements, e.g., instead of having two properties `DismantlerId` and `DismantlerName` use an Entity `Dismantler` with the properties `name` and `id` or use a URN like `org.catenax.dismantler:0.0.1`)
- [ ] fields `preferredName` and `description` are not the same
- [ ] **`preferredName` should be human readable** and follow normal orthography (e.g., no camel case but normal word separation)
- [ ] name of Aspect is singular except if it only has one property which is a Collection, List or Set. In theses cases, the Aspect name is plural.
- [ ] units are referenced from the BAMM unit catalog whenever possible
- [ ] **use constraints** to make known constraints from the use case explicit in the aspect model 

## Q3 Criteria
(to be filled out by semantic modeling team before merge to main-branch)
- [ ] All required reviewers have approved this PR (see reviewers section)
- [ ] The new aspect (version) will be implemented by at least one data provider
- [ ] The new aspect (version) will be consumed by at least one data consumer
- [ ] There exists valid test data
- [ ] In case of a new (incompatible) major version to an existing version, a migration strategy has been developed
- [ ] The model has at least version '1.0.0'
- [ ] There are no conflicts of interest (e.g. violations of intellectual property)


<!-- Please reference an issue that was initially created to introduce the new aspect model -->
Closes #