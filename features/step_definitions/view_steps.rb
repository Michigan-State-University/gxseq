Then /^I should see (\d+) rows in the table$/ do |count|
  all('table tr').count.should == count.to_i
end

Then /^the "([^"]*)" drop-down should contain the options:$/ do |id,table|
  page.should have_select(id, :options => table.raw[0])
end

Then /^I should see "([^"]*)" in column (\d+)$/ do |text, col|
  first("table tr > td:nth-child(#{col})").should have_text(text)
end

Then /^I should not see "([^"]*)"$/ do |text|
  page.should_not have_content(text)
end

Then /^Wait for keypress$/ do
  STDIN.getc 
end

When(/I save the changes/) do
  click_button 'Update'
end

When(/^I submit the form$/) do
  click_button 'Submit'
end
Then /I should be denied/ do
  page.should have_content("Access Denied")
  if(@current_user)
    current_path.should == user_path(@current_user)
  else
    current_path.should == new_user_session_path
  end
end