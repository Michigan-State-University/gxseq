module Exp
  module HasPeaks    
    # When included extend class with AutoMethods
    def self.included(base)
      base.extend(AutoMethods)
    end    
    # Instance methods added to all experiments
    def has_peaks?
      false
    end    
    # class methods to be automatically extended
    module AutoMethods
      def has_peaks
        # some validation
        unless attribute_method?(:big_wig)
          raise "Class must have a big_wig asset to have peaks"
        end
        # Now we include the instance methods
        send :include, InstanceMethods
        # And setup other class methods
        has_many :peaks, :foreign_key => "experiment_id"
      end
    end  
    # instance methods added when auto_method is called
    module InstanceMethods
      # boolean flag
      def has_peaks?
        true
      end      
      # computes peaks for this experiment.
      # - :opts => Options passed on to peak finder. See {BigWig#extract_peaks}
      def compute_peaks(opts={})
        self.update_attribute(:state,"computing")
        opts[:remove]||=false
        bioentries_experiments.each do |be|
          if(opts[:remove] && self.peaks.with_bioentry(be.bioentry_id).size > 0)
            puts "Removing stored peaks for #{be.sequence_name}"
            self.peaks.with_bioentry(be.bioentry_id).destroy_all
          end
          puts "Computing peaks for #{be.sequence_name}"
          new_peaks = extract_peaks(be.sequence_name,opts)
          add_peaks(be.bioentry_id, new_peaks)
        end
      
        self.update_attribute(:state,"ready")
        puts "Done Computing peaks #{Time.now}"
        return self.peaks.count
      end
      
      protected
      # extract peaks from the underlying asset (big_wig)
      # - :chrom => sequence_name in datafile
      # - :opts  => algorithm options. See compute_peaks
      def extract_peaks(chrom, opts)
        begin
          big_wig.extract_peaks(chrom, opts)
        rescue
          e = "**Error extracting peak information:\n#{$!}"
          puts e
          logger.info "\n\n#{e}\n\n"
        end
      end    
      # Persist an array of peaks from a single sequence
      # - :bioentry_id => sequence id the peaks belong to
      def add_peaks(bioentry_id, data)
        #set peaks to the values in array data
        #format: [start,end,value,pos]
        puts "saving #{data.size} peaks"
        return false if !data.kind_of?(Array)
        bc=Bioentry.find(bioentry_id).length
        begin
          Experiment.transaction do
            data.each do |d|
              unless (d.size == 4 && d[0].kind_of?(Integer) && d[1].kind_of?(Integer) && d[2].respond_to?("to_f") && d[3].kind_of?(Integer))
                e= "Error invalid format #{d.inspect}";puts e;logger.info "\n\n#{e}\n\n";next
              end
              unless d[0]<d[1]
                e= "Error start > end";puts e;logger.info "\n\n#{e}\n\n";next
              end
              unless (d[0]>0 && d[3] < bc) && (d[0]<=d[3] &&d[3]<=d[1])
                e= "Error peak out of bounds";puts e;logger.info "\n\n#{e}\n\n";next
              end
              p = self.peaks.build(
              :start_pos => d[0],
              :end_pos => d[1],
              :val => d[2],
              :pos => d[3],
              :bioentry_id => bioentry_id
              )
              if(p.valid?)
                p.save!
              else
                e= "invalid peak:#{p.errors}";puts e;logger.info "\n\n#{e}\n\n";next
              end
            end
          end
        rescue
          e = "**Error loading peak data:\n#{$!}"
          puts e;logger.info "\n\n#{e}\n\n"
          return false
        end
      end
    end
  end
end