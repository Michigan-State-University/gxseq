class GroupsController < ApplicationController
  autocomplete :user, :login

  load_and_authorize_resource
  skip_authorize_resource :only => :autocomplete_user_login

  def index
  end

  def show
  end

  def new
  end

  def edit
  end

  def create
    @group.owner = current_user
    respond_to do |wants|
      if @group.save
        flash[:notice] = 'Group was successfully created.'
        wants.html { redirect_to(@group) }
      else
        wants.html { render :action => "new" }
      end
    end
  end

  def update
    respond_to do |wants|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        wants.html { redirect_to(edit_group_path(@group)) }
      else
        wants.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @group.destroy

    respond_to do |wants|
      wants.html { redirect_to(groups_url) }
    end
  end

  # custom route to remove a user
  # clears out the User cache as well
  def remove_user
    to_be_removed = @group.users.where(:id => params[:user_id])
    if(to_be_removed.size > 0)
      flash[:warning] = "Removed: #{to_be_removed.map(&:login).to_sentence}"
    else
      flash[:error] = "Error: Could not find user with id '#{params[:user_id]}'"
    end
    @group.users.delete(to_be_removed)
    Ability.reset_cache
    redirect_to(edit_group_path(@group)) 
  end
end
