class UserController < ApplicationController
  load_and_authorize_resource
  ##Preferences Ajax actions
  def update_track_node
    if( (path = params[:path]) && (track = Track.find(params[:track_id])) )
      @user.preferred_track_path=path, track
      @user.save!
    end
    render :nothing => true
  end
    
  # GET /_users/1
  def show
    unless params[:fmt]
      if !@user.favorite_seqfeatures.empty?
        params[:fmt]='favorites'
      else
        params[:fmt]='samples'
      end
    end
    case params[:fmt]
    when 'samples'
      @samples = Sample.accessible_by(Ability.new(@user))
        .includes(:group,:assembly => [:species => [:scientific_name]])
        .order('groups.name,assemblies.id,samples.name')
        .paginate(:page => params[:page],:per_page => 100)
      unless params[:keywords].blank?
        txt = "%#{params[:keywords]}%"
        @samples = @samples.where{(name =~ my{txt}) |
          (description =~ my{txt}) |
          (assembly.species.scientific_name.name =~ my{txt}) |
          (assembly.version =~ my{txt})}
      end
      unless params[:sample_type].blank?
        @samples = @samples.where{type=~my{params[:sample_type]}}
      end
    when 'groups'
      @groups = Group.accessible_by(Ability.new(@user))
    end
    
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
