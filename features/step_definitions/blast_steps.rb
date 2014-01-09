Given /^there are the following Blast Databases:$/ do |table|
  # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    group = Group.find_by_name hash[:group]
    group.should_not == nil
    hash['group'] = group
    FactoryGirl.create(:blast_database,hash)
  end
end

When /^I visit the blast tool$/ do
  visit(new_blast_path)
end

Given(/^Seqfeature "(.*?)" has a blast result with definition "(.*?)"$/) do |locus, definition|
  features = Biosql::Feature::Seqfeature.find_all_by_locus_tag(locus)
  features.length.should == 1
  feature = features.first
  FactoryGirl.create(:blast_report,:hit_def => definition, :seqfeature => feature)
  Biosql::Feature::Seqfeature.reindex
end

Given(/^the test blast database exists$/) do
  FactoryGirl.create(:blast_database)
end

Given(/^I have access to the test blast db$/) do
  blast_db = BlastDatabase.first
  user = FactoryGirl.create(:user)
  user.groups << blast_db.group
  visit '/users/sign_in'
  fill_in "user_login", :with => user.login
  fill_in "user_password", :with => user.password
  click_button "Sign in"
end

When(/^I enter the test sequence$/) do
  fill_in "blast_sequence", :with => "tttgatttaaaattt"
end

When(/^I choose blast program "(.*?)"$/) do |program|
  page.select program, :from => "blast_program"
end

Then(/^I should see the blast alignment$/) do
  find('tr', :text => "lcl|1_0").should have_content("15")
  all('tr')[2].should have_content("Alignment")
  click_link '[Alignment]'
  find('tr', :text => "Identities",:match => :first).should have_content("15/15 (100%)")
  find('tr', :text => "Gaps",:match => :first).should have_content("0/15 ( 0%)")
end
