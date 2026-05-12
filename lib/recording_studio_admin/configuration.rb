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

    def call(callable, **kwargs)
      return callable.call(**kwargs) if callable.respond_to?(:call)

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
      return controller.current_root_recording if controller.respond_to?(:current_root_recording, true) &&
        controller.current_root_recording.present?

      return if actor.blank? || !defined?(RecordingStudioAccessible)

      root_recording_id = controller.params[:root_recording_id].presence
      if root_recording_id.present?
        return RecordingStudioAccessible.root_recordings_for(actor: actor, minimum_role: :view).find do |recording|
          recording.id.to_s == root_recording_id.to_s
        end
      end

      accessible_roots = RecordingStudioAccessible.root_recordings_for(actor: actor, minimum_role: :view)
      accessible_roots.find do |recording|
        RecordingStudioAdmin.admin_root_recording?(recording)
      end || accessible_roots.first
    end

    def default_allow_mounted_page?(actor:, root_recording:, **)
      return false if actor.blank?
      return false if root_recording.blank?
      return false unless defined?(RecordingStudioAccessible)

      RecordingStudioAccessible.authorized?(actor: actor, recording: root_recording, role: :admin)
    end
  end
end
