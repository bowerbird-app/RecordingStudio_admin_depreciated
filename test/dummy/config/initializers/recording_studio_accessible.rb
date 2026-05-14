# frozen_string_literal: true

require "recording_studio_accessible"

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

    redirect_to main_app.root_path, alert: "You are not allowed to manage access for this root."
  end
end

Rails.application.config.to_prepare do
  controller = RecordingStudioAccessible::RecordingAccessesController
  controller.prepend(DummyAccessibleForbiddenPage) unless controller < DummyAccessibleForbiddenPage
end
