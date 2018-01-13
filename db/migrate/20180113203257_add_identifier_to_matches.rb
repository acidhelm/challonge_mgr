class AddIdentifierToMatches < ActiveRecord::Migration[5.1]
  def change
    add_column :matches, :identifier, :string
  end
end
