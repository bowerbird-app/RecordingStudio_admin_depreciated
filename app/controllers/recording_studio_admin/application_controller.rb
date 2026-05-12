# frozen_string_literal: true

module RecordingStudioAdmin
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception unless defined?(::ApplicationController)

    layout -> { RecordingStudioAdmin.configuration.layout }

    helper_method :recording_studio_admin_current_actor,
                   :recording_studio_admin_current_root_recording,
                   :recording_studio_admin_current_root_recordable,
                   :recording_studio_admin_current_scope,
                   :recording_studio_admin_current_root_name,
                   :recording_studio_admin_admin_users_path,
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

    def recording_studio_admin_admin_users_path
      return if recording_studio_admin_current_root_recording.blank?
      return unless respond_to?(:recording_studio_accessible)

      recording_studio_accessible.recording_accesses_path(recording_studio_admin_current_root_recording)
    rescue StandardError
      nil
    end

    def recording_studio_admin_current_scope
      requested_scope = params[:scope].presence
      return configured_root_switchable_scope_keys.first unless requested_scope.present?
      return requested_scope if configured_root_switchable_scope_keys.include?(requested_scope)

      configured_root_switchable_scope_keys.first
    end

    def recording_studio_admin_root_switcher_path
      return unless respond_to?(:recording_studio_root_switchable)

      recording_studio_root_switchable.root_switch_path(
        scope: recording_studio_admin_current_scope,
        return_to: main_app.recording_studio_admin.root_path(scope: recording_studio_admin_current_scope)
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

      head :forbidden
    end

    def configured_root_switchable_scope_keys
      return ["all_roots"] unless defined?(RecordingStudioRootSwitchable) &&
        RecordingStudioRootSwitchable.respond_to?(:configuration)

      Array(RecordingStudioRootSwitchable.configuration.scopes&.keys).map(&:to_s).presence || ["all_roots"]
    end
  end
end
