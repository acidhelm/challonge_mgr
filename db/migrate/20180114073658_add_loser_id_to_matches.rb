class AddLoserIdToMatches < ActiveRecord::Migration[5.1]
  def change
    add_column :matches, :loser_id, :integer
  end
end
