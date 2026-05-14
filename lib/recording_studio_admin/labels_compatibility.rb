# frozen_string_literal: true

unless defined?(RecordingStudio::Labels)
  module RecordingStudio
    module Labels
      class << self
        def title_for(recordable)
          return "" if recordable.nil?

          if recordable.respond_to?(:name) && recordable.name.present?
            recordable.name
          elsif recordable.class.respond_to?(:model_name)
            recordable.class.model_name.human
          else
            recordable.class.name.to_s.demodulize.titleize
          end
        end
      end
    end
  end
end
