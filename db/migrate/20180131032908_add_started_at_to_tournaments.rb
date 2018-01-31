class AddStartedAtToTournaments < ActiveRecord::Migration[5.1]
  def change
    add_column :tournaments, :started_at, :datetime
  end
end
