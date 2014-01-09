@thor
Feature: Dump a blast database
export sequence for a chosen feature to use as a blast database
  Scenario: The special transcriptome should match the test database
    # The transcriptome listed must be correlated with the lib/blast_db/test.fa file that is already saved and formatted
    Given there is a Transcriptome with id 1 and the following sequence:
    | name | locus | length | seq |
    | Contig1 | C00001 | 100 | atgttctttatttttttaaattttcttttttagtttttttttaaaatttttttattttttaaaattttgatttaaaatttttttttttttaaaatttttt |
    | Contig2 | C00002 | 100 | atgggggggtgggggggtttgggggggggggaagggggggggttttgggggggaagggggttttgggggatggttttgggggggtgggggttttgggggg |
    | Contig3 | C00003 | 100 | attttgcgcgcgtggtcttgggctttcggcttgcgcgctctgcgagcattggcgttgtgacggtaatattatcttctatcttattataaatacgaaaaaa |
    | Contig4 | C00004 | 100 | attttgcgcgcgtggtcttgggctttcggcttgcgcgctctgcgagcattggcgttgtgacggtaatattatcttctatcttattataaatacgaaaaaa |
    When I run thor sequence:dump_features with "-a 1 -o cuc_test.fa -f Mrna"
    And I run `diff cuc_test.fa ../../lib/data/blast_db/test.fa`
    Then the stdout should not contain "\n"
    
  Scenario: A different transcriptome should not match the test database
    Given there is a Transcriptome with id 1 and the following sequence:
    | name | locus | length | seq |
    | Contig1 | C00001 | 10 | ttggttggtt |
    | Contig2 | C00002 | 10 | ggccggccgg |
    | Contig3 | C00003 | 10 | ccggccggcc |
    | Contig4 | C00004 | 10 | ccttccttcc |
    When I run thor sequence:dump_features with "-a 1 -o cuc_test.fa -f Mrna"
    And I run `diff cuc_test.fa ../../lib/data/blast_db/test.fa`
    Then the stdout should contain "\n"
    
  Scenario: The output should only include the supplied assembly
    Given there is a Transcriptome with id 1 and the following sequence:
    | name | locus | length | seq |
    | Contig1 | C00001 | 10 | ttggttggtt |
    | Contig2 | C00002 | 10 | ggccggccgg |
    | Contig3 | C00003 | 10 | ccggccggcc |
    | Contig4 | C00004 | 10 | ccttccttcc |
    And there is a Transcriptome with id 2 and the following sequence:
    | name | locus | length | seq |
    | A1 | A001 | 10 | tttttttttt |
    | A2 | A002 | 10 | aaaaaaaaaa |
    | A3 | A003 | 10 | cccccccccc |
    When I run thor sequence:dump_features with "-a 2 -o cuc_test.fa -f Mrna"
    Then the last output should match "3 features"
    And the file "cuc_test.fa" should not match /Contig1|Contig2|Contig3|Contig4/
    And the file "cuc_test.fa" should match /A001/
    And the file "cuc_test.fa" should match /tttttttttt/
    
  Scenario: Running with no options should report required options
    When I run thor sequence:dump_features with ""
    Then the last output should match "No value provided for required options"