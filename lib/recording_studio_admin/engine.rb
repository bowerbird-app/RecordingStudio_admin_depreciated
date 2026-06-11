# frozen_string_literal: true

module RecordingStudioAdmin
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioAdmin

    initializer "recording_studio_admin.register_recordable_type" do
      config.to_prepare do
        RecordingStudioAdmin::Engine.send(:register_recordable_type!)
      end
    end

    class << self
      private

      def register_recordable_type!
        return unless defined?(RecordingStudio) && RecordingStudio.respond_to?(:configuration)

        recordable_types = Array(RecordingStudio.configuration.recordable_types).map(&:to_s)
        return if recordable_types.include?("RecordingStudioAdmin::Admin")

        RecordingStudio.configuration.recordable_types = recordable_types + ["RecordingStudioAdmin::Admin"]
      end
    end
  end
end
