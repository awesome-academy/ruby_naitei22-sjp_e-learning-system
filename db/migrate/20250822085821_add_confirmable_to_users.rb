class AddConfirmableToUsers < ActiveRecord::Migration[7.0]
  def up
    change_table :users do |t|
      t.string   :confirmation_token unless column_exists?(:users, :confirmation_token)
      t.datetime :confirmed_at unless column_exists?(:users, :confirmed_at)
      t.datetime :confirmation_sent_at unless column_exists?(:users, :confirmation_sent_at)
      t.string   :unconfirmed_email unless column_exists?(:users, :unconfirmed_email)
    end
    add_index :users, :confirmation_token, unique: true unless index_exists?(:users, :confirmation_token)
  end

  def down
    remove_index :users, :confirmation_token if index_exists?(:users, :confirmation_token)
    remove_column :users, :confirmation_token, if_exists: true
    remove_column :users, :confirmed_at, if_exists: true
    remove_column :users, :confirmation_sent_at, if_exists: true
    remove_column :users, :unconfirmed_email, if_exists: true
  end
end
