When(/^I visit expression details of the feature$/) do
  feature = Biosql::Feature::Seqfeature.first
  feature.should_not == nil
  visit seqfeature_path(feature,:fmt => 'expression')
end

When(/^I visit json expression data for the feature grouped by "(.*?)"$/) do |trait_group|
  feature = Biosql::Feature::Seqfeature.first
  feature.should_not == nil
  if trait_group == 'None'
    t_id = nil
  else
    t_id = Biosql::Term.find_by_name_and_ontology_id(trait_group,Biosql::Term.sample_ont_id)
    t_id.should_not == nil
  end
  visit feature_counts_seqfeature_path(feature,:group_trait => t_id,:format => :json)
end

When(/^I visit expression data for the feature$/) do
  feature = Biosql::Feature::Seqfeature.first
  feature.should_not == nil
  visit feature_counts_seqfeature_path(feature,:format => :json)
end

Then(/^I should be able to group by sample traits (".+")$/) do |traits|
  page.should have_select 'trait_type_id', :options => traits.scan(/"([^"]+?)"/).flatten
end

When(/^I visit the expression tool$/) do
  visit expression_viewer_path
end

Given(/^the assembly has (\d+) expression samples?$/) do |count|
  assembly = Assembly.first
  assembly.should_not == nil
  FactoryGirl.create_list(:expression_sample, count.to_i, :assembly => assembly)
end

Given(/^the assembly has (\d+) expression samples? with values:$/) do |count,table|
  assembly = Assembly.first
  assembly.should_not == nil
  samples = FactoryGirl.create_list(:expression_sample, count.to_i, :assembly => assembly, :count_array => table.hashes)  
end

Given(/^the assembly "(.*?)" version "(.*?)" has (\d+) expression samples?$/) do |name, ver, count|
  assembly = Assembly.includes(:taxon => :scientific_name)
    .where{taxon.scientific_name.name==name}
    .where{version==my{ver}}.first
  assembly.should_not == nil
  FactoryGirl.create_list(:expression_sample, count.to_i, :assembly => assembly)
end

Then(/^I should( not)? see a coexpression link$/) do |negate|
  if(negate)
    find('#format_links').should_not have_content('Co-Expression')
  else
    find('#format_links').should have_content('Co-Expression')
  end
end