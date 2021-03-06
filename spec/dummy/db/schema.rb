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

ActiveRecord::Schema.define(version: 20180526141344) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_clients", force: :cascade do |t|
    t.string "description"
    t.string "token"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_api_clients_on_user_id"
  end

  create_table "assignments", id: :serial, force: :cascade do |t|
    t.text "solution"
    t.integer "exercise_id"
    t.integer "status", default: 0
    t.text "result"
    t.integer "submitter_id"
    t.text "expectation_results"
    t.text "feedback"
    t.text "test_results"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "submissions_count", default: 0, null: false
    t.string "submission_id"
    t.string "queries", default: [], array: true
    t.text "query_results"
    t.text "manual_evaluation_comment"
    t.integer "attemps_count", default: 0
    t.index ["exercise_id"], name: "index_assignments_on_exercise_id"
    t.index ["submission_id"], name: "index_assignments_on_submission_id"
    t.index ["submitter_id"], name: "index_assignments_on_submitter_id"
  end

  create_table "books", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "locale", default: "en"
    t.string "contact_email", default: "info@mumuki.org", null: false
    t.text "description"
    t.string "slug"
    t.index ["slug"], name: "index_books_on_slug", unique: true
  end

  create_table "chapters", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "number", default: 0, null: false
    t.integer "book_id"
    t.integer "topic_id"
  end

  create_table "complements", id: :serial, force: :cascade do |t|
    t.integer "guide_id"
    t.integer "book_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["book_id"], name: "index_complements_on_book_id"
    t.index ["guide_id"], name: "index_complements_on_guide_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "slug"
    t.string "days", array: true
    t.string "code"
    t.string "shifts", array: true
    t.string "period"
    t.string "description"
    t.integer "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "exam_authorizations", force: :cascade do |t|
    t.integer "exam_id"
    t.integer "user_id"
    t.boolean "started", default: false
    t.datetime "started_at"
    t.index ["exam_id"], name: "index_exam_authorizations_on_exam_id"
    t.index ["user_id"], name: "index_exam_authorizations_on_user_id"
  end

  create_table "exams", id: :serial, force: :cascade do |t|
    t.integer "organization_id"
    t.integer "guide_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.string "classroom_id"
    t.integer "duration"
    t.index ["classroom_id"], name: "index_exams_on_classroom_id", unique: true
    t.index ["guide_id"], name: "index_exams_on_guide_id"
    t.index ["organization_id"], name: "index_exams_on_organization_id"
  end

  create_table "exercises", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.text "test"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "language_id", default: 0
    t.integer "submissions_count"
    t.integer "guide_id"
    t.string "locale", default: "en"
    t.text "hint"
    t.text "extra"
    t.integer "number"
    t.text "corollary"
    t.integer "layout", default: 0, null: false
    t.text "expectations"
    t.string "type", default: "Problem", null: false
    t.text "tag_list", default: [], array: true
    t.text "default_content"
    t.integer "bibliotheca_id", null: false
    t.boolean "extra_visible", default: false
    t.boolean "new_expectations", default: false
    t.boolean "manual_evaluation", default: false
    t.integer "editor", default: 0, null: false
    t.string "choices", default: [], null: false, array: true
    t.text "goal"
    t.string "initial_state"
    t.string "final_state"
    t.text "assistance_rules"
    t.index ["guide_id"], name: "index_exercises_on_guide_id"
    t.index ["language_id"], name: "index_exercises_on_language_id"
  end

  create_table "guides", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.string "locale", default: "en"
    t.integer "language_id"
    t.text "extra"
    t.text "corollary"
    t.boolean "beta", default: false
    t.text "expectations"
    t.string "slug", default: "", null: false
    t.integer "type", default: 0, null: false
    t.text "authors"
    t.text "contributors"
    t.index ["name"], name: "index_guides_on_name"
    t.index ["slug"], name: "index_guides_on_slug", unique: true
  end

  create_table "invitations", id: :serial, force: :cascade do |t|
    t.string "code"
    t.string "course"
    t.datetime "expiration_date"
    t.index ["code"], name: "index_invitations_on_code", unique: true
  end

  create_table "languages", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "runner_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "visible_success_output", default: false
    t.integer "output_content_type", default: 0
    t.string "highlight_mode"
    t.text "description"
    t.boolean "queriable", default: false
    t.string "prompt"
    t.boolean "stateful_console", default: false
    t.string "extension", default: "", null: false
    t.boolean "triable", default: false
    t.string "devicon"
    t.string "comment_type", default: "cpp"
    t.string "layout_js_urls", default: [], array: true
    t.string "layout_css_urls", default: [], array: true
    t.string "layout_html_urls", default: [], array: true
    t.string "editor_js_urls", default: [], array: true
    t.string "editor_html_urls", default: [], array: true
    t.string "editor_css_urls", default: [], array: true
    t.index ["name"], name: "index_languages_on_name", unique: true
  end

  create_table "lessons", id: :serial, force: :cascade do |t|
    t.integer "guide_id"
    t.integer "number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "topic_id"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.string "submission_id"
    t.text "content"
    t.string "sender"
    t.datetime "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "read", default: false
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "book_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "settings", default: "{}", null: false
    t.text "theme", default: "{}", null: false
    t.text "profile", default: "{}", null: false
    t.index ["book_id"], name: "index_organizations_on_book_id"
  end

  create_table "paths", id: :serial, force: :cascade do |t|
    t.integer "category_id"
    t.integer "language_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["category_id"], name: "index_paths_on_category_id"
    t.index ["language_id"], name: "index_paths_on_language_id"
  end

  create_table "topics", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "locale"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "appendix"
    t.string "slug"
    t.index ["slug"], name: "index_topics_on_slug", unique: true
  end

  create_table "usages", id: :serial, force: :cascade do |t|
    t.integer "organization_id"
    t.string "slug"
    t.string "item_type"
    t.integer "item_id"
    t.string "parent_item_type"
    t.integer "parent_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["item_type", "item_id"], name: "index_usages_on_item_type_and_item_id"
    t.index ["organization_id"], name: "index_usages_on_organization_id"
    t.index ["parent_item_type", "parent_item_id"], name: "index_usages_on_parent_item_type_and_parent_item_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "provider"
    t.string "social_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email"
    t.datetime "last_submission_date"
    t.string "image_url"
    t.integer "last_exercise_id"
    t.integer "last_organization_id"
    t.string "uid", null: false
    t.text "permissions", default: "{}", null: false
    t.string "first_name"
    t.string "last_name"
    t.boolean "accepts_reminders", default: true
    t.datetime "last_reminded_date"
    t.index ["last_organization_id"], name: "index_users_on_last_organization_id"
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

end
