class SequenceVariant < ActiveRecord::Base
  belongs_to :experiment
  has_paper_trail
  scope :with_bioentry, lambda { |id|
        { :conditions => { :bioentry_id => id } }
      }
  def html_header
    "<b>#{self.class.name}</b><hr/>"
  end
  # #allow assignment to STI type from form
  # def attributes_protected_by_default
  #   super - [self.class.inheritance_column]
  # end
  
  #For conversion from SNP using IUB codes
  IUB_CODE =
  {
    'A' => ['A'],
    'C' => ['C'],
    'T' => ['T'],
    'G' => ['G'],
    'M' => ['A','C'], 
    'K' => ['G','T'], 
    'Y' => ['C','T'], 
    'R' => ['A','G'], 
    'W' => ['A','T'], 
    'S' => ['G','C'],   
    'D' => ['A','G','T'], 
    'B' => ['C','G','T'],
    'H' => ['A','C','T'],
    'V' => ['A','C','G'],
    'N' => ['A','C','G','T'] 
  }
  
  TO_IUB_CODE =
  {
     ['A'] => 'A',
     ['C'] => 'C',
     ['T'] => 'T',
     ['G'] => 'G',
     ['A','C'] => 'M', 
     ['G','T'] => 'K',
     ['C','T'] => 'Y', 
     ['A','G'] => 'R', 
     ['A','T'] => 'W', 
     ['G','C']   => 'S',
     ['A','G','T'] => 'D',
     ['C','G','T'] => 'B',
     ['A','C','T'] => 'H',
     ['A','C','G'] => 'V',
     ['A','C','G','T'] => 'N'
  }
end