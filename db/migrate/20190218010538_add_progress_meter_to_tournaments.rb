class AddProgressMeterToTournaments < ActiveRecord::Migration[5.2]
    def change
        add_column :tournaments, :progress_meter, :integer, null: false, default: 0
    end
end
