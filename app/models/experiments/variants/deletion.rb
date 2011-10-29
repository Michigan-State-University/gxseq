class Deletion < SequenceVariant
  def length
    ref.length
  end
  def html_header
    "<div style='color:darkred'>#{super}</div>"
  end
end