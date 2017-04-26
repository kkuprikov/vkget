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

ActiveRecord::Schema.define(version: 20170419144922) do

  create_table "groups", force: :cascade do |t|
    t.string   "CreateGroups"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "user_groups", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.text     "groups"
    t.string   "first_name"
    t.string   "last_name"
    t.date     "bdate"
    t.integer  "sex"
    t.string   "city_name"
    t.integer  "city_id"
    t.text     "career"
    t.string   "skype"
    t.string   "facebook"
    t.string   "twitter"
    t.string   "livejournal"
    t.string   "instagram"
    t.string   "mobile_phone"
    t.string   "home_phone"
    t.text     "counters"
    t.integer  "country_id"
    t.string   "country_title"
    t.string   "domain"
    t.integer  "university"
    t.string   "university_name"
    t.integer  "faculty"
    t.string   "faculty_name"
    t.integer  "graduation"
    t.text     "exports"
    t.integer  "followers_count"
    t.integer  "has_mobile"
    t.integer  "last_seen_platform"
    t.string   "home_town"
    t.string   "occupation_type"
    t.integer  "occupation_id"
    t.string   "occupation_name"
    t.text     "personal"
    t.text     "relatives"
    t.integer  "relation"
    t.text     "universities"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

end
