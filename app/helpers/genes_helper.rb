module GenesHelper
  def codon_map(gene,start,width=900,options={})
    height=options[:height] || 50
    return unless gene.kind_of?(Gene)
    if(gene.locations.first.strand)
      gene_start = gene.locations.first.start_pos-start
      gene_end = gene.locations.first.end_pos-start
    else
      gene_end = gene.locations.first.start_pos-start
      gene_start = gene.locations.first.end_pos-start
    end     
    html = ""
    html+=image_tag("models/green.gif", :size => "#{4}x20", :style => "position:absolute;left:#{gene_start}px;top:0px")
    html+=image_tag("models/red.gif", :size => "#{4}x20", :style => "position:absolute;left:#{gene_end}px;top:0px")
    gene.possible_starts.each do |s|
      next if(s==gene_start)
      html+=link_to(
        image_tag("models/purple.gif", 
        :size => "#{3}x20", 
        :title => "#{start+s}", 
        :style => "position:absolute;left:#{s}px;top:25px"),gene, 
        :method => :delete, 
        :confirm => "Are you sure you want to change this gene's start codon to position:#{s}?"
      )
    end
    return html
  end
  # 
  # def cleanup_sqv_ids(hash)
  #   "qualifiers[#{hash.first[0]}][#{hash.first[1].split(',').join('_')}]"
  # end
  
  def text_area_size(rows,str)
    max = (str.size > 250 ? 250 : str.size)
    cols = ((max / 25.0).round + 2).to_s
    "#{rows}x#{cols}"
  end
end