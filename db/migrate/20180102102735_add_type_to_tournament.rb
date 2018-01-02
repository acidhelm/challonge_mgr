class AddTypeToTournament < ActiveRecord::Migration[5.1]
  def change
    add_column :tournaments, :tournament_type, :string
  end
end
