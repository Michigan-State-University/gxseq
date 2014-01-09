Feature: Blast Tool
  Users can supply one or more nucleotide or protein sequence in fasta format and blast against loaded databases with NCBI blast programs.
  
  Background:
  And there is a group "group1"
  And there is a group "group2"
  
  Scenario: Members should see group accessible blast databases
  And there are the following Blast Databases:
  | name | description | group |
  | blast1 | Test Blast v1 | public |
  | blast2 | Test Blast v2 | group1 |
  | blast2 | Test Blast v3 | group2 |
  And I am signed in as "test_user"
  And "test_user" is a member of group "group1"
  When I visit the blast tool
  Then the "blast_blast_database_id" drop-down should contain the options:
  | Test Blast v1 | Test Blast v2 |
  
  Scenario: Guest users should only see public blast databases
  And there are the following Blast Databases:
  | name | description | group |
  | blast1 | Test Blast v1 | public |
  | blast2 | Test Blast v2 | public |
  | blast3 | Test Blast v3 | group1 |
  | blast4 | Test Blast v4 | group2 |
  And I am not signed in
  When I visit the blast tool
  Then the "blast_blast_database_id" drop-down should contain the options:
  | Test Blast v1 | Test Blast v2 |
  
  @javascript
  Scenario: Users can run blastn with nucleotide sequence
  Given the test blast database exists
  And I have access to the test blast db
  When I visit the blast tool
  And I enter the test sequence
  And I choose blast program "blastn"
  And I submit the form
  Then I should see the blast alignment