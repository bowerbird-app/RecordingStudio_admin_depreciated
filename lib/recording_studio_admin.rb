# frozen_string_literal: true

require "recording_studio"

require "recording_studio_admin/version"
require "recording_studio_admin/labels_compatibility"
require "recording_studio_admin/engine"
require "recording_studio_admin/configuration"

module RecordingStudioAdmin
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def current_actor(controller:)
      configuration.current_actor_for(controller: controller)
    end

    def current_root_recording(controller:, actor:)
      configuration.current_root_recording_for(controller: controller, actor: actor)
    end

    def mounted_page_allowed?(controller:, actor:, root_recording:)
      configuration.allow_mounted_page?(controller: controller, actor: actor, root_recording: root_recording)
    end

    def admin_root_recording?(recording)
      recording.respond_to?(:recordable) && recording.recordable.is_a?(RecordingStudioAdmin::Admin)
    end

    def authorized_for_role?(actor:, root_recording:, role:)
      return false if actor.blank?
      return false if root_recording.blank?
      return false unless admin_root_recording?(root_recording)
      return false unless defined?(RecordingStudioAccessible)

      RecordingStudioAccessible.authorized?(actor: actor, recording: root_recording, role: role)
    end

    def effective_role_for(actor:, root_recording:)
      %i[admin edit view].find do |role|
        authorized_for_role?(actor: actor, root_recording: root_recording, role: role)
      end
    end
  end
end
