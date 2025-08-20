class RemoveRememberDigestFromUsers < ActiveRecord::Migration[7.0]
  def up
    remove_column :users, :remember_digest, :string, if_exists: true
  end

  def down
    unless column_exists?(:users, :remember_digest)
      add_column :users, :remember_digest, :string
    end
  end
end
