class CreateAdminUser < ActiveRecord::Migration
  def self.up
    admin = (
      User.find_by_login(
        (APP_CONFIG[:admin_user] || "admin")
      ) || User.create(
        :login => (APP_CONFIG[:admin_user] || "admin"),
        :email => (APP_CONFIG[:admin_email] || "admin@admin.com"),
        :password => (APP_CONFIG[:admin_pass] || "secret")
      )
    )
    
    admin_role = Role.find_or_create_by_name("admin")
    admin.roles << admin_role
    public_grp = Group.public_group
    public_grp.owner = admin
    public_grp.save
  end

  def self.down
    # Do not remove user, future code changes may break during destory (i.e. blast_run dependent=>destroy)
  end
end
