# frozen_string_literal: true

module RecordingStudioAdmin
  class Admin < ApplicationRecord
    validates :name, presence: true
    validates :key, uniqueness: { case_sensitive: false }, allow_nil: true

    before_validation :normalize_attributes

    private

    def normalize_attributes
      self.name = name.to_s.strip.presence
      self.key = key.to_s.strip.downcase.presence
    end
  end
end
