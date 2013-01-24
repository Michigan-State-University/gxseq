class CreateAdminUser < ActiveRecord::Migration
  def self.up
    admin = User.create(
      :login => (APP_CONFIG[:admin_user] || "admin"),
      :email => (APP_CONFIG[:admin_email] || "admin@admin.com"),
      :password => (APP_CONFIG[:admin_pass] || "secret")
    )
    
    admin_role = Role.create(
      :name => "admin"
    )
    admin.roles << admin_role
    public_grp = Group.public_group
    public_grp.owner = admin
    public_grp.save
  end

  def self.down
    User.find_by_login((APP_CONFIG[:admin_user] || "admin")).destroy
    Role.find_by_name('admin').destroy
    Group.find_by_name('admin').destroy
  end
end
