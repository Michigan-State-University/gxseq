Given(/^there is an assembly$/) do
  assembly = FactoryGirl.create(:assembly)
end

Given(/^there are (\d+) "(.*?)" assemblies$/) do |count,type|
  FactoryGirl.create_list(:assembly, count.to_i, :type => type)
end

Given(/^the assembly has "(.*?)" features?$/) do |count|
  assembly = Assembly.first
  assembly.should_not == nil
  bioentry = FactoryGirl.create(:bioentry,:assembly => assembly)
  FactoryGirl.create_list(:seqfeature,count.to_i,:bioentry => bioentry)
end

Given(/^the assembly has (\d+) genes?$/) do |count|
  assembly = Assembly.first
  assembly.should_not == nil
  bioentry = FactoryGirl.create(:bioentry,:assembly => assembly)
  FactoryGirl.create_list(:gene_feature,count.to_i,:bioentry => bioentry)
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

When(/^I visit the genome listing$/) do
 visit(genomes_path)
end

When(/^I visit the transcriptome listing$/) do
 visit(transcriptomes_path)
end


