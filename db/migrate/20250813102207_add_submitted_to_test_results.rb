class AddSubmittedToTestResults < ActiveRecord::Migration[7.0]
  def change
    add_column :test_results, :submitted, :boolean, default: false, null: false
  end
end
