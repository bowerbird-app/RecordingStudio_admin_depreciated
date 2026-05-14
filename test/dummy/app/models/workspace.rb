class Workspace < ApplicationRecord
  if defined?(RecordingStudioAccessible::AllowsAccessibleChildren)
    include RecordingStudioAccessible::AllowsAccessibleChildren
    recording_studio_accessible_children :access
  end

  validates :name, presence: true
end
