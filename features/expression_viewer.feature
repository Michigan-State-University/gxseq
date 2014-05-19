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
  And the assembly has 2 expression samples
  When I visit the expression tool
  Then I should see "you don't have access"
  
  @javascript
  Scenario: Selecting an assembly should display samples
  Given there is an assembly "Test1" version "v1"
  And there is an assembly "Foo" version "Bar"
  And there is an assembly "Test2" version "v2"
  And the assembly "Test1" version "v1" has 1 expression samples
  And the assembly "Foo" version "Bar" has 2 expression samples
  And the assembly "Test2" version "v2" has 4 expression samples
  And I have "member" access to all samples
  When I visit the expression tool
  And I select option "Test1 ( v1 )" from "assembly_id"
  Then I should see 1 "samples[]" checkbox
  When I select option "Test2 ( v2 )" from "assembly_id"
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
  
  @javascript
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
  And I should see "A / B" in table "listing" header col 5
  And I should see "50" in table "listing" row 2 col 4
  And I should see "50" in table "listing" row 2 col 3
  And I should see "1.0" in table "listing" row 2 col 5
  
  @javascript
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
  And I should see "48" in table "listing" row 2 col 3
  And I should see "3" in table "listing" row 2 col 4
  And I should see "14.77" in table "listing" row 2 col 5
  
  