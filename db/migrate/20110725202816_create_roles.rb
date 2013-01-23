class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles, :force => true do |t|
      t.string :name
      t.timestamps
    end
    create_table :roles_users, :force => true, :id => false do |t|
      t.belongs_to :role
      t.belongs_to :user
    end
    add_index :roles_users, :role_id
    add_index :roles_users, :user_id
    
    Role.create(
      :name => "member"
    )
    Role.create(
      :name => "guest"
    )
  end

  def self.down
    drop_table :roles_users
    drop_table :roles
  end
end