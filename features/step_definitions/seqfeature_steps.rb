When /^I visit the create gene page$/ do
  visit(new_gene_path)
end

When(/^I visit the gene details page$/) do
  gene = Biosql::Feature::Gene.first
  gene.should_not==nil
  visit(seqfeature_path(gene))
end

Given(/^I visit the gene coexpression page$/) do
  gene = Biosql::Feature::Gene.first
  gene.should_not==nil
  visit(seqfeature_path(gene, :fmt => 'coexpression'))
end

Given(/^I visit the gene coexpression page for "(.*?)"$/) do |locus|
  gene = Biosql::Feature::Gene.with_locus_tag(locus).first
  gene.should_not==nil
  visit(seqfeature_path(gene, :fmt => 'coexpression'))
end

# default walk through the create form
# assumes the first assembly and bioentry are selected
# seems very brittle and too large for one step
When(/^I create a new gene with (\d+) gene models$/) do |model_count|
  all('#assembly_id option')[1].select_option
  all('#bioentry_id option')[1].select_option
  fill_in "Locus tag", :with => 'Gene1'
  fill_in "Start pos", :with => '100'
  fill_in "End pos", :with => '1000'
  model_count.to_i.times do |count|
    within("fieldset#gene_model_", :match => :first) do
      # CDS
      click_link "Add CDS to Gene Model"
      within("div.gene_model_cds_qualifiers") do
        click_link "Add Field"
        select "locus_tag", :from => 'Term'
        fill_in "Value", :with => 'Gene1'
        click_link "Add Location"
        fill_in "Start pos", :with => '200'
        fill_in "End pos", :with => '900'
      end
      # mRNA
      click_link "Add mRNA to Gene Model"
      within("div.gene_model_mrna_qualifiers") do
        click_link "Add Field"
        select "locus_tag", :from => 'Term'
        fill_in "Value", :with => 'Gene1'
        click_link "Add Location"
        fill_in "Start pos", :with => '150'
        fill_in "End pos", :with => '950'
      end
    end
    # add another until last iteration
    if(count < (model_count.to_i - 1) )
      click_link "Add Gene Model"
    end
  end
  
  click_button "Create Gene"
end

Then(/^I should see a gene with (\d+) gene models$/) do |count|
  count = count.to_i
  if count > 1
    page.should have_content("This locus has #{count} gene models")
  end
  # title for gene and each model
  page.all("h1.pagetitle").count.should == count + 1
  page.should have_content("Gene Created Successfully")
end

Given(/^there is a public feature$/) do
  FactoryGirl.create(:public_feature)
end

Given(/^there is a public feature with locus "(.*?)"$/) do |locus|
  FactoryGirl.create(:public_feature, :qualifier_setup => [[:locus_qual,locus]])
end


Given(/^there are "(.*?)" public features$/) do |count|
  FactoryGirl.create(:public_assembly, :feature_setup => [[1,count]], :seq_count => 1)
end

Given(/^there are no public features$/) do
  # this is ugly
  Biosql::Feature::Seqfeature.includes(:bioentry => [:assembly => [:group, :samples => :group]])
    .where{(bioentry.assembly.group.name=='public') | (bioentry.assembly.samples.group.name=='public') }
    .count.should == 0
end

When(/^I visit the edit feature page$/) do
  visit(edit_seqfeature_path(Biosql::Feature::Seqfeature.first))
end

When(/^I add a "(.*?)" annotation of "(.*?)"$/) do |term_name, value|
  click_link "Add Field"
  select(term_name, :from => 'Term')
  fill_in "Value", :with => value
end

Then(/^I should see a new "(.*?)" annotation of "(.*?)"$/) do |term_name, term_value|
  page.should have_content("Updated successfully")
  parent = find('li label', :text => term_name).find(:xpath,"..")
  within parent do
    find('input').value.should == term_value
  end
end

Then(/^the history should show "(.*?)" "(.*?)"$/) do |value, action|
  click_link("History")
  find('tr', :text => value).should have_content(action)
end

Given(/^there is a "(.*?)" feature with locus "(.*?)"$/) do |type, locus|
  FactoryGirl.create(:seqfeature, :display_name => type, :qualifier_setup => [[:locus_qual,locus]])
end

Given(/^I have "(.*?)" access to the "(.*?)" feature with locus "(.*?)"$/) do |role_name, type, locus|
  feature = Biosql::Feature::Seqfeature.find_all_by_locus_tag(locus).where(:display_name  => type).first
  feature.should_not == nil
  user = FactoryGirl.create(:user)
  role = Role.find_or_create_by_name(role_name)
  user.roles << role
  user.groups << feature.bioentry.assembly.group
  visit '/users/sign_in'
  fill_in "user_login", :with => user.login
  fill_in "user_password", :with => user.password
  click_button "Sign in"
end

When(/^I visit the features list$/) do
  visit seqfeatures_path
end

Then(/^I should see a "(.*?)" feature with locus "(.*?)"$/) do |type, locus|
  find('tr', :text => locus).should have_content(type)
end

Given(/^the feature has the following sample counts and traits:$/) do |table|
  feature = Biosql::Feature::Seqfeature.first
  feature.should_not == nil
  assembly = feature.bioentry.assembly
  assembly.should_not == nil
  table.hashes.each do |hash|
    sample = FactoryGirl.create(:sample,
      :type => "RnaSeq",
      :name => hash.delete('name'),
      :assembly => assembly
    )
    FactoryGirl.create(
      :feature_count,
      :count => hash.delete('count'),
      :normalized_count => hash.delete('norm'),
      :sample => sample,
      :seqfeature => feature
    )
    hash.each do |key,val|
      unless(val.blank?)
        term = Biosql::Term.find_by_name_and_ontology_id(key,Biosql::Term.sample_ont_id)
        term ||= FactoryGirl.create(:term, :name => key, :ontology_id => Biosql::Term.sample_ont_id)
        FactoryGirl.create(:trait, :term => term, :value => val, :sample => sample)
      end
    end
  end
end

