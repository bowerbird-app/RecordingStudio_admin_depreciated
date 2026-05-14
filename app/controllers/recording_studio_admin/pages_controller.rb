# frozen_string_literal: true

module RecordingStudioAdmin
  class PagesController < ApplicationController
    before_action -> { authorize_recording_studio_admin_role!(:view) }

    def index
      @root_recording = recording_studio_admin_current_root_recording
      @root_recordable = recording_studio_admin_current_root_recordable
      @current_role = recording_studio_admin_current_role
      @current_user_label = current_user_label
      @access_levels = access_levels_for(@root_recording)
      @pages = visible_pages(@access_levels)
    end

    private

    def current_user_label
      return recording_studio_admin_current_actor.email if recording_studio_admin_current_actor.respond_to?(:email)

      recording_studio_admin_current_actor.to_s
    end

    def access_levels_for(root_recording)
      {
        view: role_allowed?(root_recording, :view),
        edit: role_allowed?(root_recording, :edit),
        admin: role_allowed?(root_recording, :admin)
      }
    end

    def role_allowed?(root_recording, role)
      RecordingStudioAdmin.authorized_for_role?(
        actor: recording_studio_admin_current_actor,
        root_recording: root_recording,
        role: role
      )
    end

    def visible_pages(access_levels)
      page_definitions.select { |page| access_levels[page[:minimum_role]] }
    end

    def page_definitions
      [view_page, edit_page, admin_page]
    end

    def view_page
      {
        title: "View or higher",
        path: recording_studio_admin_home_path,
        minimum_role: :view,
        description: "Visible to anyone who can view the current admin root."
      }
    end

    def edit_page
      {
        title: "Edit or higher",
        path: recording_studio_admin.pages_path(scope: recording_studio_admin_current_scope),
        minimum_role: :edit,
        description: "Visible only when the current user can edit within the admin root."
      }
    end

    def admin_page
      {
        title: "Admin",
        path: recording_studio_admin_admin_users_path,
        minimum_role: :admin,
        description: "Visible only to admins who can manage root-level access."
      }
    end
  end
end
