module ExpressionHelper
  #TODO: Test track id collection
  def stored_locus_link(hit,experiments)
    if (bioentry_id = Array(hit.stored(:bioentry_id)).first)
      link_to( Array(hit.stored(:locus_tag_text)).first, bioentry_path(bioentry_id,
        :tracks => [ :models_track, :generic_feature_track, experiments.collect{|e| e.tracks.map(&:id)} ].flatten,
        :pos => Array(hit.stored(:start_pos)).first
        )
      )
    end
  end

  def highlight_result(hit,field_name)
    if hit.highlight(field_name)
      text = hit.highlight(field_name).format {|fragment| "<b><u>#{fragment}</u></b>" }
    elsif hit.stored(field_name)
      text = Array(hit.stored(field_name)).join(',').html_safe
    else
      ''
    end
    if(Array(hit.stored(:favorite_user_ids)).include?(current_user.id) )
      text = "<b>#{text}</b>"
    end
    return text.try(:html_safe)
  end
end


