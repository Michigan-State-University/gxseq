class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :rememberable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :ldap_authenticatable, :trackable, :rememberable, :timeoutable#,:confirmable, :lockable, :registerable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :login, :password, :password_confirmation, :remember_me, :role_ids
  has_and_belongs_to_many :roles
  has_many :track_layouts
  validates_uniqueness_of :login
  validates_presence_of :login
  before_save :get_ldap_email
  has_paper_trail :ignore => [:sign_in_count, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip, :remember_created_at, :updated_at]

  preference :track_path, :string
  preference :track_layout, :string
  
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
    obj.respond_to?(:versions) && obj.versions.is_a?(Array) && !obj.versions.empty? && (who_id = obj.versions.last.whodunnit)
    begin
      return self == User.find(who_id)
    rescue
      return false
    end
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
    
end
