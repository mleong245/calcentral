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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "user_data", :force => true do |t|
    t.string   "uid"
    t.string   "preferred_name"
    t.datetime "first_login_at", :null => true
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "user_data", ["uid"], :name => "index_user_data_on_uid", :unique => true

  create_table "widget_data", :force => true do |t|
    t.string   "uid"
    t.string   "widget_id"
    t.text     "data"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "widget_data", ["uid", "widget_id"], :name => "index_widget_data_on_uid_widget_id", :unique => true

  create_table "oauth2_data", :force => true do |t|
    t.string   "uid"
    t.string   "app_id"
    t.text     "access_token"
    t.text     "refresh_token"
    t.integer  "expiration_time", :limit => 8
  end

  add_index "oauth2_data", ["uid", "app_id"], :name => "index_oauth2_data_on_uid_app_id", :unique => true
end
