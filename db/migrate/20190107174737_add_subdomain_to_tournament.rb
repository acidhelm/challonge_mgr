class AddSubdomainToTournament < ActiveRecord::Migration[5.2]
    def change
        add_column :tournaments, :subdomain, :string
    end
end
