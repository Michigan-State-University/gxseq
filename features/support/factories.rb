require 'factory_girl'
FactoryGirl.define do
  # Accounts
  factory :user do
    sequence(:id)
    sequence(:login){|i| "test_user#{i}"}
    sequence(:email){|i|"test_user#{i}@test.net"}
    password 'secret'
    password_confirmation 'secret'
  end
  factory :group do
    sequence(:id)
    sequence(:name){|i| "group_#{i}"}
  end
  factory :favorite_seqfeature do
    user
    association :item, :factory => :seqfeature
    factory :favorite_mrna_seqfeature do
      association :item, :factory => :mrna_feature
    end
  end
  # Samples
  factory :sample do
    sequence(:id)
    sequence(:name){|n| "sample_#{n}"}
    type "RnaSeq"
    description "Test sample"
    assembly
    concordance_set
    user
    group {assembly.group}
  end
  factory :feature_count do
    sequence(:id)
    count 1
    normalized_count 1
    unique_count 1
  end
  factory :trait do
    sequence(:id)
    term
    sample
    user
    value "Trait1"
  end
  factory :concordance_set do
    sequence(:id)
    sequence(:name){|n| "Set_#{n}"}
    assembly
    ignore do
      item_setup ['Chr1','Chr2']
    end
    after(:create) do |concordance_set, evaluator|
      evaluator.item_setup.each do |setup|
        concordance_set.concordance_items << FactoryGirl.create(:concordance_item,
          :reference_name => setup[0],
          :bioentry => FactoryGirl.create(:bioentry)
        )
      end
    end
  end
  factory :concordance_item do
    sequence(:id)
    bioentry
  end
  # Blast
  factory :blast_database do
    sequence(:id)
    sequence(:name){|n| "blast#{n}" }
    filepath 'test.fa'
    link_ref '/seqfeatures/'
    group
    description 'Testing database'
  end
  factory :blast_run do
    blast_database
  end
  factory :blast_report do
    sequence(:id)
    blast_run
    seqfeature
    hit_def "Default Blast Definition"
  end
  
  ## Biosql ##
  
  # Features
  factory :seqfeature, :class => "Biosql::Feature::Seqfeature" do
    sequence(:seqfeature_id)
    bioentry
    display_name "Gene"
    ignore do
      loc_setup [[0,100]]
      qualifier_setup [[:locus_qual],[:gene_qual, 'WRI1'],[:note_qual]]
    end
    source_term { Biosql::Term.find_by_name_and_ontology_id('source',Biosql::Term.ano_tag_ont_id) || create(:source_term) }
    type_term { Biosql::Term.find_by_name_and_ontology_id('gene',Biosql::Term.seq_key_ont_id) || create(:gene_term) }
    before(:create) do |feature,evaluator|
      evaluator.loc_setup.each do |loc|
        feature.locations << FactoryGirl.create(:location,:seqfeature => feature,:start_pos => loc[0],:end_pos => loc[1])
      end
      evaluator.qualifier_setup.each do |qual_setup|
        if(qual_setup[1])
          feature.qualifiers << FactoryGirl.create(qual_setup[0],:seqfeature => feature, :value => qual_setup[1])
        else
          feature.qualifiers <<  FactoryGirl.create(qual_setup[0],:seqfeature => feature)
        end
      end
    end
    factory :public_feature do
      association :bioentry, :factory => :public_bioentry
    end
    factory :mrna_feature do
      display_name 'Mrna'
      type_term { Biosql::Term.find_by_name_and_ontology_id('mrna',Biosql::Term.seq_key_ont_id) || create(:mrna_term) }
    end
    factory :cds_feature do
      type_term { Biosql::Term.find_by_name_and_ontology_id('cds',Biosql::Term.seq_key_ont_id) || create(:cds_term) }
      display_name 'Cds'
    end
  end
  # attributes
  factory :qualifier, :class => "Biosql::SeqfeatureQualifierValue" do
    value "NA"
    rank 1
    term
    factory :locus_qual do
      value 'AT3G54320'
      term { Biosql::Term.find_by_name_and_ontology_id('locus_tag',Biosql::Term.ano_tag_ont_id) || create(:locus_term) }
    end
    factory :gene_qual do
      value 'WRI1'
      term { Biosql::Term.find_by_name_and_ontology_id('gene',Biosql::Term.ano_tag_ont_id) || create(:gene_name_term) }
    end
    factory :note_qual do
      value 'supporting evidence for this feature'
      term { Biosql::Term.find_by_name_and_ontology_id('note',Biosql::Term.ano_tag_ont_id) || create(:note_term) }
    end
  end
  factory :location, :class => "Biosql::Location" do
    start_pos 1
    end_pos 1000
    strand 1
    rank 1
  end
  # Sequence
  factory :bioentry, :class => "Biosql::Bioentry" do
    sequence(:bioentry_id)
    assembly
    biodatabase_id 1
    division "PLN"
    sequence(:name){|i| "Chr #{i}"}
    sequence(:accession){|i| "NC0001#{i}"}
    sequence(:identifier)
    version 1
    ignore do
      seq_setup Hash.new(:length => 100)
    end
    factory :public_bioentry do
      association :assembly, :factory => :public_assembly
    end
    after(:create) do |entry, evaluator|
      FactoryGirl.create(:biosequence, {:bioentry => entry}.merge(evaluator.seq_setup))
    end
  end
  factory :biosequence, :class => "Biosql::Biosequence" do
    bioentry
    alphabet 'DNA'
    length 100
    version 1
    seq "atgctgctgagtgatgacgtgctagatagactgctacgacataattatttaaaaaaaaaaccccccccccaaaaaaaaaattttttttttccccccctga"
  end
  # Taxonomy
  factory :taxon, :class => "Biosql::Taxon" do
    sequence(:taxon_id)
    ignore do
      taxon_name_setup [{}]
    end
    factory :species_taxon do
      node_rank "species"
      sequence(:taxon_name_setup){|i| [{:name => "A. thaliana #{i}"}] }
    end
    after(:create) do |taxon, evaluator|
      evaluator.taxon_name_setup.each do |setup|
        opts = {:taxon_id => taxon.taxon_id}.merge(setup)
        FactoryGirl.create(:taxon_name, opts)
      end
    end
  end
  factory :taxon_name, :class => "Biosql::TaxonName"do
    sequence(:name){|i|"Arabidopsis thale cress #{i}"}
    name_class "scientific name"
  end
  factory :assembly do
    sequence(:version){|n| "#{n}"}
    taxon
    association :species, :factory => :species_taxon
    type "Genome"
    group
    ignore do
      # bioentries: count
      seq_count 0
      # seqfeatures: bioentry,count [[1,1]]
      feature_setup []
    end
    before(:create) do |assembly, evaluator|
      evaluator.seq_count.to_i.times do |idx|
        assembly.bioentries << FactoryGirl.create(:bioentry,:assembly => assembly)
      end
    end
    # add features after create to index assembly/bioentry
    after(:create) do |assembly, evaluator|
      evaluator.feature_setup.each do |setup|
        seq = assembly.bioentries[setup[0]-1]
        setup[1].to_i.times do |idx|
          FactoryGirl.create(:seqfeature,
            :bioentry => seq,
            :qualifier_setup => [[:locus_qual,"LOC0#{idx}"]]
          )
        end
      end
      # force commit
      Sunspot.commit_if_dirty
    end
    
    factory :transcriptome do
      type "Transcriptome"
    end
    factory :public_assembly do
      # pre-created in hooks.rb
      group {Group.find_by_name('public')}
    end
    
  end
  
  
  factory :term, :class => "Biosql::Term" do
    sequence(:term_id)
    sequence(:name){|i| "generic term #{i}"}
    ontology_id {Biosql::Term.ano_tag_ont_id}
    factory :source_term do
      ontology_id {Biosql::Term.ano_tag_ont_id}
      name 'source'
    end
    # term singleton classes
    # must use with find_by_name
    factory :locus_term do
      ontology_id {Biosql::Term.ano_tag_ont_id}
      name 'locus_tag'
    end
    factory :db_xref_term do
      ontology_id {Biosql::Term.ano_tag_ont_id}
      name 'db_xref'
    end
    factory :note_term do
      ontology_id {Biosql::Term.ano_tag_ont_id}
      name 'note'
    end
    factory :gene_name_term do
      ontology_id {Biosql::Term.ano_tag_ont_id}
      name 'gene'
    end
    factory :gene_term do
      ontology_id {Biosql::Term.seq_key_ont_id}
      name 'gene'
    end
    factory :cds_term do
      ontology_id {Biosql::Term.seq_key_ont_id}
      name 'cds'
    end
    factory :mrna_term do
      ontology_id {Biosql::Term.seq_key_ont_id}
      name 'mrna'
    end
  end
  
end