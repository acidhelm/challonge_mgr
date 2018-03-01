class AddViewCacheToTournament < ActiveRecord::Migration[5.1]
    def change
        add_column :tournaments, :view_gold_name, :string
        add_column :tournaments, :view_blue_name, :string
        add_column :tournaments, :view_gold_score, :integer, default: 0, null: false
        add_column :tournaments, :view_blue_score, :integer, default: 0, null: false
    end
end
