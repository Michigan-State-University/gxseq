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
  end

  def self.down
  end
end
