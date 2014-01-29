Before do
  #clear caches
  Ability.reset_cache
  Biosql::Term.reset_cache
  #reset sunspot
  Sunspot.remove_all!
  #initialize seed data
  #Group.find_by_name('public') ||
  FactoryGirl.create(:group, :name => 'public')
  #Biosql::Term.find_by_name_and_ontology_id('locus_tag',Biosql::Term.ano_tag_ont_id) ||
  FactoryGirl.create(:locus_term)
  #Biosql::Term.find_by_name_and_ontology_id('db_xref',Biosql::Term.ano_tag_ont_id) ||
  FactoryGirl.create(:db_xref_term)
end