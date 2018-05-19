class AddGroupIdToMatches < ActiveRecord::Migration[5.1]
    def change
        add_column :matches, :group_id, :integer
    end
end

