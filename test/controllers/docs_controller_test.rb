# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "../test_helper"
require_relative "../dummy/config/environment"

require "devise/test/integration_helpers"
require "rails/test_help"

class RecordingStudioAdminDummyTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  TEST_PASSWORD = "DummyTestPassword!2026"

  setup do
    if ActiveRecord::Base.connection.data_source_exists?("recording_studio_root_switchable_selections")
      ActiveRecord::Base.connection.execute("DELETE FROM recording_studio_root_switchable_selections")
    end

    RecordingStudio::Recording.unscoped.delete_all
    RecordingStudio::Access.delete_all
    RecordingStudioAdmin::Admin.delete_all
    Workspace.delete_all
    User.delete_all

    @user = User.create!(
      email: "dummy-test@example.com",
      password: TEST_PASSWORD,
      password_confirmation: TEST_PASSWORD
    )

    @admin_root = RecordingStudioAdmin::Admin.create!(name: "Admin HQ", key: "  HQ  ")
    @workspace = Workspace.create!(name: "Client Workspace")

    @admin_root_recording = RecordingStudio::Recording.create!(recordable: @admin_root)
    @workspace_root_recording = RecordingStudio::Recording.create!(recordable: @workspace)

    [@admin_root_recording, @workspace_root_recording].each do |root_recording|
      access = RecordingStudio::Access.find_or_create_by!(actor: @user, role: :admin)
      RecordingStudio::Recording.create!(
        root_recording: root_recording,
        parent_recording: root_recording,
        recordable: access
      )
    end

    sign_in @user
  end

  test "admin model requires a name and normalizes key" do
    admin = RecordingStudioAdmin::Admin.new(name: " ", key: " MIXED ")

    refute admin.valid?
    assert_includes admin.errors[:name], "can't be blank"

    admin.name = "Admin Root"
    assert admin.valid?
    assert_equal "mixed", admin.key
  end

  test "mounted admin page renders with admin layout and admin users link" do
    get "/admin"

    assert_response :success
    assert_select "title", text: "Recording Studio Admin"
    assert_select "body"
    assert_includes response.body, "RS"
    assert_includes response.body, "Admin users"
    assert_includes response.body, "/recording_studio_accessible/recordings/#{@admin_root_recording.id}/accesses"
    assert_includes response.body, "Admin HQ"
  end

  test "mounted admin page forbids signed-in users without an accessible admin root" do
    limited_user = User.create!(
      email: "limited@example.com",
      password: TEST_PASSWORD,
      password_confirmation: TEST_PASSWORD
    )

    sign_in limited_user

    get "/admin"

    assert_response :forbidden
  end

  test "dummy home page shows current root name and root switcher link" do
    get root_path

    assert_response :success
    assert_includes response.body, "Recording Studio Admin"
    assert_includes response.body, "Admin HQ"
    assert_includes response.body, "/recording_studio_root_switchable/v1/root_switch"
    assert_includes response.body, "scope=all_roots"
    assert_includes response.body, "/admin?scope=all_roots"
  end

  test "mounted admin page falls back to the safe default scope" do
    get "/admin", params: { scope: "unexpected" }

    assert_response :success
    assert_includes response.body, "/admin?scope=all_roots"
    assert_includes response.body, "scope=all_roots"
    refute_includes response.body, "scope=unexpected"
  end

  test "dummy app exposes both admin and workspace roots to accessible queries" do
    roots = RecordingStudioAccessible.root_recordings_for(actor: @user, minimum_role: :view)

    assert_equal [@admin_root_recording.id, @workspace_root_recording.id].sort, roots.map(&:id).sort
    assert_includes roots.map { |recording| recording.recordable.class.name }, "RecordingStudioAdmin::Admin"
    assert_includes roots.map { |recording| recording.recordable.class.name }, "Workspace"
  end
end
