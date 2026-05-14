# frozen_string_literal: true

module RecordingStudioAdmin
  class Configuration
    attr_accessor :layout
    attr_writer :current_actor_resolver, :current_root_recording_resolver, :mounted_page_authorizer

    def initialize
      @layout = "recording_studio_admin/application"
    end

    def current_actor_for(controller:)
      call(@current_actor_resolver || method(:default_current_actor_for), controller: controller)
    end

    def current_root_recording_for(controller:, actor:)
      call(
        @current_root_recording_resolver || method(:default_current_root_recording_for),
        controller: controller,
        actor: actor
      )
    end

    def allow_mounted_page?(controller:, actor:, root_recording:)
      call(
        @mounted_page_authorizer || method(:default_allow_mounted_page?),
        controller: controller,
        actor: actor,
        root_recording: root_recording
      )
    end

    private

    def call(callable, **)
      return callable.call(**) if callable.respond_to?(:call)

      callable
    end

    def default_current_actor_for(controller:)
      if defined?(Current) && Current.respond_to?(:actor) && Current.actor.present?
        Current.actor
      elsif controller.respond_to?(:current_user, true)
        controller.current_user
      end
    end

    def default_current_root_recording_for(controller:, actor:)
      current_root = current_root_recording_from(controller)
      return current_root if controller_current_root_recording?(current_root)
      return unless accessible_root_lookup_available?(actor)

      accessible_roots = accessible_root_recordings_for(actor)
      requested_root_recording_from(controller:, accessible_roots: accessible_roots) ||
        admin_root_recording_from(accessible_roots) ||
        accessible_roots.first
    end

    def default_allow_mounted_page?(actor:, root_recording:, **)
      RecordingStudioAdmin.authorized_for_role?(actor: actor, root_recording: root_recording, role: :view)
    end

    def current_root_recording_from(controller)
      return unless controller.respond_to?(:current_root_recording, true)

      controller.current_root_recording
    end

    def controller_current_root_recording?(current_root)
      current_root.present? && (
        !current_root.respond_to?(:recordable) ||
        RecordingStudioAdmin.admin_root_recording?(current_root)
      )
    end

    def accessible_root_recordings_for(actor)
      RecordingStudioAccessible.root_recordings_for(actor: actor, minimum_role: :view)
    end

    def accessible_root_lookup_available?(actor)
      actor.present? && defined?(RecordingStudioAccessible)
    end

    def requested_root_recording_from(controller:, accessible_roots:)
      root_recording_id = controller.params[:root_recording_id].presence
      return if root_recording_id.blank?

      accessible_roots.find { |recording| recording.id.to_s == root_recording_id.to_s }
    end

    def admin_root_recording_from(accessible_roots)
      accessible_roots.find { |recording| RecordingStudioAdmin.admin_root_recording?(recording) }
    end
  end
end
