class AddGroupTeamIdsToTeams < ActiveRecord::Migration[5.1]
  def change
    add_column :teams, :group_team_ids, :text
  end
end
