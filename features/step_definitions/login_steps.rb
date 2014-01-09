Given /^I am signed in as "([^"]*)"$/ do |login|
  if page.has_css?('a', :text => 'Log Out')
    click_link 'Log Out'
  end
  user = FactoryGirl.create(:user, :login => login)
  visit '/users/sign_in'
  fill_in "user_login", :with => user.login
  fill_in "user_password", :with => user.password
  click_button "Sign in"
  current_path.should_not == new_user_session_path
  @current_user = user
end

Given /^I am signed in with role "([^"]*)"$/ do |rolename|
  if page.has_css?('a', :text => 'Log Out')
    click_link 'Log Out'
  end
  user = FactoryGirl.create(:user)
  visit '/users/sign_in'
  fill_in "user_login", :with => user.login
  fill_in "user_password", :with => user.password
  click_button "Sign in"
  current_path.should_not == new_user_session_path
  role = Role.find_or_create_by_name(rolename)
  role.should_not == nil
  user.roles << role
  user.has_role?(rolename).should_not==nil?
  @current_user = user
end

Given /^I am not signed in$/ do
  if page.has_css?('a', :text => 'Log Out')
    click_link 'Log Out'
  end
  @current_user = nil
end