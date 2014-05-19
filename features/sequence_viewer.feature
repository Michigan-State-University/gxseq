Feature: Sequence Viewer
Show the genomic context for a bioentry. Allow navigation and display of related experimental data
  @javascript
  Scenario: Viewing a sequence should render the sequence viewer
    Given there is a public assembly
    And the assembly has 3 sequence entries
    When I visit the genome listing
    And I click "View First entry"
    Then I should see the sequence viewer