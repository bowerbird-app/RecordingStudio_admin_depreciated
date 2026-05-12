# frozen_string_literal: true

require "recording_studio"

require "recording_studio_admin/version"
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
      recording&.recordable.is_a?(RecordingStudioAdmin::Admin)
    end
  end
end
