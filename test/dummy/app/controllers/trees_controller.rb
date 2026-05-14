# frozen_string_literal: true

class TreesController < ApplicationController
  helper_method :recording_label, :children_for

  def index
    @root_recordings = Array(RecordingStudioAccessible.root_recordings_for(actor: current_user, minimum_role: :view))
      .sort_by(&:created_at)

    ActiveRecord::Associations::Preloader.new(records: @root_recordings, associations: :recordable).call

    @child_recordings_by_parent_id = RecordingStudio::Recording.where(root_recording_id: @root_recordings.map(&:id))
      .includes(:recordable)
      .order(:created_at)
      .group_by(&:parent_recording_id)
  end

  private

  def children_for(recording)
    @child_recordings_by_parent_id.fetch(recording.id, [])
  end

  def recording_label(recording)
    recordable = recording.recordable

    case recordable
    when RecordingStudio::Access
      actor_label = if recordable.actor.respond_to?(:email)
        recordable.actor.email
      else
        recordable.actor.to_s
      end

      "Access: #{recordable.role} for #{actor_label}"
    else
      return recordable.name if recordable.respond_to?(:name) && recordable.name.present?
      return RecordingStudio::Labels.title_for(recordable) if defined?(RecordingStudio::Labels)

      recordable.to_s
    end
  end
end