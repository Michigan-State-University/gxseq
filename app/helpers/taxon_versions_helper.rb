module TaxonVersionsHelper
  def remote_search(taxon_version_id, url,div_id,search_string="Search...")
    content_tag(:div,"",:style => "float:left",:id => div_id, :'data-item' => taxon_version_id, :'data-url' => url, :class => 'remote_search')
  end
end
