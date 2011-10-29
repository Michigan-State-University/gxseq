class Insertion < SequenceVariant
  def length
    alt.length
  end
  def html_header
    "<div style='color:green'>#{super}</div>"
  end
end