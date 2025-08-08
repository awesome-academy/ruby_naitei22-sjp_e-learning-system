class AcceptNullOnUserAnswer < ActiveRecord::Migration[7.0]
  def change
    change_column_null :test_results, :user_answers, true
  end
end
