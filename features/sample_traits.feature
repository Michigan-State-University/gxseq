Feature: Sample Traits
  Samples have user defined attributes used to group and filter results.
  Scenario: Members can manage trait types from samples
    Given There is a sample
    And I have "member" access to the sample
    When I view the sample update page
    And I choose to manage trait types
    And I add a trait "DPA" with definition "Days Post Anthesis"
    Then I should see a trait "DPA" with definition "Days Post Anthesis"
    
  @javascript
  Scenario: Members can add traits to a sample
    Given There is a sample
    And I have "member" access to the sample
    And there is a trait "Genotype"
    And there is a trait "DPA"
    When I view the sample update page
    And I add a new trait "Genotype" with value "G1"
    And I add a new trait "DPA" with value "5"
    And I save the changes
    Then I should see trait "Genotype" with value "G1"
    And I should see trait "DPA" with value "5"
    
  Scenario: Traits should be listed with samples
    Given There is a sample
    And I have "member" access to the sample
    And there is a trait "Genotype"
    And the sample has trait "Genotype" with value "WT"
    When I view the sample listing
    Then I should see trait "Genotype" with value "WT"
  
  Scenario: Feature expression should display series option for sample traits
    Given there is a public feature
    And the feature has the following sample counts and traits:
    | name | norm | count | Genotype | DPA |
    | A1 | 4 | 4 | WT | 1 |
    | B1 | 2 | 2 | OX | 1 |
    When I visit expression details of the feature
    Then I should be able to group by sample traits "None","Genotype" and "DPA"
  
  Scenario: Expression data should not be grouped by default
    Given there is a public feature with locus "LOC01"
    And the feature has the following sample counts and traits:
    | name | norm | count | Genotype | DPA |
    | A1 | 4 | 4 | WT | 1 |
    | A2 | 8 | 8 | WT | 3 |
    | B1 | 2 | 2 | OX | 1 |
    | B2 | 6 | 6 | OX | 3 |
    When I visit json expression data for the feature grouped by "None"
    Then the JSON should have 1 entry
    And the JSON should be: 
    """
    [{
      "series":"LOC01",
      "values":[
        {"x":"A1","y":"4.0"},
        {"x":"A2","y":"8.0"},
        {"x":"B1","y":"2.0"},
        {"x":"B2","y":"6.0"}
      ]
    }]
    """
  Scenario: Expression data should be grouped when a trait is supplied
    # Empty trait should also be left out of response
    Given there is a public feature with locus "LOC01"
    And the feature has the following sample counts and traits:
    | name | norm | count | Genotype | DPA |
    | A1 | 4 | 4 | WT | 1 |
    | A2 | 8 | 8 | WT | 3 |
    | B1 | 2 | 2 | OX | 1 |
    | B2 | 6 | 6 | OX | 3 |
    | B3 | 6 | 6 |  | 3 | 
    When I visit json expression data for the feature grouped by "Genotype"
    Then the JSON should have 2 entries
    And the JSON should be: 
    """
    [
    {
      "series":"OX",
      "values":[
        {"x":"B1","y":"2.0"},
        {"x":"B2","y":"6.0"}
      ]
    },
    {
      "series":"WT",
      "values":[
        {"x":"A1","y":"4.0"},
        {"x":"A2","y":"8.0"}
      ]
    }]
    """