module ExpressionHelper

  def stored_locus_link(hit,experiments)
    bioentry_id = Array(hit.stored(:bioentry_id)).first
    link_to( Array(hit.stored(:locus_tag_text)).first, bioentry_path(bioentry_id,
      :tracks => [ :models_track, :generic_feature_track, experiments.collect{|e| e.tracks.with_bioentry(bioentry_id).first.id} ].flatten,
      :pos => Array(hit.stored(:start_pos)).first
      )
    )
  end

  def highlight_result(hit,field_name)
    if hit.highlight(field_name)
      text = hit.highlight(field_name).format {|fragment| "<b><u>#{fragment}</u></b>" }
    elsif hit.stored(field_name)
      text = Array(hit.stored(field_name)).join(',').html_safe
    elsif hit.stored(:id)
      text = hit.stored(:id).to_s
    end
    if(Array(hit.stored(:favorite_user_ids)).include?(current_user.id) )
      text = "<b>#{text}</b>"
    end
    return text.html_safe
  end
end


