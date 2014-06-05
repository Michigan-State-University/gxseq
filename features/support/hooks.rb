Before do
  #clear caches
  Ability.reset_cache
  Biosql::Term.reset_cache
  #reset sunspot
  Sunspot.remove_all!
  #initialize seed data
  Group.delete_all
  FactoryGirl.create(:group, :name => 'public')
  FactoryGirl.create(:locus_term)
  FactoryGirl.create(:db_xref_term)
  ##See at_exit
  BlastDatabase.delete_all
  BlastDatabase.connection.execute("Insert into blast_databases (id, name) values(1,'SeedBlastDb')")
  BlastRun.delete_all
  BlastRun.connection.execute("Insert into blast_runs (id, blast_database_id) values(1,1)")
end

at_exit do
  #NOTE used to avoid Seqfeature static index definition issues
  # Pre creating a basic blast run so the id is baked into the index
  # this blast run is used in feature steps to assign index blast defs
  # It must exist PRIOR to loading the rails class framework in cucumber
  BlastDatabase.delete_all
  BlastDatabase.connection.execute("Insert into blast_databases (id, name) values(1,'SeedBlastDb')")
  BlastRun.delete_all
  BlastRun.connection.execute("Insert into blast_runs (id, blast_database_id) values(1,1)")
end