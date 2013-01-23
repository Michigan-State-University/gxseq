# Load settings.yml into APP_CONFIG constant
begin
  APP_CONFIG = YAML.load_file("#{::Rails.root.to_s}/config/settings.yml")[::Rails.env].symbolize_keys
rescue
 puts "Error reading settings file.\nCheck config/settings.yml.sample for more information"
end

# Set default accession_link for bioentries
# TODO: store settings in database, allow admin configuration
ACCESSION_LINK = "http://www.ncbi.nlm.nih.gov/sites/entrez?db=genome&cmd=search&term=" unless defined? ACCESSION_LINK

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
