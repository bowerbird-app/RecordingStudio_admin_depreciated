# frozen_string_literal: true

source "https://rubygems.org"

# Runtime dependencies resolved from git in development until they are available via the configured gem source.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.33"
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v0.1.0-alpha"

# Specify your gem's dependencies in recording_studio_admin.gemspec
gem "devise"
gemspec

gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
