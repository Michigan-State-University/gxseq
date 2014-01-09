Given /^there is a group "([^"]*)"$/ do |group_name|
  Group.find_by_name(group_name) || FactoryGirl.create(:group,:name => group_name)
end

Given /^"([^"]*)" is a member of group "([^"]*)"$/ do |user_name, group_name|
  user = User.find_by_login(user_name)
  user.should_not == nil
  group = Group.find_by_name(group_name)
  group.should_not == nil
  group.users << user
  group.save
end

Given /^there are (\d+) sequence entries in group "([^"]*)"$/ do |count, group_name|
  group = Group.find_by_name(group_name)
  group.should_not == nil
  assembly = FactoryGirl.create(:assembly, :group => group)
  entries = FactoryGirl.create_list(:bioentry,count.to_i,:assembly => assembly)
  Biosql::Bioentry.reindex
  Ability.reset_cache
end

Given /^the public group exists/ do
  Group.find_by_name("public") || FactoryGirl.create(:group, :name => 'public')
end
