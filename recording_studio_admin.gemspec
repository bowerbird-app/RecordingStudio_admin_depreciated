# frozen_string_literal: true

require_relative "lib/recording_studio_admin/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_admin"
  spec.version     = RecordingStudioAdmin::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_admin"
  spec.summary     = "Minimal admin-root addon for RecordingStudio"
  spec.description = "Adds a lightweight RecordingStudioAdmin::Admin root recordable, " \
                     "a small mounted admin page, and lightweight install and migration generators."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "flat_pack"
  spec.add_dependency "importmap-rails"
  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio"
  spec.add_dependency "tailwindcss-rails"
end
