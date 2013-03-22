class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :rememberable, :registerable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :ldap_authenticatable, :trackable, :rememberable, :timeoutable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :login, :password, :password_confirmation, :remember_me, :role_ids, :is_ldap
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :roles
  has_many :track_layouts
  has_many :favorites, :order => :type
  has_many :favorite_seqfeatures
  has_many :seqfeatures, :through => :favorite_seqfeatures
  has_many :experiments
  has_many :blast_runs, :order => 'id desc'
  has_one :private_group, :class_name => "Group", :include => :owner, :foreign_key => 'owner_id', :conditions => "name = users.login", :dependent => :destroy
  validates_uniqueness_of :login
  validates_presence_of :login
  before_create :get_ldap_email
  before_save :set_default_role
  after_create :setup_default_groups
  
  has_paper_trail :ignore => [:sign_in_count, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip, :remember_created_at, :updated_at]

  preference :track_path, :string
  preference :track_layout, :string
  
  # name used for public display
  def display_name
    login
  end
  
  def has_role?(role)
    @user_roles ||= roles.collect(&:name)
    @user_roles.include?(role) || @user_roles.include?('admin')
  end
  
  def is_admin?
    has_role?("admin")
  end
  
  # ldap users have no salt so we rescue BCrypt::Errors::InvalidHash
  def valid_password?(password)
    # we don't want to validate against local password unless local user
    return false if is_remote?
    super
  rescue BCrypt::Errors::InvalidHash => e
    false
  end
  
  # a user owns an object if they created it.
  def owns?(obj)
    return self.id == obj.try(:versions).try(:last).try(:whodunnit).to_i
  end
  
  # a remote user does not have the same account settings as a local user
  def is_remote?
    self.is_ldap
  end
  
  protected
  
  def get_ldap_email
    return unless self.is_remote?
    begin
      self.email = Devise::LdapAdapter.get_ldap_param(login,'mail')
    rescue
      logger.info "\n\n#{$!}\n#{caller.join("\n")}\n\n"
    end
  end
  
  # TODO: Make this configurable - default remote users are members, all others are guests
  def set_default_role
    if self.roles.empty?
      if is_remote?
        self.roles << Role.find_or_create_by_name('member')
      else
        self.roles << Role.find_or_create_by_name('guest')
      end
    end
  end
  
  def setup_default_groups
    unless self.login.blank?
      private_group = Group.new(:name => self.login, :owner => self)
      private_group.users << self
      begin
        private_group.save!
      rescue => e
        server_error(e,"could not generate private group for #{self.inspect}")
      end
    end
    Group.public_group.users << self
  end
end
