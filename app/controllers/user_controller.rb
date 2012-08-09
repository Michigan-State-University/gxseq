class UserController < ApplicationController

  before_filter :find_user, :only => [:show, :edit, :update]
  
  ##Preferences Ajax actions
  def update_track_node
    if( (path = params[:path]) && (track = Track.find(params[:track_id])) )
      current_user.preferred_track_path=path, track
      current_user.save!
    end
    render :nothing => true
  end
    
  # GET /_users/1
  def show
  # show.html.erb
  end

  # GET /users/1/edit
  def edit
  end

  # PUT /users/1
  def update
    respond_to do |wants|
      if user = @user.update_attributes(params[:user])
        flash[:notice] = 'Password updated successfully!'
        flash[:warning] = 'You have been signed out, please sign in to continue.'
        wants.html { redirect_to(root_path) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end
  
  # public profile view
  def profile
    
  end
  
  private
    def find_user
      @user = User.find(params[:id])
      unless(@user == current_user)
        flash[:error] = "You are not authorized to view that resource!"
        redirect_to(root_path)
        return
      end
    end

end
