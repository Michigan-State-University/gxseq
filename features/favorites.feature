Feature: Favorites
  Favorites allow for quick access to common features from the user profile. They also can be used to filter listings.
  Background:
    Given I am signed in as "test_user"
  Scenario: List favorites
    Given "test_user" user has 2 favorite seqfeatures
    When I visit the user profile favorites tab for "test_user"
    Then I should see 2 rows in the table
  Scenario: Favorite type should not include modules
    Given "test_user" user has 2 favorite mrna seqfeatures
    When I visit the user profile favorites tab for "test_user"
    Then I should see 2 rows in the table
    And I should see "Mrna" in column 2
    And I should not see "Biosql::Feature"
  Scenario: Favorite description should include blast reports
    Given "test_user" user has a favorite seqfeature with locus "Fea1"
    And Seqfeature "Fea1" has a blast result with definition "Seed Storage Protein" 
    When I visit the user profile favorites tab for "test_user"
    Then I should see 1 rows in the table
    And I should see "Seed Storage Protein" in column 3
    
    