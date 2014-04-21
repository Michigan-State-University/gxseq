class Ability

  include CanCan::Ability
  # This caching method is added to avoid long running queries.
  # ids are computed and passed to sunspot during text searches
  # the results are stored in class variables for future use.
  #
  # hash used for auth cache. keys are user_id, values are id ranges
  @@assembly_auth_ids = {}
  # clears  the auth cache
  # The cache is reset when sample or group information changes
  # see: GroupsController::remove_user, Group::add_user, Sample::update_cache
  def self.reset_cache
    @@assembly_auth_ids = {}
  end
  # returns an array of assembly ids accessible by this user
  # used to send authorized ids in index queries
  def authorized_assembly_ids
    @@assembly_auth_ids[@stored_user_id]||=Assembly.accessible_by(self).select_ids.uniq
  end
  # returns the user_id for this ability so we can reference it in controller
  def user_id
    @stored_user_id
  end
  # NOTE: There is an issue when combining abilities that reference the same table
  # when searching sample->users and sequence->users we need to use different lookup method
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
    @stored_user_id = user.id || 'guest'
    # admin can view and edit everything
    if user.is_admin?
      can :manage, :all
      
    # Members can create and belong to multiple groups. Sample and Sequence data is protected by Groups.
    # Each Taxon Version or Sample is tied to a single group. Members can view Sample and Sequence data only if they belong to it's group.
    # Members can view Sequence data if they can view any sample tied to the sequence and can annotate sequence they can view.
    elsif user.has_role?('member')
      #Users
      can :read, User
      can [:update,:update_track_node], User, :id => user.id
      #Groups
      can :manage, Group, :owner_id => user.id
      can :read, Group, :users => {:id => user.id}
      #need to get more information about users managing groups
      #can :create, Group
      #Taxon
      can :read, Biosql::Taxon, :species_assemblies => {:group => {:users => {:id => user.id}}}
      can :read, Biosql::Taxon, :species_assemblies => {:samples => {:group => {:id => user.group_ids}}}
      #Assemblies
      can :read, Assembly, :group => {:users => {:id => user.id}}
      can :read, Assembly, :samples => {:group => {:id => user.group_ids}}
      #Sequence
      can :read, Biosql::Bioentry, :assembly => {:group => {:users => {:id => user.id}}}
      can :read, Biosql::Bioentry, :assembly => {:samples => {:group => {:id => user.group_ids}}}
      #Features
      can [:read,:update, :toggle_favorite, :base_counts, :feature_counts, :coexpressed_counts], Biosql::Feature::Seqfeature, :bioentry => {:assembly => {:group => {:users => {:id => user.id}}}}
      can [:read,:update, :toggle_favorite, :base_counts, :feature_counts, :coexpressed_counts], Biosql::Feature::Seqfeature, :bioentry => {:assembly => {:samples => {:group => {:id => user.group_ids}}}}
      can :create, Biosql::Feature::Seqfeature
      #GeneModels
      can [:read,:update], GeneModel, :bioentry => {:assembly => {:group => {:users => {:id => user.id}}}}
      can [:read,:update], GeneModel, :bioentry => {:assembly => {:samples => {:group => {:id => user.group_ids}}}}
      can :create, GeneModel
      #Samples
      can :manage, Sample, :user_id => user.id
      can [:read,:track_data,:update], Sample, :group => {:users => {:id => user.id}}
      can :create, Combo
      #Traits
      can :read, Biosql::Ontology
      can [:read,:create], Biosql::Term
      #Tracks
      # Tracks are only accessible if they have samples
      # Non-sample tracks are not tested in controllers/models (models,generic,six_frame)
      can :read, Track, :sample => {:group => {:id => user.group_ids}}
      #Asset
      can :read, Asset, :sample => {:group => {:users => {:id => user.id}}}
      #Expression
      can :read, FeatureCount, :sample => {:group => {:users => {:id => user.id}}}
      can :read, FeatureCount, :sample => {:user_id => user.id}
      #Blast Database
      can :read, BlastDatabase, :group => {:users => {:id => user.id}}

      # TODO: coordinate user_id,owner_id,owns? methods for consistency (Sample,Group,What Else?)
      # Need explicit create to allow new samples
      #
      # Owner tests - these were added as extra feature/sequence visibilty tests. Removed for simplicity.
      # They did allow users to view sequence and features if they could view any associated samples
      # Removed because these lookups take several seconds on mysql and only the admin can manage groups, samples, and sequence right now
      #
      # can :read, Taxon, :species_assemblies => {:samples => {:user_id => user.id}}
      # can :read, Assembly, :samples => {:user_id => user.id}
      # can :read, Bioentry, :assembly => {:samples => {:user_id => user.id}}
      # can [:read,:update, :toggle_favorite], Seqfeature, :bioentry => {:assembly => {:samples => {:user_id => user.id}}}
      # can [:read,:update], GeneModel, :bioentry => {:assembly => {:samples => {:user_id => user.id}}}
    
    # Guest users have group based access but annotation is limited.
    elsif user.has_role?('guest')
      can :read, User, :id => user.id
      can :update, User, :id => user.id
      can :read, Group, :users => {:id => user.id}
      can :read, Biosql::Taxon, :species_assemblies => {:group => {:users => {:id => user.id}}}
      can :read, Biosql::Taxon, :species_assemblies => {:samples => {:group => {:id => user.group_ids}}}
      can :read, Assembly, :group => {:users => {:id => user.id}}
      can :read, Assembly, :samples => {:group => {:id => user.group_ids}}
      can :read, Biosql::Bioentry, :assembly => {:group => {:users => {:id => user.id}}}
      can :read, Biosql::Bioentry, :assembly => {:samples => {:group => {:id => user.group_ids}}}
      can [:read, :toggle_favorite, :base_counts, :feature_counts, :coexpressed_counts], Biosql::Feature::Seqfeature, :bioentry => {:assembly => {:group => {:users => {:id => user.id}}}}
      can [:read, :toggle_favorite, :base_counts, :feature_counts, :coexpressed_counts], Biosql::Feature::Seqfeature, :bioentry => {:assembly => {:samples => {:group => {:id => user.group_ids}}}}
      can [:read], GeneModel, :bioentry => {:assembly => {:group => {:users => {:id => user.id}}}}
      can [:read], GeneModel, :bioentry => {:assembly => {:samples => {:group => {:id => user.group_ids}}}}
      can [:read, :track_data], Sample, :group => {:users => {:id => user.id}}
      can :read, Track, :sample => {:group => {:id => user.group_ids}}
      can :read, Asset, :sample => {:group => {:users => {:id => user.id}}}
      can :read, FeatureCount, :sample => {:group => {:users => {:id => user.id}}}
      can :read, BlastDatabase, :group => {:users => {:id => user.id}}
    
    # Anybody from the public can view data in the Public group.
    else
      public_gid = Group.public_group.id
      can :read, User, :id => user.id
      can :read, Group, :name => 'public'
      can :read, Biosql::Taxon, :species_assemblies => {:group => {:name => 'public'}}
      can :read, Biosql::Taxon, :species_assemblies => {:samples => {:group_id => public_gid}}
      can :read, Assembly, :group => {:name => 'public'}
      can :read, Assembly, :samples => {:group_id => public_gid}
      can :read, Biosql::Bioentry, :assembly => {:group => {:name => 'public'}}
      can :read, Biosql::Bioentry, :assembly => {:samples => {:group_id => public_gid}}
      can [:read, :base_counts, :feature_counts, :coexpressed_counts], Biosql::Feature::Seqfeature, :bioentry => {:assembly => {:group => {:name => 'public'}}}
      can [:read, :base_counts, :feature_counts, :coexpressed_counts], Biosql::Feature::Seqfeature, :bioentry => {:assembly => {:samples => {:group_id => public_gid}}}
      can :read, GeneModel, :bioentry => {:assembly => {:group => {:name => 'public'}}}
      can :read, GeneModel, :bioentry => {:assembly => {:samples => {:group_id => public_gid}}}
      can [:read,:track_data], Sample, :group => {:name => 'public'}
      can [:read,:track_data], Sample, :assembly => {:group_id => public_gid}
      can :read, Track, :sample => {:group_id => public_gid}
      can :read, Track, :sample => {:assembly => {:group => {:name => 'public'}}}
      can :read, Asset, :sample => {:group => {:name => 'public'}}
      can :read, Asset, :sample => {:assembly => {:group => {:name => 'public'}}}
      can :read, FeatureCount, :sample => {:group => {:name => 'public'}}
      can :read, FeatureCount, :sample => {:assembly => {:group_id => public_gid}}
      can :read, BlastDatabase, :group => {:name => 'public'}
    end
  end
  
end