class CreateAdminUser < ActiveRecord::Migration
  def self.up
    User.paper_trail_off
    admin = User.create(
      :login => (APP_CONFIG[:admin_user] || "admin"),
      :email => (APP_CONFIG[:admin_email] || "admin@admin.com"),
      :password => (APP_CONFIG[:admin_pass] || "secret")
    )
    User.paper_trail_on
    
    admin_role = Role.create(
      :name => "admin"
    )
    admin.roles << admin_role
    public_grp = Group.public_group
    public_grp.owner = admin
    public_grp.save
  end

  def self.down
    User.find_all_by_login((APP_CONFIG[:admin_user] || "admin")).destroy_all
  end
end
