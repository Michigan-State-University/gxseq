class Admin::JobsController < Admin::AdminController
  def index
    sort_col = params[:c]||'created_at'
    if params[:d] && (params[:d].upcase == 'UP' || params[:d].upcase == 'ASC')
      sort_dir = 'ASC'
    else
      sort_dir = 'DESC'
    end
    params[:status]||='incomplete'
    @jobs = Delayed::Job.scoped
    if(params[:queue])
      @jobs = @jobs.where(:queue => params[:queue])
    end
    unless(params[:user].blank?)
      @jobs = @jobs.where(:user_id => params[:user])
    end
    unless params[:time].blank?
      @jobs = @jobs.where("created_at > '#{(Time.now - params[:time].to_i.hours).to_date}'")
    end
    case params[:status]      
    when 'complete'
      @jobs = @jobs.where("completed_at is not null")
    when 'incomplete'
      @jobs = @jobs.where("completed_at is null")
    when 'failed'
      @jobs = @jobs.where("failed_at is not null")
    when 'pending'
      @jobs = @jobs.where('completed_at is null AND failed_at is null')
    when 'all'
    end
    
    @jobs = @jobs.includes(:user).order("#{sort_col} #{sort_dir}")
    @jobs = @jobs.paginate(:page => params[:page])
    
    @job_users = Delayed::Job.select('distinct user_id').where('user_id is not null').collect{|d| User.find(d.user_id) rescue nil}.compact.sort{|user1,user2|user1.display_name<=>user2.display_name}
  end
  
  def show
    @job = Delayed::Job.find(params[:id])
  end
  
  def destroy
    @job = Delayed::Job.find(params[:id])
    @job.destroy(true) if @job
    flash[:warning] = "The job has been destroyed"
    redirect_to admin_jobs_path
  end
  
  def retry
    @job = Delayed::Job.find(params[:id])
    @job.locked_at = @job.locked_by = @job.completed_at = @job.failed_at = nil
    @job.attempts+=1
    @job.save
    redirect_to admin_jobs_path
  end
end