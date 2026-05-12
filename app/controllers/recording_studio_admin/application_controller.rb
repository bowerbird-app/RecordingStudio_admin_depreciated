# frozen_string_literal: true

module RecordingStudioAdmin
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception unless defined?(::ApplicationController)

    layout -> { RecordingStudioAdmin.configuration.layout }

    helper_method :recording_studio_admin_current_actor,
                   :recording_studio_admin_current_root_recording,
                   :recording_studio_admin_current_root_recordable,
                   :recording_studio_admin_current_scope,
                   :recording_studio_admin_home_path,
                   :recording_studio_admin_current_root_name,
                   :recording_studio_admin_current_role,
                   :recording_studio_admin_admin_users_path,
                   :recording_studio_admin_admin_users_allowed?,
                   :recording_studio_admin_pages_path,
                   :recording_studio_admin_pages_allowed?,
                   :recording_studio_admin_root_switcher_path

    before_action :set_recording_studio_admin_context
    before_action :authorize_recording_studio_admin_page!

    private

    def set_recording_studio_admin_context
      @recording_studio_admin_current_actor = RecordingStudioAdmin.current_actor(controller: self)
      @recording_studio_admin_current_root_recording = RecordingStudioAdmin.current_root_recording(
        controller: self,
        actor: @recording_studio_admin_current_actor
      )
    end

    def recording_studio_admin_current_actor
      @recording_studio_admin_current_actor
    end

    def recording_studio_admin_current_root_recording
      @recording_studio_admin_current_root_recording
    end

    def recording_studio_admin_current_root_recordable
      recording_studio_admin_current_root_recording&.recordable
    end

    def recording_studio_admin_current_root_name
      recordable = recording_studio_admin_current_root_recordable
      return "No current root" if recordable.blank?

      if recordable.respond_to?(:name) && recordable.name.present?
        recordable.name
      elsif defined?(RecordingStudio::Labels)
        RecordingStudio::Labels.title_for(recordable)
      else
        recordable.to_s
      end
    end

    def recording_studio_admin_home_path
      main_app.root_path
    rescue StandardError
      "/"
    end

    def recording_studio_admin_admin_users_path
      return if recording_studio_admin_current_root_recording.blank?
      return unless respond_to?(:recording_studio_accessible)

      recording_studio_accessible.recording_accesses_path(recording_studio_admin_current_root_recording)
    rescue StandardError
      nil
    end

    def recording_studio_admin_admin_users_allowed?
      RecordingStudioAdmin.authorized_for_role?(
        actor: recording_studio_admin_current_actor,
        root_recording: recording_studio_admin_current_root_recording,
        role: :admin
      )
    end

    def recording_studio_admin_current_scope
      requested_scope = params[:scope].presence
      return configured_root_switchable_scope_keys.first unless requested_scope.present?
      return requested_scope if configured_root_switchable_scope_keys.include?(requested_scope)

      configured_root_switchable_scope_keys.first
    end

    def recording_studio_admin_current_role
      RecordingStudioAdmin.effective_role_for(
        actor: recording_studio_admin_current_actor,
        root_recording: recording_studio_admin_current_root_recording
      )
    end

    def recording_studio_admin_pages_path
      recording_studio_admin.pages_path(scope: recording_studio_admin_current_scope)
    end

    def recording_studio_admin_pages_allowed?
      RecordingStudioAdmin.authorized_for_role?(
        actor: recording_studio_admin_current_actor,
        root_recording: recording_studio_admin_current_root_recording,
        role: :view
      )
    end

    def recording_studio_admin_root_switcher_path
      return unless respond_to?(:recording_studio_root_switchable)

      recording_studio_root_switchable.root_switch_path(
        scope: recording_studio_admin_current_scope,
        return_to: recording_studio_admin.root_path(scope: recording_studio_admin_current_scope)
      )
    rescue StandardError
      nil
    end

    def authorize_recording_studio_admin_page!
      return if RecordingStudioAdmin.mounted_page_allowed?(
        controller: self,
        actor: recording_studio_admin_current_actor,
        root_recording: recording_studio_admin_current_root_recording
      )

      render_access_denied_page(
        title: "Admin root access required",
        subtitle: "This mounted admin area only works for accessible admin roots.",
        message: "Switch to an admin root where you have access, or ask an administrator to grant access to this root.",
        required_role: :view
      )
    end

    def authorize_recording_studio_admin_role!(role)
      return if RecordingStudioAdmin.authorized_for_role?(
        actor: recording_studio_admin_current_actor,
        root_recording: recording_studio_admin_current_root_recording,
        role: role
      )

      render_access_denied_page(
        title: "Higher access required",
        subtitle: "You can reach the admin root, but this page needs a stronger role.",
        message: "This page requires #{role} access or higher for the current admin root.",
        required_role: role
      )
    end

    def render_access_denied_page(title:, subtitle:, message:, required_role:)
      @recording_studio_admin_access_denied_title = title
      @recording_studio_admin_access_denied_subtitle = subtitle
      @recording_studio_admin_access_denied_message = message
      @recording_studio_admin_access_denied_required_role = required_role

      render "recording_studio_admin/shared/access_denied", status: :forbidden
    end

    def configured_root_switchable_scope_keys
      return ["all_roots"] unless defined?(RecordingStudioRootSwitchable) &&
        RecordingStudioRootSwitchable.respond_to?(:configuration)

      Array(RecordingStudioRootSwitchable.configuration.scopes&.keys).map(&:to_s).presence || ["all_roots"]
    end
  end
end
