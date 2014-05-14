Before do
  #clear caches
  Ability.reset_cache
  Biosql::Term.reset_cache
  #reset sunspot
  Sunspot.remove_all!
  #initialize seed data
  FactoryGirl.create(:group, :name => 'public')
  FactoryGirl.create(:locus_term)
  FactoryGirl.create(:db_xref_term)
end