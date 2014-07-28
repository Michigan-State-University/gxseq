Feature: Coexpression Chart
Find similar genes from expression profile and display an interactive view

  Scenario: Coexpression tab should be hidden when no expression exists
  Given I am not signed in
  And there is a public assembly
  And the assembly has 1 gene
  When I visit the gene details page
  Then I should not see a coexpression link
  
  Scenario: Coexpression tab should be shown when expression exists
  Given I am not signed in
  And there is a public assembly
  And the assembly has 1 gene
  And the assembly has 1 expression sample
  When I visit the gene details page
  Then I should see a coexpression link
  
  Scenario: Private coexpression should not be available to the public
  Given I am not signed in
  And there is an assembly
  And the assembly has 1 gene
  And the assembly has 1 expression sample
  And I visit the gene coexpression page
  Then I should be denied
  
  @javascript
  Scenario: Co-Expression should return similar genes with annotations
  Given there is an assembly
  And I have "guest" access to the assembly
  And the assembly has 3 features with options:
  | type | locus | gene | function | product |
  | gene_feature | At1g | G1 | Func1 | Prod1 |
  | gene_feature | At2g | G2 | Func2 | Prod2 |
  | gene_feature | At3g | G3 | Func3 | Prod3 |
  And Seqfeature "At2g" has a blast result with definition "Seed Storage"
  And the assembly has 1 expression sample with values:
  | normalized_count |
  | 10 |
  | 1 |
  | 10 |
  And the assembly has 1 expression sample with values:
  | normalized_count |
  | 20 |
  | 2 |
  | 15 |
  And the assembly has 1 expression sample with values:
  | normalized_count |
  | 50 |
  | 5 |
  | 20 |
  And the assembly has 1 expression sample with values:
  | normalized_count |
  | 10 |
  | 1 |
  | 10 |
  And the assembly has 1 expression sample with values:
  | normalized_count |
  | 20 |
  | 2 |
  | 20 |
  When I visit the gene coexpression page for "At1g"
  Then I should see "At1g" in slickgrid row 1 col 1
  And I should see "G1 | Func1 | Prod1" in slickgrid row 1 col 2
  And I should see "G2 | Func2 | Prod2" in slickgrid row 2 col 2
  And I should see "Seed Storage" in slickgrid row 2 col 2
  And I should see "1" in slickgrid row 1 col 3
  And I should see "22" in slickgrid row 1 col 5
  And I should see "1" in slickgrid row 2 col 4
  And I should see "2.2" in slickgrid row 2 col 5
  And I should see "0.7607" in slickgrid row 3 col 3
  And I should see "0.5787" in slickgrid row 3 col 4
  