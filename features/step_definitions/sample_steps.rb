Given(/^There is a sample$/) do
  FactoryGirl.create(:sample)
end

Given(/^the sample has trait "(.*?)" with value "(.*?)"$/) do |trait_name, trait_value|
  sample = Sample.first
  term = Biosql::Term.find_by_name_and_ontology_id(trait_name,Biosql::Term.sample_ont_id)
  FactoryGirl.create(:trait, :sample => sample,:value => trait_value,:term => term)
end

Given(/^I have "(.*?)" access to the sample$/) do |role_name|
  sample = Sample.first
  sample.should_not == nil
  user = FactoryGirl.create(:user)
  role = Role.find_or_create_by_name(role_name)
  user.roles << role
  user.groups << sample.group
  visit '/users/sign_in'
  fill_in "user_login", :with => user.login
  fill_in "user_password", :with => user.password
  click_button "Sign in"
end

When(/^I view the sample update page$/) do
  sample = Sample.first
  visit(polymorphic_url([:edit,sample], :routing_type => :path))
end

When(/^I view the sample listing$/) do
  sample = Sample.first
  visit(polymorphic_url(sample.class.new, :routing_type => :path))
end

When(/^I choose to manage trait types$/) do
  page.should have_content("Manage Selections")
  click_link("Manage Selections")
end

When(/^I add a trait "(.*?)" with definition "(.*?)"$/) do |trait_name, definition|
    within("form") do
      fill_in "Name", :with => trait_name
      fill_in "Definition", :with => definition
      click_button "Add"
    end
end

Then(/^I should see a trait "(.*?)" with definition "(.*?)"$/) do |trait_name, definition|
  find('tr', :text => trait_name).should have_content(definition)
end

Given(/^there is a trait "(.*?)"$/) do |name|
  FactoryGirl.create(:term, :ontology_id => Biosql::Term.sample_ont_id,:name => name)
end

When(/^I add a new trait "(.*?)" with value "(.*?)"$/) do |trait_name, trait_value|
  within "#sample_traits" do
    click_link "Add Trait"
    within ".nested-fields", :match => :first do
      select trait_name, :from => "Type"
      fill_in "Value", :with => trait_value
    end
  end
end

Then(/^I should see trait "(.*?)" with value "(.*?)"$/) do |trait_name, trait_value|
  if page.has_css?('p', :text => trait_name)
    find('p', :text => trait_name).should have_content(trait_value)
  else
    find('td', :text => trait_name).should have_content(trait_value)
  end
end