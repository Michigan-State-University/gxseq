Feature: Features Listing
  List all the features (Gene,mRNA,etc..) with search and sort
  
  Scenario: List features in default group
  If a feature is in the same group as a user it should be visible
  Given there is a "Gene" feature with locus "LOC10001"
  And I have "member" access to the "Gene" feature with locus "LOC10001"
  When I visit the features list
  Then I should see a "Gene" feature with locus "LOC10001"
  
  Scenario: Empty Public Listing
  If no public features are available the feature listing should be empty
  Given I am not signed in
  And there are no public features
  When I visit the features list
  Then I should see 0 rows in the table

  Scenario: Public Listing
  If features are available in the public group they should be displayed
  Given I am not signed in
  And there are "3" public features
  When I visit the features list
  Then I should see 3 rows in the table
  
  