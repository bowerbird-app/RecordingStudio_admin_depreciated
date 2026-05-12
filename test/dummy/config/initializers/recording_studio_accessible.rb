# frozen_string_literal: true

RecordingStudioAccessible.configure do |config|
  config.access_management_current_actor_resolver = ->(controller:) { Current.actor || controller.current_user }
  config.access_management_actor_label = ->(actor) { actor.email }
end

module DummyAccessibleForbiddenPage
  private

  def authorize_access_management!
    return if RecordingStudioAccessible::AccessManagementPolicy.allowed?(
      recording: @recording,
      actor: current_actor,
      controller: self
    )

    render "recording_studio_accessible/recording_accesses/forbidden", status: :forbidden
  end
end

Rails.application.config.to_prepare do
  controller = RecordingStudioAccessible::RecordingAccessesController
  controller.prepend(DummyAccessibleForbiddenPage) unless controller < DummyAccessibleForbiddenPage
end
