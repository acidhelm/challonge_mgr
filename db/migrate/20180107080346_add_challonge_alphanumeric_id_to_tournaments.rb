class AddChallongeAlphanumericIdToTournaments < ActiveRecord::Migration[5.1]
  def change
    add_column :tournaments, :challonge_alphanumeric_id, :string
  end
end
