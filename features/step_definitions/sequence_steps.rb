Given /^there are (\d+) sequence entries$/ do |count|
  FactoryGirl.create_list(:bioentry, count.to_i)
end

When /^I visit the sequence list$/ do
  visit(bioentries_path)
end

Then(/^I should see the sequence viewer$/) do
  page.should have_content("Configuration")
  page.should have_content("Genome Sequence")
  page.should have_content("Dragmode: browse")
  page.should have_content("Position:")
end


