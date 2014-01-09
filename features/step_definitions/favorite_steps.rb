Given /^"([^"]*)" user has (\d+) favorite seqfeatures$/ do |login, count|
  user = User.find_by_login(login)
  user.should_not == nil
  count.to_i.times do
    FactoryGirl.create(:favorite_seqfeature, :user => user)
  end
  Biosql::Feature::Seqfeature.reindex
  Ability.reset_cache
end

Given(/^"(.*?)" user has a favorite seqfeature with locus "(.*?)"$/) do |login, locus|
  user = User.find_by_login(login)
  user.should_not == nil
  seqfeature = FactoryGirl.create(:seqfeature, :qualifier_setup => [[:locus_qual,locus]])
  FactoryGirl.create(:favorite_seqfeature, :user => user, :item => seqfeature)
  Biosql::Feature::Seqfeature.reindex
  Ability.reset_cache
end

Given /^"([^"]*)" user has (\d+) favorite mrna seqfeatures$/ do |login, count|
  user = User.find_by_login(login)
  user.should_not == nil
  count.to_i.times do
    FactoryGirl.create(:favorite_mrna_seqfeature, :user => user)
  end
  Biosql::Feature::Seqfeature.reindex
  Ability.reset_cache
end

When /^I visit the user profile favorites tab for "([^"]*)"$/ do |login|
  user = User.find_by_login(login)
  user.should_not == nil
  visit(user_path(user,:fmt => :favorites))
end
