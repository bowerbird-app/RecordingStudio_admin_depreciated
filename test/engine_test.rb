# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def test_register_recordable_type_appends_admin_once
    recording_studio = Module.new
    configuration = Struct.new(:recordable_types).new(["Workspace"])
    recording_studio.define_singleton_method(:configuration) { configuration }

    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) { |&block| to_prepare_blocks << block }

    with_temporary_constant(:RecordingStudio, recording_studio) do
      RecordingStudioAdmin::Engine.stub(:config, config_stub) do
        find_initializer("recording_studio_admin.register_recordable_type").block.call
      end

      to_prepare_blocks.first.call
      to_prepare_blocks.first.call

      assert_equal ["Workspace", "RecordingStudioAdmin::Admin"], configuration.recordable_types
    end
  end

  def test_labels_compatibility_defines_title_for_when_missing
    recording_studio = Module.new

    with_temporary_constant(:RecordingStudio, recording_studio) do
      load File.expand_path("../lib/recording_studio_admin/labels_compatibility.rb", __dir__)

      named_recordable_class = Class.new do
        def self.name
          "ExampleNamespace::WorkspaceRecordable"
        end
      end

      assert_equal "Admin", RecordingStudio::Labels.title_for(Struct.new(:name).new("Admin"))
      assert_equal "Workspace Recordable", RecordingStudio::Labels.title_for(named_recordable_class.new)
    end
  end

  private

  def find_initializer(name)
    RecordingStudioAdmin::Engine.initializers.find { |initializer| initializer.name == name }
  end

  def with_temporary_constant(name, value)
    existed = Object.const_defined?(name)
    original = Object.const_get(name) if existed
    Object.send(:remove_const, name) if existed
    Object.const_set(name, value)
    yield
  ensure
    Object.send(:remove_const, name) if Object.const_defined?(name)
    Object.const_set(name, original) if existed
  end
end
