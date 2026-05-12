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

    @viewer = User.create!(
      email: "viewer@example.com",
      password: TEST_PASSWORD,
      password_confirmation: TEST_PASSWORD
    )

    @workspace_admin = User.create!(
      email: "workspace-admin@example.com",
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

    viewer_access = RecordingStudio::Access.find_or_create_by!(actor: @viewer, role: :view)
    RecordingStudio::Recording.create!(
      root_recording: @admin_root_recording,
      parent_recording: @admin_root_recording,
      recordable: viewer_access
    )

    workspace_admin_access = RecordingStudio::Access.find_or_create_by!(actor: @workspace_admin, role: :admin)
    RecordingStudio::Recording.create!(
      root_recording: @workspace_root_recording,
      parent_recording: @workspace_root_recording,
      recordable: workspace_admin_access
    )

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
    assert_includes response.body, "Pages"
    assert_includes response.body, "Admin users"
    assert_includes response.body, "/recording_studio_accessible/recordings/#{@admin_root_recording.id}/accesses"
    assert_includes response.body, "Admin HQ"
  end

  test "mounted admin page forbids users who only have workspace access" do
    sign_in @workspace_admin

    get "/admin"

    assert_response :forbidden
    assert_includes response.body, "Admin root access required"
    assert_includes response.body, "403 forbidden"
  end

  test "mounted admin page allows admin-root viewers but hides stricter actions" do
    sign_in @viewer

    get "/admin"

    assert_response :success
    assert_includes response.body, "view access"
    assert_includes response.body, "/admin/pages"
    refute_includes response.body, "/recording_studio_accessible/recordings/#{@admin_root_recording.id}/accesses"
  end

  test "pages route renders for admin users on the admin root" do
    get "/admin/pages"

    assert_response :success
    assert_includes response.body, "Admin-root pages can require stronger access"
    assert_includes response.body, "edit or higher"
  end

  test "pages route renders for admin-root viewers and hides stronger cards" do
    sign_in @viewer

    get "/admin/pages"

    assert_response :success
    assert_includes response.body, "Current user access"
    assert_includes response.body, "viewer@example.com"
    assert_includes response.body, "view enabled"
    refute_includes response.body, "Visible only when the current user can edit within the admin root."
    refute_includes response.body, "Visible only to admins who can manage root-level access."
  end

  test "accessible access management renders a visible 403 page for unauthorized users" do
    sign_in @viewer

    get "/recording_studio_accessible/recordings/#{@admin_root_recording.id}/accesses"

    assert_response :forbidden
    assert_includes response.body, "Access management is unavailable"
    assert_includes response.body, "You need admin access on this root to manage users."
    assert_includes response.body, "viewer@example.com"
  end

  test "dummy home page shows current root name and root switcher link" do
    get root_path

    assert_response :success
    assert_includes response.body, "Recording Studio Admin"
    assert_includes response.body, "Admin HQ"
    assert_includes response.body, "/recording_studio_root_switchable/v1/root_switch"
    assert_includes response.body, "scope=all_roots"
    assert_includes response.body, "/admin/?scope=all_roots"
  end

  test "mounted admin page emits canonical admin scope links" do
    get "/admin"

    assert_response :success
    assert_includes response.body, "/admin/pages?scope=all_roots"
    assert_includes response.body, "return_to=%2Fadmin%2F%3Fscope%3Dall_roots"
    assert_includes response.body, "scope=all_roots"
  end

  test "dummy app exposes both admin and workspace roots to accessible queries" do
    roots = RecordingStudioAccessible.root_recordings_for(actor: @user, minimum_role: :view)

    assert_equal [@admin_root_recording.id, @workspace_root_recording.id].sort, roots.map(&:id).sort
    assert_includes roots.map { |recording| recording.recordable.class.name }, "RecordingStudioAdmin::Admin"
    assert_includes roots.map { |recording| recording.recordable.class.name }, "Workspace"
  end
end
