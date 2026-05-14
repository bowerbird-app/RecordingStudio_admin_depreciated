# frozen_string_literal: true

RecordingStudioAdmin.configure do |config|
  config.current_actor_resolver = ->(controller:) { Current.actor || controller.current_user }
  config.current_root_recording_resolver = ->(controller:, **) { controller.current_root_recording }
end
