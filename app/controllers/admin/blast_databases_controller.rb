class Admin::BlastDatabasesController < Admin::AdminController

  before_filter :find_blast_database, :only => [:show, :edit, :update, :destroy]

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
    @blast_database.destroy

    respond_to do |wants|
      wants.html { redirect_to(blast_databases_url) }
    end
  end

  private
    def find_blast_database
      @blast_database = BlastDatabase.find(params[:id])
    end

end
