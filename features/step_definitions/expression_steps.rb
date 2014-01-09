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
