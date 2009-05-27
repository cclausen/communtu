# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 2008122700000000) do

  create_table "base_packages", :force => true do |t|
    t.string   "type"
    t.string   "name"
    t.string   "section",                          :default => "unknown"
    t.text     "description"
    t.integer  "category_id",        :limit => 11
    t.integer  "license_type",       :limit => 11
    t.integer  "user_id",            :limit => 11
    t.integer  "published",          :limit => 11, :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "urls"
    t.string   "fullsection"
    t.string   "icon_file"
    t.boolean  "is_program"
    t.integer  "popcon",             :limit => 11
    t.boolean  "default_install"
    t.integer  "security_type",      :limit => 11
    t.string   "version"
    t.string   "debianized_version"
  end

  create_table "cart_contents", :force => true do |t|
    t.integer  "cart_id",         :limit => 11
    t.integer  "base_package_id", :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "carts", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "parent_id",   :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "link"
  end

  create_table "comments", :force => true do |t|
    t.integer  "user_id",        :limit => 11
    t.integer  "metapackage_id", :limit => 11, :default => 0
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "debs", :force => true do |t|
    t.integer  "metapackage_id",  :limit => 11
    t.integer  "distribution_id", :limit => 11
    t.integer  "derivative_id",   :limit => 11
    t.integer  "license_type",    :limit => 11
    t.integer  "security_type",   :limit => 11
    t.string   "version"
    t.string   "url"
    t.boolean  "generated"
    t.boolean  "outdated"
    t.string   "errmsg"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "log"
  end

  create_table "dependencies", :force => true do |t|
    t.integer  "package_distr_id", :limit => 11
    t.integer  "base_package_id",  :limit => 11
    t.integer  "dep_type",         :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "derivatives", :force => true do |t|
    t.string   "name"
    t.string   "icon_file"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sudo"
    t.string   "dialog"
  end

  create_table "distributions", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "short_name"
    t.string   "url"
  end

  create_table "folders", :force => true do |t|
    t.integer  "user_id",    :limit => 11
    t.integer  "parent_id",  :limit => 11
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "languages", :force => true do |t|
    t.string   "name"
    t.string   "country_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "message_copies", :force => true do |t|
    t.integer  "recipient_id", :limit => 11
    t.integer  "message_id",   :limit => 11
    t.integer  "folder_id",    :limit => 11
    t.boolean  "is_read",                    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.integer  "author_id",  :limit => 11
    t.string   "subject"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "metacontents", :force => true do |t|
    t.integer  "metapackage_id",  :limit => 11
    t.integer  "base_package_id", :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "metacontents_derivatives", :force => true do |t|
    t.integer  "metacontent_id", :limit => 11
    t.integer  "derivative_id",  :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "metacontents_distrs", :force => true do |t|
    t.integer  "metacontent_id",  :limit => 11
    t.integer  "distribution_id", :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "package_distrs", :force => true do |t|
    t.integer  "package_id",      :limit => 11
    t.integer  "distribution_id", :limit => 11
    t.integer  "repository_id",   :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version"
    t.string   "filename"
    t.integer  "size",            :limit => 11
    t.integer  "installedsize",   :limit => 11
  end

  create_table "permissions", :force => true do |t|
    t.integer  "role_id",    :limit => 11, :null => false
    t.integer  "user_id",    :limit => 11, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "repositories", :force => true do |t|
    t.integer  "distribution_id", :limit => 11
    t.integer  "security_type",   :limit => 11
    t.integer  "license_type",    :limit => 11
    t.string   "url"
    t.string   "subtype"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "gpgkey"
  end

  create_table "roles", :force => true do |t|
    t.string   "rolename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translations", :force => true do |t|
    t.integer  "language_id", :limit => 11
    t.string   "tag"
    t.text     "contents"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "umfrage_packages", :force => true do |t|
    t.integer  "umfrage_id", :limit => 11
    t.string   "package"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "umfrage_sources", :force => true do |t|
    t.integer  "umfrage_id", :limit => 11
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "umfrages", :force => true do |t|
    t.boolean  "einsteiger"
    t.boolean  "freak"
    t.boolean  "sammler"
    t.boolean  "musik"
    t.boolean  "video"
    t.boolean  "netz"
    t.boolean  "grafik"
    t.boolean  "spiele"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_packages", :force => true do |t|
    t.integer  "user_id",     :limit => 11
    t.integer  "package_id",  :limit => 11
    t.boolean  "is_selected"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_profiles", :force => true do |t|
    t.integer  "user_id",     :limit => 11
    t.integer  "category_id", :limit => 11
    t.integer  "rating",      :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "password_reset_code",       :limit => 40
    t.boolean  "enabled",                                 :default => true
    t.integer  "license",                   :limit => 11, :default => 1
    t.integer  "security",                  :limit => 11, :default => 2
    t.integer  "distribution_id",           :limit => 11, :default => 2
    t.integer  "language_id",               :limit => 11, :default => 1
    t.integer  "first_login",               :limit => 11, :default => 1
    t.integer  "template_id",               :limit => 11
    t.integer  "derivative_id",             :limit => 11
    t.integer  "profile_version",           :limit => 11
    t.boolean  "profile_changed",                         :default => false
    t.boolean  "anonymous",                               :default => false
  end

  create_table "videos", :force => true do |t|
    t.integer  "base_package_id", :limit => 11
    t.string   "url"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end