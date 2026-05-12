module ApplicationHelper
  def current_root_name
    recordable = current_root_recordable
    return "No current root" if recordable.blank?

    if recordable.respond_to?(:name) && recordable.name.present?
      recordable.name
    elsif defined?(RecordingStudio::Labels)
      RecordingStudio::Labels.title_for(recordable)
    else
      recordable.to_s
    end
  end
end
