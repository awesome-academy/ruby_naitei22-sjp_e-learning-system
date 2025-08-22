class RemovePasswordDigestFromUsers < ActiveRecord::Migration[7.0]
  def up
    remove_column :users, :password_digest, :string, if_exists: true
  end

  def down
    unless column_exists?(:users, :password_digest)
      add_column :users, :password_digest, :string
    end
  end
end
