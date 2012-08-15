module ApplicationHelper
  # Hash of items for top navigation links
  # Each key has an array of link, [matching controller symbols]
  def top_navbar_items
    {
      :home => [root_path,[:home,:'devise/sessions']],
      :sequence => [bioentries_path,[:bioentries]],
      :features => [genes_path,[:genes,:seqfeatures]],
      :experiments => [experiments_path,[:experiments, :chip_chips, :chip_seqs, :synthetics, :variants]],
      :tools => [tools_path,[:tools]],
      :help => [help_path,[:help]]
    }
  end
  # return top nav bar html
  # set the active class for any items matching the controller name
  def application_top_navbar_items
    content_tag( :ul, :id => "top-navigation") do
      top_navbar_items.collect{ |k,v|
        content_tag :li, link_to(k.to_s.capitalize,v[0], :class => ('active' if v[1].include?(params[:controller].to_sym)) ),
      }.join.html_safe +
      ((current_user && current_user.is_admin?) ? content_tag(:li, link_to("Admin", admin_root_path, :class => ('active' if params[:controller]=~/^admin/))) : '')
    end
  end
  
  # TODO possible refactor
  def sort_link(title, column, options = {})
    condition = options[:unless] if options.has_key?(:unless)
    tooltip = options.delete(:tooltip) if options.has_key?(:tooltip)
    sort_dir = params[:d] == 'up' ? 'down' : 'up'
    link_to_unless condition, "#{title}<span>#{tooltip}</span>".html_safe, request.parameters.merge({:c => column, :d => sort_dir}), options
  end
  
  # Helper for rendering Sequence in View
  def formatted_sequence(seq,hsh = {})
    seq.to_formatted(hsh).html_safe
  end
  
  # canvas 2d number line
  def number_line(start, width, options={})
    #use js 2d canvas to draw a number line
    height = options[:height] || 50
    tickheight = options[:tickheight] || 4
    fontheight = options[:fontheight] || 10
    per_pixel = options[:per_pixel] || 1
    id = options[:id] || "number_line_#{start}"
    line = "
      <canvas id='canvas_number_line_#{id}' width='#{width}px' height='#{height}'>
      </canvas>
      <script type='text/javascript'>
        var context = $('canvas_number_line_#{id}').getContext('2d');
        context.textAlign='center';
        context.font='bold #{fontheight}px arial,sans-serif'
        context.fillRect(#{0},#{(height/2)-1},#{width}, 2)       
        #{ text = ""
          0.step(width,10) {|x|
            if(x.divmod(100)[1]==0)
              h = tickheight*2
              text += "context.fillText('#{start+(x*per_pixel)}',#{x},#{(height/2)+h+fontheight});"
            else
              h = tickheight
            end
            puts h;
            text += "context.fillRect(#{x},#{(height/2)-(h)},1,#{h*2});"
          }
          text
        }
        
      </script>
    "
    return line.html_safe
  end
  
  # dynamic links for nested form items
  def link_to_remove_fields(name, f,options={})
    if f.object.new_record?
      js = "remove_fields(this)"
    else
      object_name = f.object.respond_to?(:name) ? f.object.name : f.object.class.name.underscore.humanize
      js = "if(confirm('Are you sure you want to remove this #{object_name}?\\n\\nThe field will be removed from view and submitting the form will delete it permanently.')){remove_fields(this)}"
    end
    "#{f.hidden_field(:_destroy) unless f.object.new_record?} #{link_to_function(name,js,options)}".html_safe
  end

  def link_to_add_fields(name, f, association, options={})
    new_object = f.object.class.reflect_on_association(association).klass.new
    partial = options[:partial] || association.to_s.singularize + "_fields"
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(partial, {:f => builder}.merge(options[:locals]||{}) )
    end
      content_tag(:div,link_to_function(name, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\",'#{options[:render]}')", options), :class => "new-fields")
  end
  
  def link_to_show_deleted(object, association, options={})
    return if object.new_record? || object.versions.nil?    
  end
  
  # Add title for all alt declarations
  def image_tag(location, options={})
    options[:title] ||= options[:alt]
    super(location, options)
  end
end
