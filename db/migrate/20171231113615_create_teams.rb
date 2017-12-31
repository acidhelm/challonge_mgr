class CreateTeams < ActiveRecord::Migration[5.1]
  def change
    create_table :teams do |t|
      t.references :tournament, foreign_key: true
      t.integer :challonge_id
      t.string :name
      t.integer :seed

      t.timestamps
    end
  end
end
