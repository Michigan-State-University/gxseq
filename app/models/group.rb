# == Schema Information
#
# Table name: groups
#
#  created_at :datetime
#  id         :integer          not null, primary key
#  name       :string(255)
#  owner_id   :integer
#  updated_at :datetime
#

class Group < ActiveRecord::Base
  belongs_to :owner, :class_name => "User", :foreign_key => 'owner_id'
  has_and_belongs_to_many :users
  has_many :assemblies
  has_many :bioentries, :through => :assemblies
  has_many :experiments
  validate :new_user_login
  before_save :add_new_user
  attr_accessor :new_user
  
  def self.public_group
    Group.find_or_create_by_name('public')
  end
  # virtual method just sets an instance variable for validation
  def user_login=(string)
    @new_user = string unless string.blank?
  end

  def user_login
    new_user
  end
  # save valid users and reset user cache
  def add_new_user
    if(u = get_user_from_string(new_user))
      self.users << u
      Ability.reset_cache
    end
  end
  
  protected
  # validate the new username
  def new_user_login
    if(new_user)
      unless(u = get_user_from_string(new_user))
        self.errors.add :user_login, "'#{new_user}' could not be found"
      end
    end
  end
  # lookup users by string or id
  def get_user_from_string(str)
    User.find_by_login(str) || User.find_by_id(str)
  end
end
