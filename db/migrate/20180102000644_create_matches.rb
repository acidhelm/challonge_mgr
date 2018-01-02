class CreateMatches < ActiveRecord::Migration[5.1]
  def change
    create_table :matches do |t|
      t.references :tournament, foreign_key: true
      t.integer :challonge_id
      t.string :state
      t.integer :team1_id
      t.integer :team2_id
      t.integer :winner_id
      t.integer :round
      t.integer :suggested_play_order
      t.string :scores_csv
      t.date :underway_at

      t.timestamps
    end
  end
end
