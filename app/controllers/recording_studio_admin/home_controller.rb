# frozen_string_literal: true

module RecordingStudioAdmin
  class HomeController < ApplicationController
    def index
      @root_recording = recording_studio_admin_current_root_recording
      @root_recordable = recording_studio_admin_current_root_recordable
      @current_role = recording_studio_admin_current_role
    end
  end
end
