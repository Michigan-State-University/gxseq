module ApplicationHelper
  # Hash of items for top navigation links
  # Each key has an array of link, [matching controller symbols]
  def top_navbar_items
    {
      :home => [root_path,[:home]],
      :sequence => [root_path,[:bioentries]],
      :genes => [root_path,[:genes]],
      :experiments => [root_path,[:experiments, :chip_chips, :chip_seqs, :synthetics, :variants]],
      :tools => [root_path,[:tools]],
      :help => [root_path,[:documentation]]
    }
  end
  # return top nav bar html
  # set the active class for any items matching the controller name
  def application_top_navbar_items
    content_tag( :ul, :id => "top-navigation") do
      top_navbar_items.collect{ |k,v|
        content_tag :li, link_to(k.to_s.capitalize,v[0], :class => ('active' if v[1].include?(params[:controller].to_sym)) ), 
      }.join.html_safe +
      (current_user.is_admin? ? content_tag(:li, link_to("Admin", admin_root_path, :class => ('active' if params[:controller]=~/^admin/))) : '')
    end
  end
  
  # TODO possible refactor
  def sort_link(title, column, options = {})
    condition = options[:unless] if options.has_key?(:unless)
    tooltip = options.delete(:tooltip) if options.has_key?(:tooltip)
    sort_dir = params[:d] == 'up' ? 'down' : 'up'
    link_to_unless condition, "#{title}<span>#{tooltip}</span>".html_safe, request.parameters.merge({:c => column, :d => sort_dir}), options
  end
end
