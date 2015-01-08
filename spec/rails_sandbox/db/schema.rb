# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20121009161700) do

  create_table "categories", force: true do |t|
    t.string   "reference"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories_projects", id: false, force: true do |t|
    t.integer "category_id"
    t.integer "project_id"
  end

  create_table "digitals", force: true do |t|
    t.integer  "owner_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "empties", force: true do |t|
  end

  create_table "loader_releases", force: true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.integer  "version_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "long_and_complex_table_linked_to_versions", force: true do |t|
    t.integer "version_id"
  end

  create_table "milestones", force: true do |t|
    t.string   "name"
    t.datetime "datetime"
    t.decimal  "cost",       precision: 8, scale: 2, default: 0.0
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "owners", force: true do |t|
    t.string   "name"
    t.decimal  "budget"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", force: true do |t|
    t.string   "title"
    t.string   "value_as_string"
    t.text     "value_as_text"
    t.boolean  "value_as_boolean",                          default: false
    t.datetime "value_as_datetime"
    t.integer  "value_as_integer",                          default: 0
    t.decimal  "value_as_double",   precision: 8, scale: 2, default: 0.0
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string "title"
    t.string "first_name"
  end

  create_table "versions", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
