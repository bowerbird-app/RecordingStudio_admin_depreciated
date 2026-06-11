# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "../test_helper"
require_relative "../dummy/config/environment"

require "devise/test/integration_helpers"
require "rails/test_help"

class RecordingStudioAdminDummyTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.use_transactional_tests = false

  TEST_PASSWORD = "DummyTestPassword!2026"

  setup do
    clear_root_switchable_selections
    clear_dummy_records
    create_users
    create_roots
    create_access_records
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
    assert_includes response.body, 'data-theme="rounded"'
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

  test "dummy-owned pages route renders for admin users on the admin root" do
    get "/admin/pages"

    assert_response :success
    assert_includes response.body, "Admin-root pages can require stronger access"
    assert_includes response.body, "edit or higher"
    assert_includes response.body, "Visible only to admins who can manage root-level access."
  end

  test "dummy-owned pages route renders for admin-root viewers and hides admin-only actions" do
    sign_in @viewer

    get "/admin/pages"

    assert_response :success
    assert_includes response.body, "Current user access"
    assert_includes response.body, "viewer@example.com"
    assert_includes response.body, "view enabled"
    refute_includes response.body, "Visible only when the current user can edit within the admin root."
    refute_includes response.body, "Visible only to admins who can manage root-level access."
  end

  test "dummy tree page renders accessible roots and their nested structure" do
    get tree_path

    assert_response :success
    assert_includes response.body, "Recording tree"
    assert_includes response.body, "Admin HQ"
    assert_includes response.body, "Client Workspace"
    assert_includes response.body, "Access: admin for dummy-test@example.com"
    assert_includes response.body, "Access: view for viewer@example.com"
    assert_includes response.body, ">Tree<"
  end

  test "dummy config page renders setup steps and code snippets" do
    get config_path

    assert_response :success
    assert_includes response.body, "Configuration guide"
    assert_includes response.body, "Gemfile"
    assert_includes response.body, "app/controllers/application_controller.rb"
    assert_includes response.body, "config/routes.rb"
    assert_includes response.body, "config/initializers/recording_studio_accessible.rb"
    assert_includes response.body, "recording_studio_admin"
    assert_includes response.body, "recording_studio_recordable"
    assert_includes response.body, "RecordingStudio.enable_capability(:accessible, on: self)"
    assert_includes response.body, "before_action { Current.actor = current_user }"
    assert_includes response.body, "mount RecordingStudioAdmin::Engine"
    assert_includes response.body, "config.access_management_current_actor_resolver"
    assert_includes response.body, "RecordingStudio.root_recording_for(admin)"
    assert_includes response.body, ">Config<"
  end

  test "accessible access management redirects unauthorized users home with an alert" do
    sign_in @viewer

    get "/recording_studio_accessible/recordings/#{@admin_root_recording.id}/accesses"

    assert_redirected_to "/"

    follow_redirect!

    assert_response :success
    assert_includes response.body, 'data-theme="rounded"'
    assert_includes response.body, "You are not allowed to manage access for this root."
    assert_includes response.body, "Recording Studio Admin"
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

  test "root switcher page uses the rounded dummy layout" do
    get "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_roots",
      return_to: "/"
    }

    assert_response :success
    assert_includes response.body, 'data-theme="rounded"'
    assert_includes response.body, "Change"
  end

  test "mounted admin page emits canonical admin scope links" do
    get "/admin"

    assert_response :success
    assert_includes response.body, "/admin/pages?scope=all_roots"
    assert_includes response.body, "return_to=%2Fadmin%2F%3Fscope%3Dall_roots"
    assert_includes response.body, "scope=all_roots"
  end

  test "engine routes only expose the mounted index" do
    engine_routes = RecordingStudioAdmin::Engine.routes.routes.filter_map do |route|
      route.path.spec.to_s if route.verb&.match?("GET")
    end

    assert_includes engine_routes, "/"
    refute_includes engine_routes, "/pages(.:format)"
  end

  test "dummy app exposes both admin and workspace roots to accessible queries" do
    roots = RecordingStudioAccessible.root_recordings_for(actor: @user, minimum_role: :view)

    assert_equal [@admin_root_recording.id, @workspace_root_recording.id].sort, roots.map(&:id).sort
    assert_includes roots.map { |recording| recording.recordable.class.name }, "RecordingStudioAdmin::Admin"
    assert_includes roots.map { |recording| recording.recordable.class.name }, "Workspace"
  end

  private

  def clear_root_switchable_selections
    return unless ActiveRecord::Base.connection.data_source_exists?("recording_studio_root_switchable_selections")

    ActiveRecord::Base.connection.execute("DELETE FROM recording_studio_root_switchable_selections")
  end

  def clear_dummy_records
    RecordingStudio::Recording.unscoped.delete_all
    RecordingStudio::Access.delete_all
    RecordingStudioAdmin::Admin.delete_all
    Workspace.delete_all
    User.delete_all
  end

  def create_users
    @user = create_user("dummy-test@example.com")
    @viewer = create_user("viewer@example.com")
    @workspace_admin = create_user("workspace-admin@example.com")
  end

  def create_user(email)
    User.create!(
      email: email,
      password: TEST_PASSWORD,
      password_confirmation: TEST_PASSWORD
    )
  end

  def create_roots
    @admin_root = RecordingStudioAdmin::Admin.create!(name: "Admin HQ", key: "  HQ  ")
    @workspace = Workspace.create!(name: "Client Workspace")
    @admin_root_recording = RecordingStudio.root_recording_for(@admin_root)
    @workspace_root_recording = RecordingStudio.root_recording_for(@workspace)
  end

  def create_access_records
    create_root_admin_accesses
    create_viewer_access
    create_workspace_admin_access
  end

  def create_root_admin_accesses
    [@admin_root_recording, @workspace_root_recording].each do |root_recording|
      bootstrap_access(actor: @user, role: :admin, parent_recording: root_recording)
    end
  end

  def create_viewer_access
    grant_access(
      actor: @viewer,
      role: :view,
      recording: @admin_root_recording,
      manager_actor: @user
    )
  end

  def create_workspace_admin_access
    grant_access(
      actor: @workspace_admin,
      role: :admin,
      recording: @workspace_root_recording,
      manager_actor: @user
    )
  end

  def bootstrap_access(actor:, role:, parent_recording:)
    RecordingStudioAccessible::AccessCreationContext.allow do
      RecordingStudio.root_recording_or_self(parent_recording).record(
        RecordingStudio::Access,
        actor: actor,
        parent_recording: parent_recording
      ) do |access|
        access.actor = actor
        access.role = role
      end
    end
  end

  def grant_access(actor:, role:, recording:, manager_actor:)
    result = RecordingStudioAccessible.grant_access(
      recording: recording,
      actor: actor,
      role: role,
      manager_actor: manager_actor
    )

    return result if result.success?

    raise Array(result.errors).presence || result.error || "Could not grant #{role} access"
  end
end
