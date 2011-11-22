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
  end

  def self.down
  end
end
