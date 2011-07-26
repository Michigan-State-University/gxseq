class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :rememberable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :login, :password, :password_confirmation, :remember_me
  has_and_belongs_to_many :roles
  
  def has_role?(role)
    @user_roles ||= roles.collect(&:name)
    @user_roles.include?(role) || @user_roles.include?('admin')
  end
  
  def is_admin?
    has_role?("admin")
  end
  
end
