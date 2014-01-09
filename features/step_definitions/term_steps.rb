Given(/^there is a Genbank source$/) do
  FactoryGirl.create(:term, :name => 'Genbank', :ontology_id => Biosql::Term.seq_src_ont_id)
end

Given(/the Term class is reloaded/) do
  Biosql::Term.clear_cache
end

Given(/^there is a "(.*?)" annotation$/) do |name|
  unless Biosql::Term.find_by_name_and_ontology_id(name, Biosql::Term.ano_tag_ont_id)
    FactoryGirl.create(:term, :name => name, :ontology_id => Biosql::Term.ano_tag_ont_id)
  end
end
