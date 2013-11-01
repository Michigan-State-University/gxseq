module ApplicationHelper
  # Hash of items for top navigation links
  # Each key has an array of link, [matching controller symbols]
  def top_navbar_items
    {
      #:home => [root_path,[:home,:'devise/sessions',:user]],
      :sequence => [genomes_path,[:bioentries,:genomes,:transcriptomes]],
      :features => [seqfeatures_path,[:genes,:seqfeatures]],
      :samples => [samples_path,[:samples, :chip_chips, :chip_seqs, :synthetics, :variants]],
      :tools => [tools_path,[:tools,:expression,:blast_runs]],
      :help => [faq_path,[:help]]
    }
  end
  # return top nav bar html
  # set the active class for any items matching the controller name
  def application_top_navbar_items
    content_tag( :ul, :id => "top-navigation") do
      top_navbar_items.collect{ |k,v|
        content_tag :li, link_to(k.to_s.capitalize,v[0], :class => ('active' if v[1].find{|key| params[:controller] =~ /#{key}/}) )
      }.join.html_safe +
      ((current_user && current_user.is_admin?) ? content_tag(:li, link_to("Admin", admin_root_path, :class => ('active' if params[:controller]=~/^admin/))) : '')
    end
  end

  # Renders a clickable sorting link with arrows
  def sort_link(title, column, options = {})
    condition = options[:unless] if options.has_key?(:unless)
    tooltip = options.delete(:tooltip) if options.has_key?(:tooltip)
    sort_dir = params[:d] == 'up' ? 'down' : 'up'
    link_to_unless condition, "#{params[:c].to_s==column.to_s ? (params[:d]=='up' ? image_tag('sort_up.png', :size => '11x11') : image_tag('sort_down.png', :size => '11x11')) : image_tag('sort_off.png', :size => '10x10')}#{title}<span>#{tooltip}</span>".html_safe, request.parameters.merge({:c => column, :d => sort_dir}), options
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
      <canvas id='canvas_number_line_#{id}' width='#{width+50}px' height='#{height}'>
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
              text += "context.fillText('#{start+(x*per_pixel).floor}',#{x},#{(height/2)+h+fontheight});"
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

  def sliced_toggle(small_text,full_text,dom_id)
    full_text = small_text if full_text.nil?
    [
      (
        content_tag(:div,
          content_tag(:div, '[+]',
            :style => 'float:left;cursor:pointer;color:#648FAB;',
            :id => "toggle_#{dom_id}_open",
            :onclick => "$('slice_#{dom_id}_full').toggle();
              $('slice_#{dom_id}_short').toggle();
              $('toggle_#{dom_id}_open').toggle();
              $('toggle_#{dom_id}_close').toggle();")+'&nbsp;'.html_safe+small_text,
          :style => "text-wrap:none;text-align:left;overflow:hidden;height:1.2em",
          :id => "slice_#{dom_id}_short")
      ),
      content_tag(:div,
        content_tag(:div,'[-]',
          :id =>"toggle_#{dom_id}_close",
          :style =>'float:left;cursor:pointer;display:none;color:#648FAB',
          :onclick =>" $('slice_#{dom_id}_full').toggle();
          $('slice_#{dom_id}_short').toggle();
          $('toggle_#{dom_id}_open').toggle();
          $('toggle_#{dom_id}_close').toggle();")+'&nbsp;'.html_safe+full_text.try(:html_safe),
        :id => "slice_#{dom_id}_full",
        :style => "display:none;text-align:left")
    ].join.html_safe
  end
  
  def feature_format_link(feature,fmt,fmt_label,current_fmt)
    if current_fmt==fmt
      content_tag(:div, fmt_label,
        :style => "display:inline;padding:.5em;padding-bottom:.4em;border: 2px solid #C3C4C7;border-bottom: 2px solid white;margin-right:-.25em;margin-left:-.25em"
		  )
		else
		  content_tag(:div, link_to( fmt_label, seqfeature_path(feature, :fmt => fmt)),
        :style => "display:inline;padding:.5em;padding-top:.2em;border-right: 1px solid #C3C4C7;border-left: 1px solid #C3C4C7;margin-right:-.25em;margin-left:-.25em"
		  )
		end
  end
end
