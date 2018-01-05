class AddCurrentMatchToTournaments < ActiveRecord::Migration[5.1]
  def change
    add_column :tournaments, :current_match, :integer
  end
end
