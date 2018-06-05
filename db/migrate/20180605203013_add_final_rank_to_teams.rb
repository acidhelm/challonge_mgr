class AddFinalRankToTeams < ActiveRecord::Migration[5.1]
    def change
        add_column :teams, :final_rank, :integer
    end
end
