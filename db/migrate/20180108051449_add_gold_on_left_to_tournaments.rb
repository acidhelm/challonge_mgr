class AddGoldOnLeftToTournaments < ActiveRecord::Migration[5.1]
  def change
    add_column :tournaments, :gold_on_left, :boolean
  end
end
