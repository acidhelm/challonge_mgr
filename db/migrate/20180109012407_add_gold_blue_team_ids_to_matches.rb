class AddGoldBlueTeamIdsToMatches < ActiveRecord::Migration[5.1]
  def change
    add_column :matches, :gold_team_id, :integer
    add_column :matches, :blue_team_id, :integer
  end
end
