class AddGroupNameToMatches < ActiveRecord::Migration[5.1]
    def change
        add_column :matches, :group_name, :string
    end
end
