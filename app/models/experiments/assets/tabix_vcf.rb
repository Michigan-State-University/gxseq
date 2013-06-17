# == Schema Information
#
# Table name: assets
#
#  created_at        :datetime
#  data_content_type :string(255)
#  data_file_name    :string(255)
#  data_file_size    :integer
#  data_updated_at   :datetime
#  experiment_id     :integer
#  id                :integer          not null, primary key
#  state             :string(255)      default("pending")
#  type              :string(255)
#  updated_at        :datetime
#

class TabixVcf < Tabix
  def load
    update_attribute(:state, "loading")
    create_index
    update_attribute(:state, "complete")
  end
  
  def create_index
    super({:s => 1, :b => 2, :e => 2, :c => '#', :S => 0})
  end
  
  def sequence
    self.groups
  end
  
  def header_line
    header.split("\n").last
  end
  
  def samples
    header_line.split("\t")[9..-1]
  end
  
  def is_match?(line,sample_idx)
    if(sample_idx)
      gt = line.split("\t")[9+sample_idx].split(":")[0]
      return true if ["0/0","0|0","./.",".|."].include? gt
    end
    return true if line.split("\t")[4] == '.'
    return false
  end
  
  def get_data(seq,start,stop,opts={})
    return [] if seq.blank?
    t = Time.now
    # run the raw parent
    return super(seq,start,stop,opts) if opts[:raw]
    
    sample = opts[:sample]    
    only_variants = opts[:only_variants]
    
    # find sample index
    if(sample && !sample.blank?)
      return [] unless sample_idx = samples.index(sample)
    else
      sample = samples.first
      sample_idx = 0
    end
    # setup skip function
    if(only_variants)
      opts[:skip_func] = lambda do |line|
        is_match?(line,sample_idx)
      end
    end
    # setup parse function
    opts[:user_func] = lambda do |string|
      begin
        v1 = {}
        data = string.split("\t")
        v1[:allele]=1
        v1[:pos]=data[1].to_i
        v1[:dbid]=data[2]
        v1[:ref]=data[3]
        v1[:alt]=data[4]
        v1[:qual]=data[5].to_i
        v1[:id]="1_#{data[1]}_#{data[3]}_#{data[4]}"
        # decide variant type
        if v1[:ref].length == 1
          if v1[:alt].length == 1
            v1[:type] = (v1[:alt]=='.' ? 'match' : 'snp')
          else
            v1[:type] = 'insertion'
          end
        else
          if v1[:ref].length <= v1[:alt].length
            v1[:type] = 'indel'
          else
            v1[:type] = 'deletion'
          end
        end
        
        if sample
          # get gt
          gt = data[9+sample_idx].split(":")[0]
          # create second allele
          v2 = v1.clone
          v2[:allele]=2
          v2[:id]="2_#{data[1]}_#{data[3]}_#{data[4]}"
          # check gt for zygosity
          if gt[0]=="0"
            v1[:type]='match'
          end
          if gt[2]=="0"
            v2[:type]='match'
          end
        else
          v2=nil
        end
        
        return [v1,v2]
      rescue
        return nil
      end
    end
    # Run the loop
    (super(seq,start,stop,opts)).flatten.compact
  end
  
end
