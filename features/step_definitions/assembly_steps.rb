Given(/^there is an assembly$/) do
  assembly = FactoryGirl.create(:assembly)
end

Given(/^the assembly has "(.*?)" feature$/) do |count|
  assembly = Assembly.first
  assembly.should_not == nil
  bioentry = FactoryGirl.create(:bioentry,:assembly => assembly)
  FactoryGirl.create_list(:seqfeature,count.to_i,:bioentry => bioentry)
end

Given(/^the assembly has (\d+) sequence entries/) do |count|
  # add bioentry because assembly needs at least one sequence
  assembly = Assembly.first
  assembly.should_not == nil
  FactoryGirl.create_list(:bioentry,count.to_i,:assembly => assembly)
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