# frozen_string_literal: true

require "test_helper"

class RecordingStudioAdminTest < Minitest::Test
  def test_public_api_exposes_configuration_and_helpers
    assert_respond_to RecordingStudioAdmin, :configuration
    assert_respond_to RecordingStudioAdmin, :configure
    assert_respond_to RecordingStudioAdmin, :admin_root_recording?
  end

  def test_version_exists
    refute_nil RecordingStudioAdmin::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, RecordingStudioAdmin::Engine
  end

  def test_admin_model_validates_name_and_normalizes_key
    model_source = File.read(File.expand_path("../app/models/recording_studio_admin/admin.rb", __dir__))

    assert_includes model_source, "validates :name, presence: true"
    assert_includes model_source, "self.key = key.to_s.strip.downcase.presence"
  end

  def test_engine_layout_and_home_view_use_flatpack_components
    layout_source = File.read(
      File.expand_path("../app/views/layouts/recording_studio_admin/application.html.erb", __dir__)
    )
    view_source = File.read(File.expand_path("../app/views/recording_studio_admin/home/index.html.erb", __dir__))

    assert_includes layout_source, "FlatPack::SidebarLayout::Component"
    assert_includes view_source, "FlatPack::PageTitle::Component"
    assert_includes view_source, "FlatPack::Card::Component"
    assert_includes view_source, "FlatPack::Badge::Component"
    assert_includes view_source, 'text: "Admin users"'
  end

  def test_dummy_top_nav_mentions_root_switcher
    top_nav_source = File.read(File.expand_path("dummy/app/views/layouts/flat_pack/_top_nav.html.erb", __dir__))

    assert_includes top_nav_source, "Switch root"
    assert_includes top_nav_source, "current_root_name"
  end

  def test_dummy_readme_describes_admin_and_workspace_roots
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "RecordingStudioAdmin::Admin"
    assert_includes readme_source, "Workspace"
    assert_includes readme_source, "/admin"
  end
end
