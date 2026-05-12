# frozen_string_literal: true

RecordingStudioAccessible.configure do |config|
  config.access_management_current_actor_resolver = ->(controller:) { Current.actor || controller.current_user }
  config.access_management_actor_label = ->(actor) { actor.email }
end
