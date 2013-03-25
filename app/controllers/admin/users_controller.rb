class Admin::UsersController < Admin::AdminController
  before_filter :find_user, :except => [:index,:new, :create]
  before_filter :load_data, :only => [:edit, :new, :create, :update]
  
  # render index.html
  def index
    params[:c]||=:last_sign_in_at
    order_d = (params[:d]=='up' ? 'asc' : 'desc')
    @users = User.order("#{params[:c]} #{order_d}")
      .paginate(:page => params[:page])
    if(params[:q])
      query = "%#{params[:q]}%"
      @users = @users.where{ (login =~ query) || (email =~ query) }
    end
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
  
  # DELETE /ontologies/1
   def destroy
     @user.destroy
     respond_to do |wants|
       wants.html { redirect_to(admin_users_url) }
     end
   end
   
protected
  def find_user
    @user = User.find(params[:id], :include => :roles)
  end
  
  def load_data
    @default_role = Role.find_or_create_by_name("member")
    @roles = Role.all
  end

end


