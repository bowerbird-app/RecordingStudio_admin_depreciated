# frozen_string_literal: true

module RecordingStudioAdmin
  class PagesController < ApplicationController
    before_action -> { authorize_recording_studio_admin_role!(:view) }

    def index
      @root_recording = recording_studio_admin_current_root_recording
      @root_recordable = recording_studio_admin_current_root_recordable
      @current_role = recording_studio_admin_current_role
      @current_user_label = if recording_studio_admin_current_actor.respond_to?(:email)
        recording_studio_admin_current_actor.email
      else
        recording_studio_admin_current_actor.to_s
      end
      @access_levels = {
        view: RecordingStudioAdmin.authorized_for_role?(
          actor: recording_studio_admin_current_actor,
          root_recording: @root_recording,
          role: :view
        ),
        edit: RecordingStudioAdmin.authorized_for_role?(
          actor: recording_studio_admin_current_actor,
          root_recording: @root_recording,
          role: :edit
        ),
        admin: RecordingStudioAdmin.authorized_for_role?(
          actor: recording_studio_admin_current_actor,
          root_recording: @root_recording,
          role: :admin
        )
      }
      @pages = [
        {
          title: "View or higher",
          path: recording_studio_admin_home_path,
          minimum_role: :view,
          description: "Visible to anyone who can view the current admin root."
        },
        {
          title: "Edit or higher",
          path: recording_studio_admin.pages_path(scope: recording_studio_admin_current_scope),
          minimum_role: :edit,
          description: "Visible only when the current user can edit within the admin root."
        },
        {
          title: "Admin",
          path: recording_studio_admin_admin_users_path,
          minimum_role: :admin,
          description: "Visible only to admins who can manage root-level access."
        }
      ].select { |page| @access_levels[page[:minimum_role]] }
    end
  end
end