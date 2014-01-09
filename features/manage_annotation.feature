Feature: Manage Annotations
  Users can manage the sequence annotations updating, removing, and adding items
  @javascript
  Scenario: Members should be able to create a new gene on public sequence
    Given there is a Genbank source
    And there is a public assembly
    And the public assembly has 2 sequence entries
    And I am signed in with role "member"
    When I visit the create gene page
    And I create a new gene with 2 gene models
    Then I should see a gene with 2 gene models
  @javascript
  Scenario: Members should be able to create a gene on accessible sequence
    Given there is a Genbank source
    And there is an assembly
    And the assembly has 2 sequence entries
    And I have "member" access to the assembly
    When I visit the create gene page
    And I create a new gene with 1 gene models
    Then I should see a gene with 1 gene models
  Scenario: Guests should not be able to create a new gene on any sequence
    Given there is a public assembly
    And the public assembly has 3 sequence entries
    And I am signed in with role "guest"
    When I visit the create gene page
    Then I should be denied
  Scenario: The public should not be able to create gene on any sequence
    Given there is a public assembly
    And the public assembly has 1 sequence entries
    And I am not signed in
    When I visit the create gene page
    Then I should be denied
  @javascript
  Scenario: Members should be able to update public features
    Given there is a public feature
    And there is a "Function" annotation
    And I am signed in with role "member"
    When I visit the edit feature page
    And I add a "Function" annotation of "Amazing Stuff"
    And I save the changes
    Then I should see a new "Function" annotation of "Amazing Stuff"
    And the history should show "Amazing Stuff" "create"
  Scenario: Guests should not be able to update features
    Given there is a public feature
    And I am signed in with role "guest"
    When I visit the edit feature page
    Then I should be denied
  Scenario: The public should not be able to update features
    Given there is a public feature
    And I am not signed in
    When I visit the edit feature page
    Then I should be denied
  # Scenario: Locus Tags should be unique to an assembly