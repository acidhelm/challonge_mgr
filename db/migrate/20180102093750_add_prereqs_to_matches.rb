class AddPrereqsToMatches < ActiveRecord::Migration[5.1]
  def change
    add_column :matches, :team1_prereq_match_id, :integer
    add_column :matches, :team2_prereq_match_id, :integer
    add_column :matches, :team1_is_prereq_match_loser, :boolean
    add_column :matches, :team2_is_prereq_match_loser, :boolean
  end
end
