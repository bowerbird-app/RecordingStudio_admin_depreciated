class AdminPagesController < ApplicationController
  before_action :set_recording_studio_admin_context
  before_action :authorize_admin_root_access!
  before_action -> { authorize_admin_role!(:view) }

  def index
    @root_recording = @recording_studio_admin_current_root_recording
    @root_recordable = @root_recording&.recordable
    @current_role = RecordingStudioAdmin.effective_role_for(
      actor: current_user,
      root_recording: @root_recording
    )
    @current_user_label = current_user.respond_to?(:email) ? current_user.email : current_user.to_s
    @access_levels = {
      view: RecordingStudioAdmin.authorized_for_role?(
        actor: current_user,
        root_recording: @root_recording,
        role: :view
      ),
      edit: RecordingStudioAdmin.authorized_for_role?(
        actor: current_user,
        root_recording: @root_recording,
        role: :edit
      ),
      admin: RecordingStudioAdmin.authorized_for_role?(
        actor: current_user,
        root_recording: @root_recording,
        role: :admin
      )
    }
    @pages = [
      {
        title: "View or higher",
        path: root_path,
        minimum_role: :view,
        description: "Visible to anyone who can view the current admin root."
      },
      {
        title: "Edit or higher",
        path: admin_pages_path(scope: current_scope),
        minimum_role: :edit,
        description: "Visible only when the current user can edit within the admin root."
      },
      {
        title: "Admin",
        path: recording_studio_accessible.recording_accesses_path(@root_recording),
        minimum_role: :admin,
        description: "Visible only to admins who can manage root-level access."
      }
    ].select { |page| @access_levels[page[:minimum_role]] }
  end

  private

  def set_recording_studio_admin_context
    @recording_studio_admin_current_root_recording = RecordingStudioAdmin.current_root_recording(
      controller: self,
      actor: current_user
    )
  end

  def authorize_admin_root_access!
    return if RecordingStudioAdmin.mounted_page_allowed?(
      controller: self,
      actor: current_user,
      root_recording: @recording_studio_admin_current_root_recording
    )

    render_forbidden(
      title: "Admin root access required",
      subtitle: "This host-owned page still requires an accessible admin root.",
      message: "Switch to an admin root where you have access, or ask an administrator to grant access to this root.",
      required_role: :view
    )
  end

  def authorize_admin_role!(role)
    return if RecordingStudioAdmin.authorized_for_role?(
      actor: current_user,
      root_recording: @recording_studio_admin_current_root_recording,
      role: role
    )

    render_forbidden(
      title: "Higher access required",
      subtitle: "You can reach the admin root, but this page needs a stronger role.",
      message: "This page requires #{role} access or higher for the current admin root.",
      required_role: role
    )
  end

  def render_forbidden(title:, subtitle:, message:, required_role:)
    @recording_studio_admin_access_denied_title = title
    @recording_studio_admin_access_denied_subtitle = subtitle
    @recording_studio_admin_access_denied_message = message
    @recording_studio_admin_access_denied_required_role = required_role

    render "recording_studio_admin/shared/access_denied", status: :forbidden
  end

  def current_scope
    requested_scope = params[:scope].presence
    configured_scopes = Array(RecordingStudioRootSwitchable.configuration.scopes&.keys).map(&:to_s).presence || ["all_roots"]
    return configured_scopes.first if requested_scope.blank?
    return requested_scope if configured_scopes.include?(requested_scope)

    configured_scopes.first
  end
end