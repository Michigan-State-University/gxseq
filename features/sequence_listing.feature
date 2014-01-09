Feature: Sequence Listing
  List all the different sequences in the site with search and sort. Link to sequence viewer or details.

  Scenario: List sequence in default group
  If sequence is in the same group as a user it should be visible
  Given I am signed in as "test_user"
  And there is a group "default"
  And "test_user" is a member of group "default"
  And there are 2 sequence entries in group "default"
  When I visit the sequence list
  Then I should see 2 rows in the table
  
  Scenario: Empty Public Listing
  If no public sequence is available the listing should be empty
  Given I am not signed in
  And there are 2 sequence entries
  When I visit the sequence list
  Then I should see 0 rows in the table

  Scenario: Public Listing
  If sequence is available in the public group it should be displayed
  Given I am not signed in
  And the public group exists
  And there are 4 sequence entries in group "public"
  When I visit the sequence list
  Then I should see 4 rows in the table