# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180102102735) do

  create_table "matches", force: :cascade do |t|
    t.integer "tournament_id"
    t.integer "challonge_id"
    t.string "state"
    t.integer "team1_id"
    t.integer "team2_id"
    t.integer "winner_id"
    t.integer "round"
    t.integer "suggested_play_order"
    t.string "scores_csv"
    t.date "underway_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "team1_prereq_match_id"
    t.integer "team2_prereq_match_id"
    t.boolean "team1_is_prereq_match_loser"
    t.boolean "team2_is_prereq_match_loser"
    t.index ["tournament_id"], name: "index_matches_on_tournament_id"
  end

  create_table "teams", force: :cascade do |t|
    t.integer "tournament_id"
    t.integer "challonge_id"
    t.string "name"
    t.integer "seed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_teams_on_tournament_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "description"
    t.integer "challonge_id"
    t.string "name"
    t.string "state"
    t.string "challonge_url"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tournament_type"
    t.index ["user_id"], name: "index_tournaments_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "user_name"
    t.string "api_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
