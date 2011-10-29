class Indel < SequenceVariant
  def length
    alt.length
  end
  def html_header
    "<div style='color:orange'>#{super}</div>"
  end
end