class UserController < ApplicationController
  load_and_authorize_resource
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
    params[:fmt]||='favorites'
    @groups = Group.accessible_by(current_ability)
    @samples = Experiment.accessible_by(current_ability)
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

end
