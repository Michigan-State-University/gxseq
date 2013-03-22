class Admin::BlastRunsController < ApplicationController
  # GET /admin/blast_runs
  # GET /admin/blast_runs.xml
  def index
    @blast_runs = BlastRun.scoped

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @blast_runs }
    end
  end

  # GET /admin/blast_runs/1
  # GET /admin/blast_runs/1.xml
  def show
    @blast_run = BlastRun.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @blast_run }
    end
  end

  # GET /admin/blast_runs/new
  # GET /admin/blast_runs/new.xml
  def new
    @blast_run = BlastRun.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @blast_run }
    end
  end

  # GET /admin/blast_runs/1/edit
  def edit
    @blast_run = BlastRun.find(params[:id])
  end

  # POST /admin/blast_runs
  # POST /admin/blast_runs.xml
  def create
    @blast_run = BlastRun.new(params[:blast_run])

    respond_to do |format|
      if @blast_run.save
        format.html { redirect_to(@blast_run, :notice => 'Blast run was successfully created.') }
        format.xml  { render :xml => @blast_run, :status => :created, :location => @blast_run }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @blast_run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /admin/blast_runs/1
  # PUT /admin/blast_runs/1.xml
  def update
    @blast_run = BlastRun.find(params[:id])

    respond_to do |format|
      if @blast_run.update_attributes(params[:blast_run])
        format.html { redirect_to(@blast_run, :notice => 'Blast run was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @blast_run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/blast_runs/1
  # DELETE /admin/blast_runs/1.xml
  def destroy
    @blast_run = BlastRun.find(params[:id])
    @blast_run.destroy

    respond_to do |format|
      format.html { redirect_to(blast_runs_url) }
      format.xml  { head :ok }
    end
  end
end
