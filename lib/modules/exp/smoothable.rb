module Exp
  module Smoothable
    # This will be called below
    def self.included(base)
      base.extend(AutoMethods)
    end    
    # Instance methods added to all experiments
    def smoothable?
      false
    end    
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
      # boolean flag
      def smoothable?
        true
      end
      # duplicates self and converts big_wig to smoothed big wig
      # - :exp_hsh => options for the new experiment. See {Experiment} class
      # - :smooth_hsh => options for the smoothing process. See {BigWig#get_smoothed_data}
      def create_smoothed_experiment(exp_hsh={}, smooth_hsh={})
        puts "---Creating new Smoothed experiment #{smooth_hsh.inspect} #{Time.now}"
        begin
          ChipSeq.transaction do
            new_exp = self.clone(exp_hsh)
            if(new_exp.valid?)
              smooth_hsh[:filename]||=new_exp.name.gsub(' ','_').downcase
              f = self.big_wig.get_smoothed_data(smooth_hsh)
              new_exp.assets << Asset.new(:type => "BigWig",:data => f)
              new_exp.save!
              puts "Done creating new smoothed experiment: #{exp_hsh[:name]} #{Time.now}"
            else
              puts "Smoothing error: Invalid experiment received #{Time.now}"
            end
          end
        rescue Exception => e
          puts "Error creating smoothed bigwig\n#{$!}\n#{e.backtrace}\n"
        end
      end      
    end    
  end
end
Experiment.send :include, Exp::Smoothable