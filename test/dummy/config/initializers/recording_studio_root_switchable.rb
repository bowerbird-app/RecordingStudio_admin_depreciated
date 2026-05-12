# frozen_string_literal: true

RecordingStudioRootSwitchable.configure do |config|
  config.current_actor_resolver = ->(controller:) { Current.actor || controller.current_user }

  config.scope :all_roots do |scope|
    scope.label = "All roots"
    scope.description = "Admin and standard roots available to the current actor"
    scope.available_roots = lambda do |actor:, **|
      RecordingStudioAccessible.root_recordings_for(actor: actor, minimum_role: :view)
    end
    scope.default_root = lambda do |roots:, **|
      roots.find { |recording| recording.recordable.is_a?(RecordingStudioAdmin::Admin) } || roots.first
    end
  end
end
