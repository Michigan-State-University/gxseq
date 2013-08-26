class Admin::BlastDatabasesController < Admin::AdminController

  before_filter :find_blast_database, :only => [:show, :edit, :update, :destroy]
  autocomplete :taxon_name, :taxon_id, :full => true, :full_model => true,:class_name => 'biosql/taxon_name', :column_name => 'name'
  autocomplete :group, :id, :full => true, :column_name => 'name'
  skip_authorize_resource :only => :autocomplete_taxon_name_taxon_id
  # GET /blast_databases
  def index
    @blast_databases = BlastDatabase.scoped
    if(params[:q])
      @blast_databases = @blast_databases.where{(name =~ params[:q]) | (link_ref =~ params[:q])}
    end
  # index.html.erb
  end

  # GET /_blast_databases/1
  def show
  # show.html.erb
  end

  # GET /blast_databases/new
  def new
    @blast_database = BlastDatabase.new
  # new.html.erb
  end

  # GET /blast_databases/1/edit
  def edit
  end

  # POST /blast_databases
  def create
    @blast_database = BlastDatabase.new(params[:blast_database])

    respond_to do |wants|
      if @blast_database.save
        flash[:notice] = 'BlastDatabase was successfully created.'
        wants.html { redirect_to(admin_blast_databases_path) }
      else
        wants.html { render :action => "new" }
      end
    end
  end

  # PUT /blast_databases/1
  def update
    respond_to do |wants|
      if @blast_database.update_attributes(params[:blast_database])
        flash[:notice] = 'BlastDatabase was successfully updated.'
        wants.html { redirect_to(admin_blast_databases_path) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end

  # DELETE /blast_databases/1
  def destroy
    bd_name = @blast_database.name
    if((br_count = @blast_database.blast_runs.count) > 0)
      flash[:error] = "You must remove all #{br_count} blast runs before destroying #{bd_name}"
      redirect_to(admin_blast_databases_path)
    else
      @blast_database.destroy
      flash[:warning] = bd_name+' destroyed successfully.'
      redirect_to(admin_blast_databases_path)
    end
  end

  private
    def find_blast_database
      @blast_database = BlastDatabase.find(params[:id])
    end
    #
    # Returns a hash with three keys actually used by the Autocomplete jQuery-ui
    # Can be overriden to show whatever you like
    # Hash also includes a key/value pair for each method in extra_data
    #
    def json_for_autocomplete(items, method, extra_data=[])
      items.collect do |item|
        hash = {"id" => item.id.to_s, "label" => item.send(method), "value" => item.send(method)}
        extra_data.each do |datum|
          hash[datum] = item.send(datum)
        end if extra_data
        hash
      end
    end
end
