Feature: Assembly
Manage assemblies in the database

  Scenario: Assemblies with >1000 sequence should be able to delete data
  Given there is an assembly
  And the assembly has 1005 simple sequence entries
  And I delete all data from the assembly
  Then the assembly should have 0 sequence entries