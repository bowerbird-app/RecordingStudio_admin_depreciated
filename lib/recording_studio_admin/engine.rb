# frozen_string_literal: true

module RecordingStudioAdmin
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioAdmin

    initializer "recording_studio_admin.register_recordable_type" do
      config.to_prepare do
        RecordingStudioAdmin::Engine.send(:register_recordable_type!)
        RecordingStudioAdmin::Engine.send(:enable_accessible_children!)
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

      def enable_accessible_children!
        return unless defined?(RecordingStudioAccessible::AllowsAccessibleChildren)
        return unless defined?(RecordingStudioAdmin::Admin)

        unless RecordingStudioAdmin::Admin < RecordingStudioAccessible::AllowsAccessibleChildren
          RecordingStudioAdmin::Admin.include(RecordingStudioAccessible::AllowsAccessibleChildren)
        end

        return if RecordingStudioAdmin::Admin.instance_variable_defined?(
          :@recording_studio_admin_accessible_children_enabled
        )

        RecordingStudioAdmin::Admin.recording_studio_accessible_children(:access)
        RecordingStudioAdmin::Admin.instance_variable_set(:@recording_studio_admin_accessible_children_enabled, true)
      end
    end
  end
end
