module CombosHelper
  def nested_links(sample)
    a_text=b_text=''
    if(sample.class == Combo)
      a_components = sample.a_components
      b_components = sample.b_components
      if(a_components.count>1)
        a_text="<b style='color:blue'>#{sample.a_op}</b>(#{a_components.collect{|c| nested_links(c.sample)}.join(", ")})"
      elsif(a_components.first)
        a_text="(#{nested_links(a_components.first.sample)})"
      end
      if(b_components.count>1)
        b_text="<b style='color:blue'>#{sample.b_op}</b>(#{b_components.collect{|c| nested_links(c.sample)}.join(", ")})"
      elsif(b_components.first)
        b_text="(#{nested_links(b_components.first.sample)})"
      end
      doc="<div>
        <div style='margin-left:1em'>#{a_text}</div>
          <div style='margin-left:1em'><b style='color:blue'>#{sample.mid_op}</b></div>
        <div style='margin-left:1em'>#{b_text}</div>
      </div>".html_safe
      return doc
    else
      link_to sample.display_name, sample, {:target => '_blank'}
    end
  end
end