class Ability

  include CanCan::Ability
  
  # This caching method is added to avoid long running queries.
  # id ranges are computed and passed to sunspot during text searches
  # the results are stored in class variables for future use.
  #
  # hash used for auth cache. keys are user_id, values are id ranges
  @@seqfeature_auth_ids = {}
  @@gene_model_auth_ids = {}
  @@bioentry_auth_ids = {}
  # clear out the auth cache
  # The cache is reset when sample or group information changes
  # see: GroupsController::remove_user, Group::add_user, Experiment::update_cache
  def self.reset_cache
    @@seqfeature_auth_ids = {}
    @@gene_model_auth_ids = {}
    @@bioentry_auth_ids = {}
  end
  # returns an array of seqfeature id ranges accessible by this user
  # used to send authorized ids in index queries
  def authorized_seqfeature_ids
    @@seqfeature_auth_ids[@stored_user_id]||=Seqfeature.accessible_by(self).select_ranges
  end
  # returns an array of gene model id ranges accessible by this user
  def authorized_gene_model_ids
    @@gene_model_auth_ids[@stored_user_id]||=GeneModel.accessible_by(self).select_ranges
  end
  # returns an array of bioentry id ranges accessible by this user
  def authorized_bioentry_ids
    @@bioentry_auth_ids[@stored_user_id]||=Bioentry.accessible_by(self).select_ranges
  end
  # returns the user_id for this ability so we can reference it in controller
  def user_id
    @stored_user_id
  end
  # NOTE: There is an issue when combining abilities that reference the same table
  # when searching experiment->users and sequence->users we need to use different lookup method
  # group -> users -> id => user.id   vs.  group -> id => user.group_ids
  # otherwise the sql produced will not use the generated join table name and will be incorrect
  # example:
  # 
  #   LEFT OUTER JOIN `users` ON `users`.`id` = `groups_users`.`user_id`
  #   LEFT OUTER JOIN `users` `users_groups` ON `users_groups`.`id` = `users_groups_join`.`user_id`
  #   WHERE (`users`.`id` = 2) OR (`users`.`id` = 2)  <- Should be `users_groups`.`id`
  #
  def initialize(user)
    # guest user (not logged in) == new user
    user ||= User.new
    # store the user id or nil for cache lookup
    @stored_user_id = user.id
    # admin can view and edit everything
    if user.is_admin?
      can :manage, :all
      
    # Members can create and belong to multiple groups. Sample and Sequence data is protected by Groups.
    # Each Taxon Version or Sample is tied to a single group. Members can view Sample and Sequence data only if they belong to it's group.
    # Members can view Sequence data if they can view any sample tied to the sequence and can annotate sequence they can view.
    elsif user.has_role?('member')
      #Users
      can :read, User
      can :update, User, :id => user.id
      #Groups
      can :manage, Group, :owner_id => user.id
      can :read, Group, :users => {:id => user.id}
      #need to get more information about users managing groups
      #can :create, Group
      #Taxon
      can :read, Taxon, :species_assemblies => {:group => {:users => {:id => user.id}}}
      can :read, Taxon, :species_assemblies => {:experiments => {:group => {:id => user.group_ids}}}
      #Assemblies
      can :read, Assembly, :group => {:users => {:id => user.id}}
      can :read, Assembly, :experiments => {:group => {:id => user.group_ids}}
      #Sequence
      can :read, Bioentry, :assembly => {:group => {:users => {:id => user.id}}}
      can :read, Bioentry, :assembly => {:experiments => {:group => {:id => user.group_ids}}}
      #Features
      can [:read,:update, :toggle_favorite, :feature_counts], Seqfeature, :bioentry => {:assembly => {:group => {:users => {:id => user.id}}}}
      can [:read,:update, :toggle_favorite, :feature_counts], Seqfeature, :bioentry => {:assembly => {:experiments => {:group => {:id => user.group_ids}}}}
      can :create, Seqfeature
      #GeneModels
      can [:read,:update], GeneModel, :bioentry => {:assembly => {:group => {:users => {:id => user.id}}}}
      can [:read,:update], GeneModel, :bioentry => {:assembly => {:experiments => {:group => {:id => user.group_ids}}}}
      #TODO: Update gene model create view before enabling
      #can :create, GeneModel
      #Samples
      can :manage, Experiment, :user_id => user.id
      can :read, Experiment, :group => {:users => {:id => user.id}}
      can :track_data, Experiment, :group => {:users => {:id => user.id}}
      can :track_data, Experiment, :user_id => user.id
      #Tracks
      # Tracks are only accessible if they have experiments
      # Non-experiment tracks are not tested in controllers/models (models,generic,six_frame)
      can :read, Track, :experiment => {:group => {:id => user.group_ids}}
      #Asset
      can :read, Asset, :experiment => {:group => {:users => {:id => user.id}}}
      #Expression
      can :read, FeatureCount, :experiment => {:group => {:users => {:id => user.id}}}
      can :read, FeatureCount, :experiment => {:user_id => user.id}
      #Blast Database
      can :read, BlastDatabase, :group => {:users => {:id => user.id}}
      # TODO: coordinate user_id,owner_id,owns? methods for consistency (Experiment,Group,What Else?)
      # Need explicit create to allow new experiments
      #
      # Owner tests - these were added as extra feature/sequence visibilty tests. Removed for simplicity.
      # They did allow users to view sequence and features if they could view any associated samples
      # Removed because these lookups take several seconds on mysql and only the admin can manage groups, samples, and sequence right now
      #
      # can :read, Taxon, :species_assemblies => {:experiments => {:user_id => user.id}}
      # can :read, Assembly, :experiments => {:user_id => user.id}
      # can :read, Bioentry, :assembly => {:experiments => {:user_id => user.id}}
      # can [:read,:update, :toggle_favorite], Seqfeature, :bioentry => {:assembly => {:experiments => {:user_id => user.id}}}
      # can [:read,:update], GeneModel, :bioentry => {:assembly => {:experiments => {:user_id => user.id}}}
    
    # Guest users have group based access but annotation is limited.
    elsif user.has_role?('guest')
      can :read, User, :id => user.id
      can :update, User, :id => user.id
      can :read, Group, :users => {:id => user.id}
      can :read, Taxon, :species_assemblies => {:group => {:users => {:id => user.id}}}
      can :read, Taxon, :species_assemblies => {:experiments => {:group => {:id => user.group_ids}}}
      can :read, Assembly, :group => {:users => {:id => user.id}}
      can :read, Assembly, :experiments => {:group => {:id => user.group_ids}}
      can :read, Bioentry, :assembly => {:group => {:users => {:id => user.id}}}
      can :read, Bioentry, :assembly => {:experiments => {:group => {:id => user.group_ids}}}
      can [:read, :toggle_favorite], Seqfeature, :bioentry => {:assembly => {:group => {:users => {:id => user.id}}}}
      can [:read, :toggle_favorite], Seqfeature, :bioentry => {:assembly => {:experiments => {:group => {:id => user.group_ids}}}}
      can [:read,], GeneModel, :bioentry => {:assembly => {:group => {:users => {:id => user.id}}}}
      can [:read,], GeneModel, :bioentry => {:assembly => {:experiments => {:group => {:id => user.group_ids}}}}
      can :read, Experiment, :group => {:users => {:id => user.id}}
      can :track_data, Experiment, :group => {:users => {:id => user.id}}
      can :read, Track, :experiment => {:group => {:id => user.group_ids}}
      can :read, Asset, :experiment => {:group => {:users => {:id => user.id}}}
      can :read, FeatureCount, :experiment => {:group => {:users => {:id => user.id}}}
      can :read, BlastDatabase, :group => {:users => {:id => user.id}}
    #TODO: What about users with no role?
    
    # Anybody from the public can view data in the Public group.
    else
      can :read, User, :id => user.id
      can :read, Group, :name => 'public'
      can :read, Taxon, :species_assemblies => {:group => {:name => 'public'}}
      can :read, Assembly, :group => {:name => 'public'}
      can :read, Bioentry, :assembly => {:group => {:name => 'public'}}
      can :read, Seqfeature, :bioentry => {:assembly => {:group => {:name => 'public'}}}
      can :read, GeneModel, :bioentry => {:assembly => {:group => {:name => 'public'}}}
      can :read, Experiment, :group => {:name => 'public'}
      can :track_data, Experiment, :group => {:name => 'public'}
      can :read, Track, :experiment => {:group => {:name => 'public'}}
      can :read, Asset, :experiment => {:group => {:name => 'public'}}
      can :read, FeatureCount, :experiment => {:group => {:name => 'public'}}
      can :read, BlastDatabase, :group => {:name => 'public'}
    end
  end
  
end