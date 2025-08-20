class AddRememberTokenToUsers < ActiveRecord::Migration[7.0]
  def up
    unless column_exists?(:users, :remember_token)
      add_column :users, :remember_token, :string
    end
  end

  def down
    remove_column :users, :remember_token, if_exists: true
  end
end
