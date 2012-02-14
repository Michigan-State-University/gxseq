class Admin::UsersController < Admin::AdminController
  before_filter :find_user, :except => [:index,:new, :create, :logout]
  before_filter :load_data, :only => [:edit, :new, :create, :update]
  before_filter :check_auth, :except => [:sign_out]
  
  # render index.html
  def index
    # TODO - update search / pagination
    #@users = User.search(:q => params[:q], :c => params[:c], :d => params[:d], :page => params[:page])
    @users = User.all
  end
  
  def edit
  end
    
  # render new.rhtml
  def new
    @user = User.new
    @roles = Role.all
  end
 
  def show
  end
  
  def create
    @roles = Role.all
    @user = User.new(params[:user])
    if(@user.valid?)
      if(@user.password.blank?)
        @user.errors.add(:password, "cannot be blank")
        render :action => :new
        return
      end
      if(@user.password_confirmation.blank?)
        @user.errors.add(:password_confirmation, "cannot be blank")
        render :action => :new
        return
      end
      if(@user.password_confirmation != @user.password)
        @user.errors.add(:password, "must equal password confirmation")
        render :action => :new
        return
      end
      @user.save
      redirect_to admin_users_path
    else
      render :action => :new
    end
  end

  def update
    if @user.update_attributes(params[:user])
      flash[:notice] = "#{@user.login} successfully updated"
      redirect_to(current_user.is_admin? ? admin_users_path : @user)
    else
      render :action => "edit"
    end
  end
  
  def logout
    sign_out(current_user)
    redirect_to(new_session_path)
  end
  
protected
  def find_user
    @user = User.find(params[:id], :include => :roles)
  end
  
  def load_data
    if current_user && current_user.is_admin?
      @default = Role.find_by_name("user")
      @roles = Role.all
    end
  end
  
  def check_auth
    redirect_to(root_path) unless current_user.is_admin?
  end
end


