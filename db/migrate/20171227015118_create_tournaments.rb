class CreateTournaments < ActiveRecord::Migration[5.1]
  def change
    create_table :tournaments do |t|
      t.string :description
      t.integer :challonge_id
      t.string :name
      t.string :state
      t.string :challonge_url
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
