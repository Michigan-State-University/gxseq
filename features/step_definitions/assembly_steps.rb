Given(/^there is an assembly$/) do
  assembly = FactoryGirl.create(:assembly)
end

Given(/^there is an assembly "(.*?)" version "(.*?)"$/) do |name,version|
  taxon = FactoryGirl.create(:taxon,:taxon_name_setup => [{:name => name}])
  assembly = FactoryGirl.create(:assembly,:version => version,:taxon => taxon)
end

Given(/^there are (\d+) "(.*?)" assemblies$/) do |count,type|
  FactoryGirl.create_list(:assembly, count.to_i, :type => type)
end

Given(/^the assembly has "(.*?)" features?$/) do |count|
  assembly = Assembly.first
  assembly.should_not == nil
  bioentry = FactoryGirl.create(:bioentry,:assembly => assembly)
  FactoryGirl.create_list(:seqfeature,count.to_i,:bioentry => bioentry)
end

Given(/^the assembly has (\d+) genes?$/) do |count|
  assembly = Assembly.first
  assembly.should_not == nil
  bioentry = FactoryGirl.create(:bioentry,:assembly => assembly)
  FactoryGirl.create_list(:gene_feature,count.to_i,:bioentry => bioentry)
end

Given(/^the assembly has (\d+) features with options:$/) do |count,table|
  assembly = Assembly.first
  assembly.should_not == nil
  bioentry = FactoryGirl.create(:bioentry,:assembly => assembly)
  hash = table.hashes
  count.to_i.times do |idx|
    hsh = hash[idx]||{}
    qual_setup = [[:note_qual]]
    qual_setup<< (hsh['locus'] ? [:locus_qual,hsh['locus']] : [:locus_qual])
    qual_setup<< (hsh['gene'] ? [:gene_qual,hsh['gene']] : [:gene_qual,'WRI1'])
    qual_setup<<[:function_qual,hsh['function']] if hsh['function']
    qual_setup<<[:product_qual,hsh['product']] if hsh['product']
    FactoryGirl.create((hsh['type']||'gene'),:bioentry => bioentry,:qualifier_setup => qual_setup)
  end
end

Given(/^the assembly has (\d+) sequence entries/) do |count|
  # add bioentry because assembly needs at least one sequence
  assembly = Assembly.first
  assembly.should_not == nil
  FactoryGirl.create_list(:bioentry,count.to_i,:assembly => assembly)
end

Given(/^the assembly has (\d+) simple sequence entries/) do |count|
  # add bioentry because assembly needs at least one sequence
  assembly = Assembly.first
  assembly.should_not == nil
  FactoryGirl.create_list(:bioentry,count.to_i,:assembly => assembly,:skip_seq => true)
end

Given(/^there is a public assembly$/) do
  assembly = FactoryGirl.create(:public_assembly)
end

Given(/^the public assembly has (\d+) sequence entries/) do |count|
  # add bioentry because assembly needs at least one sequence
  assembly = Assembly.scoped.includes(:group).where{group.name=='public'}.first
  assembly.should_not == nil
  FactoryGirl.create_list(:bioentry,count.to_i,:assembly => assembly)
end

Given /^there is a Transcriptome with id (\d+) and the following sequence:$/ do |id, table|
  entries = table.hashes
  assembly = FactoryGirl.create(:transcriptome, :id => id)
  features = []
  entries.each do |entry|
    bioentry = FactoryGirl.create(:bioentry,
      :assembly => assembly,
      :name =>  entry[:name],
      :accession => entry[:locus],
      :seq_setup => { :length => entry[:length], :seq => entry[:seq] }
    )
    features<<FactoryGirl.create(:mrna_feature,
      :bioentry => bioentry,
      loc_setup: [ [1, entry[:length]] ],
      qualifier_setup: [ [:locus_qual, entry[:locus]] ]
    )
  end
  Biosql::Feature::Seqfeature.reindex_all_by_id(features.map(&:id))
  Ability.reset_cache
end

Given(/^I have "(.*?)" access to the assembly$/) do |role|
  assembly = Assembly.first
  assembly.should_not == nil
  user = FactoryGirl.create(:user)
  role = Role.find_or_create_by_name(role)
  user.roles << role
  user.groups << assembly.group
  visit '/users/sign_in'
  fill_in "user_login", :with => user.login
  fill_in "user_password", :with => user.password
  click_button "Sign in"
end

Given(/^I have "(.*?)" access to all assemblies$/) do |role|
  assemblies = Assembly.all
  assemblies.should_not == []
  user = FactoryGirl.create(:user)
  role = Role.find_or_create_by_name(role)
  user.roles << role
  assemblies.each do |assembly|
    user.groups << assembly.group
  end
  visit '/users/sign_in'
  fill_in "user_login", :with => user.login
  fill_in "user_password", :with => user.password
  click_button "Sign in"
end

When(/^I visit the genome listing$/) do
 visit(genomes_path)
end

When(/^I visit the transcriptome listing$/) do
 visit(transcriptomes_path)
end

Given(/^I delete all data from the assembly$/) do
  assembly = Assembly.first
  assembly.should_not == nil
  assembly.delete_all_data
end

Then(/^the assembly should have (\d+) sequence entries$/) do |arg1|
  assembly = Assembly.first
  assembly.should_not == nil
  assembly.bioentries.count.should == 0
end


