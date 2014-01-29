module Smoothable
  # This will be called below
  def self.included(base)
    base.extend(AutoMethods)
  end    
  # Instance methods added to all samples
  
  # class methods to be automatically extended
  module AutoMethods
    def smoothable
      # some validation
      unless attribute_method?(:big_wig)
        raise "Class must have a big_wig asset to have peaks"
      end
      send :include, InstanceMethods
    end
  end  
  # instance methods added when auto_method is called
  module InstanceMethods
    # duplicates self and converts big_wig to smoothed big wig
    # - :sample_hsh => options for the new sample. See {Sample} class
    # - :smooth_hsh => options for the smoothing process. See {BigWig#get_smoothed_data}
    def create_smoothed_sample(sample_hsh={}, smooth_hsh={})
      puts "---Creating new Smoothed sample #{smooth_hsh.inspect} #{Time.now}"
      begin
        Sample.transaction do
          new_sample = self.clone(sample_hsh)
          smooth_hsh[:filename]||=new_sample.name.gsub(' ','_').downcase
          f = self.big_wig.get_smoothed_data(smooth_hsh)
          new_sample.assets.build(:type => "BigWig",:data => f)
          if(new_sample.valid?)
            new_sample.save!
            puts "Done creating new smoothed sample: #{sample_hsh[:name]} #{Time.now}"
          else
            puts "Smoothing error: Invalid sample received #{Time.now}"
          end
        end
      rescue Exception => e
        puts "Error creating smoothed bigwig\n#{$!}\n#{e.backtrace}\n"
      end
    end      
  end    
end
