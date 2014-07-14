Before do
  #clear caches
  Ability.reset_cache
  Biosql::Term.reset_cache
  #reset sunspot
  Sunspot.remove_all!
  #initialize seed data
  Group.delete_all
  User.delete_all
  FactoryGirl.create(:group, :name => 'public')
  ##See at_exit
  BlastDatabase.delete_all
  BlastDatabase.connection.execute("Insert into blast_databases (id, name) values(1,'SeedBlastDb')")
  BlastRun.delete_all
  BlastRun.connection.execute("Insert into blast_runs (id, blast_database_id) values(1,1)")
  Biosql::Term.delete_all
  Biosql::Ontology.delete_all
  Biosql::Ontology.connection.execute("Insert into ontology (ontology_id,name) values(1,'Annotation Tags')")
  FactoryGirl.create(:locus_term)
  FactoryGirl.create(:db_xref_term)
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
  Biosql::Term.delete_all
  Biosql::Ontology.delete_all
  Biosql::Ontology.connection.execute("Insert into ontology (ontology_id,name) values(1,'Annotation Tags')")
  Biosql::Term.connection.execute("Insert into term (term_id,name,ontology_id) values(1,'gene',1)")
  Biosql::Term.connection.execute("Insert into term (term_id,name,ontology_id) values(2,'function',1)")
  Biosql::Term.connection.execute("Insert into term (term_id,name,ontology_id) values(3,'product',1)")
  
end