class AddForfeitedToMatch < ActiveRecord::Migration[5.1]
    def change
        add_column :matches, :forfeited, :boolean
    end
end
