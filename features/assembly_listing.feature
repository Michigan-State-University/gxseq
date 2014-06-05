Feature: Assembly Listing
List all the assemblies (Genome or Transcriptome) with links to browse or view

  Scenario: Public Genomes should be visible to everyone
  Given there is a public assembly
  When I visit the genome listing
  Then I should see 2 rows in the table

  Scenario: Private Genomes should not be visible to everyone
  Given I am not signed in
  And there is an assembly
  When I visit the genome listing
  Then I should see 0 rows in the table

  Scenario: Private Transcriptomes should be visible to members
  Given there are 3 "Transcriptome" assemblies
  And I have "member" access to all assemblies
  And I visit the transcriptome listing
  Then I should see 6 rows in the table
  
  Scenario: Explore link should list sequence entries
  
  Scenario: View link should open genomic context
