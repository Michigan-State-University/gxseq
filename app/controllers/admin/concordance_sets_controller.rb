class Admin::ConcordanceSetsController < Admin::AdminController
  before_filter :find_set, :only => [:edit,:update]
  def index
    params[:c]||="taxon_name.name"
    order_d = params[:d]=='up' ? 'asc' : 'desc'
    @concordance_sets = ConcordanceSet.includes(:assembly => [:taxon => :scientific_name])
      .order("#{params[:c]} #{order_d}")
  end
  
  def new
    @concordance_set = ConcordanceSet.new
  end
  
  def create
    @concordance_set = ConcordanceSet.new(params[:concordance_set])
    if(@concordance_set.valid?)
      ConcordanceSet.transaction do
        @concordance_set.save
        @concordance_set.assembly.bioentries.each do |entry|
          ConcordanceItem.fast_insert({
            :concordance_set_id => @concordance_set.id,
            :bioentry_id => entry.bioentry_id,
            :reference_name => entry.accession
          }
          )
        end
      end
      redirect_to edit_admin_concordance_set_url(@concordance_set)
    else
      render :edit, @concordance_set, :error => "Could not save concordance"
    end
  end
  
  def edit
  end
  
  def update
    if @concordance_set.update_attributes(params[:concordance_set])
      redirect_to edit_admin_concordance_set_url(@concordance_set)
    else
      render :edit, @concordance_set, :error => "Could not save concordance"
    end
  end
  
  protected
  def find_set
    @concordance_set = ConcordanceSet.find(params[:id])
    @concordance_items = @concordance_set.concordance_items.paginate(:page => (params[:page]||1))
  end
end