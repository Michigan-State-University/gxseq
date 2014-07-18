# Load settings.yml into APP_CONFIG constant
begin
  APP_CONFIG = YAML.load_file("#{File.expand_path File.dirname(__FILE__)}/../settings.yml")[::Rails.env].symbolize_keys
  APP_CONFIG[:term_id_order]={}
  if APP_CONFIG[:default_term_order]
     APP_CONFIG[:default_term_order].each do |t,val|
       term = Biosql::Term.where{name==my{t}}.where{ontology_id.in my{Biosql::Term.annotation_ontologies}}.first
       APP_CONFIG[:term_id_order]["term_#{term.id}_order"]=val if term
     end
  end
rescue => e
 puts "Error reading settings file.\nCheck config/settings.yml.sample for more information \n\t**#{e}\n\n"
end

Squeel.configure do |config|
  # To load hash extensions (to allow for AND (&), OR (|), and NOT (-) against
  # hashes of conditions)
  config.load_core_extensions :hash

  # To load symbol extensions (for a subset of the old MetaWhere functionality,
  # via ARel predicate methods on Symbols: :name.matches, etc)
  # config.load_core_extensions :symbol

  # To load both hash and symbol extensions
  # config.load_core_extensions :hash, :symbol
end
