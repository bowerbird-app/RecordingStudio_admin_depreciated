# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def test_defaults_current_actor_to_current_actor_then_current_user
    actor = Object.new
    controller = Struct.new(:current_user).new(:user)

    current_class = Class.new do
      class << self
        attr_accessor :actor
      end
    end
    current_class.actor = actor

    with_temporary_constant(:Current, current_class) do
      assert_equal actor, RecordingStudioAdmin::Configuration.new.current_actor_for(controller: controller)
    end
  end

  def test_defaults_current_root_recording_to_controller_method
    root_recording = Object.new
    controller = Struct.new(:params) do
      def current_root_recording
        :root_recording
      end
    end.new({})

    assert_equal(
      :root_recording,
      RecordingStudioAdmin::Configuration.new.current_root_recording_for(
        controller: controller,
        actor: root_recording
      )
    )
  end

  def test_custom_authorizer_is_used
    configuration = RecordingStudioAdmin::Configuration.new
    configuration.mounted_page_authorizer = ->(actor:, **) { actor == :allowed }

    assert configuration.allow_mounted_page?(controller: Object.new, actor: :allowed, root_recording: nil)
    refute configuration.allow_mounted_page?(controller: Object.new, actor: :blocked, root_recording: nil)
  end

  def test_default_authorizer_requires_a_root_recording
    configuration = RecordingStudioAdmin::Configuration.new

    refute configuration.allow_mounted_page?(controller: Object.new, actor: :allowed, root_recording: nil)
  end

  def test_default_root_resolver_ignores_param_without_accessible_integration
    controller = Struct.new(:params).new({ root_recording_id: "123" })

    assert_nil RecordingStudioAdmin::Configuration.new.current_root_recording_for(
      controller: controller,
      actor: :allowed
    )
  end

  private

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
