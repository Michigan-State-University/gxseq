Feature: Expression Viewer
List expression data for features along with annotations. Allow user choice of sample combinations.

  Scenario: Public assemblies should be listed
  Given there is a public assembly
  And the assembly has 2 expression samples
  When I visit the expression tool
  Then I should see "Arabidopsis thale cress" 
  
  Scenario: Private assemblies should not be visible
  Given I am not signed in
  And there is an assembly
  And the assembly has "2" expression samples
  When I visit the expression tool
  Then I should see "you don't have access"
  
  @javascript
  Scenario: Selecting an assembly should display samples
  Given there are 3 "Genome" assemblies
  And the assembly 1 has 1 expression samples
  And the assembly 2 has 2 expression samples
  And the assembly 3 has 4 expression samples
  And I have "member" access to all samples
  When I visit the expression tool
  And I select assembly 1
  Then I should see 1 "samples[]" checkbox
  When I select assembly 3
  Then I should see 4 "samples[]" checkbox

  Scenario: Submitting the form should render expression matrix
  Given there is a public assembly
  And the assembly has 5 genes
  And the assembly has 3 expression samples
  When I visit the expression tool
  And I check "samples[]" 1
  And I check "samples[]" 3
  And I submit the form
  Then I should see 5 rows in the table
  And I should see "Sum" in header column 5
  
  @wip @javascript
  Scenario: Selecting ratio should render expression ratio
  Given there is a public assembly
  And the assembly has 3 genes
  And the assembly has 4 expression samples
  When I visit the expression tool
  And I select option "Ratio" from "form_type"
  And I check "a_samples[]" 1
  And I check "a_samples[]" 2
  And I check "b_samples[]" 3
  And I check "b_samples[]" 4
  And I submit the form
  Then I should see 4 rows in the table
  And I should see "A / B" in table "listing" row 1 col 5
  
  @wip @javascript
  Scenario: Ratio minimum should filter low expression features
  Given there is a public assembly
  And the assembly has 3 genes
  And the assembly has 1 expression sample with values:
  | normalized_count |
  | 20.5 |
  | 20.5 |
  | 20.5 |
  And the assembly has 1 expression sample with values:
  | normalized_count |
  | 20.5 |
  | 75.5 |
  | 75.5 |
  And the assembly has 1 expression sample with values:
  | normalized_count |
  | 0.0 |
  | 0.0 |
  | 0.0 |
  And the assembly has 1 expression sample with values:
  | normalized_count |
  | 5.5 |
  | 6.5 |
  | 7.5 |
  When I visit the expression tool
  And I select option "Ratio" from "form_type"
  And I check "a_samples[]" 1
  And I check "a_samples[]" 2
  And I check "b_samples[]" 3
  And I check "b_samples[]" 4
  And I submit the form
  Then I should see 3 rows in the table
  
  