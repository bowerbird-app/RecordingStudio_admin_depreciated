# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

DUMMY_TEST_FILE = File.expand_path("test/controllers/docs_controller_test.rb", __dir__)
DUMMY_GEMFILE = File.expand_path("test/dummy/Gemfile", __dir__)
DUMMY_APP_ROOT = File.expand_path("test/dummy", __dir__)
ROOT_VENDOR_BUNDLE = File.expand_path("vendor/bundle", __dir__)
ROOT_TEST_EXCLUSIONS = %w[test/controllers/docs_controller_test.rb test/rename_verification_test.rb].freeze
ROOT_TEST_PATH = File.expand_path("test", __dir__)
BUNDLER_KEYS_TO_CLEAR = %w[
  BUNDLE_BIN_PATH
  BUNDLE_LOCKFILE
  BUNDLER_SETUP
  BUNDLER_ORIG_BUNDLE_BIN_PATH
  BUNDLER_ORIG_BUNDLE_GEMFILE
  BUNDLER_ORIG_BUNDLE_LOCKFILE
  BUNDLER_ORIG_BUNDLER_SETUP
  BUNDLER_ORIG_BUNDLER_VERSION
  BUNDLER_VERSION
  RUBYLIB
  RUBYOPT
].freeze

def run_command!(env, *command)
  return if system(env, *command)

  raise "Command failed (#{Process.last_status.exitstatus}): #{command.join(' ')}"
end

def dummy_bundle_env
  dummy_bundle_base_env.merge(dummy_bundle_cleared_env)
end

def dummy_bundle_base_env
  {
    "BUNDLE_APP_CONFIG" => ENV.fetch("BUNDLE_APP_CONFIG", nil),
    "BUNDLE_GEMFILE" => DUMMY_GEMFILE,
    "DISABLE_SIMPLECOV" => "true",
    "GEM_HOME" => ENV.fetch("BUNDLER_ORIG_GEM_HOME", ENV.fetch("GEM_HOME", nil)),
    "GEM_PATH" => ENV.fetch("BUNDLER_ORIG_GEM_PATH", nil)
  }.compact
end

def dummy_bundle_cleared_env
  BUNDLER_KEYS_TO_CLEAR.to_h { |key| [key, nil] }.merge("BUNDLE_GEMFILE" => DUMMY_GEMFILE).compact
end

def preserved_env_value(key)
  ENV.fetch("BUNDLER_ORIG_#{key}", ENV.fetch(key, ""))
end

def isolated_dummy_env
  {
    "PATH" => preserved_env_value("PATH"),
    "GEM_HOME" => preserved_env_value("GEM_HOME"),
    "GEM_PATH" => preserved_env_value("GEM_PATH"),
    "BUNDLE_PATH" => ROOT_VENDOR_BUNDLE,
    "BUNDLE_GEMFILE" => DUMMY_GEMFILE,
    "DISABLE_SIMPLECOV" => "true"
  }
end

def isolated_dummy_test_command
  env_args = isolated_dummy_env.map { |key, value| "#{key}=#{value}" }

  ["env", "-i", *env_args, "bundle", "exec", "ruby", "-I#{ROOT_TEST_PATH}", DUMMY_TEST_FILE]
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"].exclude(*ROOT_TEST_EXCLUSIONS)
  t.verbose = false
end

namespace :test do
  desc "Run rename verification tests to validate gem naming consistency"
  task :rename_verification do
    ruby "test/rename_verification_test.rb", verbose: true
  end

  desc "Run rename verification tests in verbose mode"
  task :rename_verification_verbose do
    ruby "test/rename_verification_test.rb", "--verbose", verbose: true
  end
end

namespace :test do
  desc "Run dummy app integration tests under the dummy app bundle"
  task :dummy do
    Dir.chdir(DUMMY_APP_ROOT) do
      run_command!(dummy_bundle_env, *isolated_dummy_test_command)
    end
  end

  desc "Run gem and dummy app tests"
  task all: %i[test dummy]
end

namespace :app do
  desc "Run all tests for the gem"
  task test: "test:all"
end

task default: :test
