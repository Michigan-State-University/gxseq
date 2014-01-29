Given /^there are (\d+) sequence entries$/ do |count|
  FactoryGirl.create_list(:bioentry, count.to_i)
end

When /^I visit the sequence list$/ do
  visit(bioentries_path)
end

Given /^there is a Transcriptome with id (\d+) and the following sequence:$/ do |id, table|
  entries = table.hashes
  assembly = FactoryGirl.create(:transcriptome, :id => id)
  entries.each do |entry|
    bioentry = FactoryGirl.create(:bioentry,
      :assembly => assembly,
      :name =>  entry[:name],
      :accession => entry[:locus],
      :seq_setup => { :length => entry[:length], :seq => entry[:seq] }
    )
    FactoryGirl.create(:mrna_feature,
      :bioentry => bioentry,
      loc_setup: [ [1, entry[:length]] ],
      qualifier_setup: [ [:locus_qual, entry[:locus]] ]
    )
  end
  Biosql::Feature::Seqfeature.reindex
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