Then /^I should see (\d+) rows in the table$/ do |count|
  all('table tr').count.should == count.to_i
end

Then /^the "([^"]*)" drop-down should contain the options:$/ do |id,table|
  page.should have_select(id, :options => table.raw[0])
end

Then /^I should see "([^"]*)" in column (\d+)$/ do |text, col|
  first("table tr > td:nth-child(#{col})").should have_text(text)
end

Then /^I should see "([^"]*)" in header column (\d+)$/ do |text, col|
  first("table thead > th:nth-child(#{col})").should have_text(text)
end

Then /^I should see "([^"]*)" in table "([^"]*)" header col (\d+)$/ do |text, css_class, col|
  thead=page.first(".#{css_class} thead")
  thead.all('th')[col.to_i-1].should have_text(text)
end

Then /^I should see "([^"]*)" in table "([^"]*)" row (\d+) col (\d+)$/ do |text, css_class, row, col|
  tr=page.all(".#{css_class} tr")[row.to_i-1]
  tr.all('td')[col.to_i-1].should have_text(text)
end

Then /^I should see "([^"]*)" in slickgrid row (\d+) col (\d+)$/ do |text, row, col|
  tr=page.all(".slick-row")[row.to_i-1]
  tr.all('.slick-cell')[col.to_i-1].should have_text(text)
end

Then /^I should not see "([^"]*)"$/ do |text|
  page.should_not have_content(text)
end

Then /^I should see "([^"]*)"$/ do |text|
  page.should have_content(text)
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

Then /^I should see (\d+) "([^"]*)" checkbox/ do |count, id|
  page.should have_field(id,:count => count.to_i)
end

When(/^I select option "([^"]*)" from "([^"]*)"$/) do |option,select|
  select(option, :from => select)
end

When(/^I check "([^"]*)" (\d+)$/) do |name,idx|
  all("input[type='checkbox'][name='"+name+"']")[idx.to_i-1].set(true)
end

When(/^I click "(.*?)"$/) do |text|
  click_link text
end
