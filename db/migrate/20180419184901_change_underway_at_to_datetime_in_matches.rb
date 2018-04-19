class ChangeUnderwayAtToDatetimeInMatches < ActiveRecord::Migration[5.1]
    def up
        change_column :matches, :underway_at, :datetime
    end

    def down
        change_column :matches, :underway_at, :date
    end
end
