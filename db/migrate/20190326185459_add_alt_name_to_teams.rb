class AddAltNameToTeams < ActiveRecord::Migration[5.2]
    def change
        add_column :teams, :alt_name, :string
    end
end
