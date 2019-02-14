class AddShowQuickStartToUsers < ActiveRecord::Migration[5.2]
    def change
        add_column :users, :show_quick_start, :boolean, default: true
    end
end

