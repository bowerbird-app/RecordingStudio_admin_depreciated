# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require "generators/recording_studio_admin/install/install_generator"
require "generators/recording_studio_admin/migrations/migrations_generator"

class InstallGeneratorTest < Minitest::Test
  INSTALL_TEMPLATE_PATH = File.expand_path(
    "../lib/generators/recording_studio_admin/install/templates/INSTALL.md",
    __dir__
  )

  def with_temp_app
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "app/assets/tailwind"))
      FileUtils.mkdir_p(File.join(dir, "db/migrate"))
      yield dir
    end
  end

  def build_install_generator(destination_root, options = {})
    RecordingStudioAdmin::Generators::InstallGenerator.new(
      [],
      options,
      destination_root: destination_root
    )
  end

  def build_migrations_generator(destination_root, options = {})
    RecordingStudioAdmin::Generators::MigrationsGenerator.new(
      [],
      options,
      destination_root: destination_root
    )
  end

  def test_mount_engine_uses_default_admin_path
    generator = build_install_generator("/tmp")
    routes = []

    generator.stub(:route, ->(value) { routes << value }) do
      generator.mount_engine
    end

    assert_equal ['mount RecordingStudioAdmin::Engine, at: "/admin"'], routes
  end

  def test_add_tailwind_source_injects_engine_and_flatpack_sources
    with_temp_app do |dir|
      css_path = File.join(dir, "app/assets/tailwind/application.css")
      File.write(css_path, "@import \"tailwindcss\";\n")

      generator = build_install_generator(dir)

      Rails.stub(:root, Pathname.new(dir)) do
        generator.stub(:say, nil) do
          generator.add_tailwind_source
        end
      end

      css = File.read(css_path)
      assert_includes css, '@source "../../vendor/bundle/**/recording_studio_admin/app/views/**/*.erb";'
      assert_includes css, '@source "../../vendor/bundle/**/flat_pack/app/components/**/*.{rb,erb}";'
      assert_includes css, '@source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/flat_pack-*/app/components/**/*.{rb,erb}";'
      assert_includes css, '@source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/flatpack-*/app/components/**/*.{rb,erb}";'
    end
  end

  def test_install_initializer_keeps_safe_defaults_and_checks_current_safely
    initializer_template =
      "../lib/generators/recording_studio_admin/install/templates/recording_studio_admin_initializer.rb"
    initializer = File.read(File.expand_path(initializer_template, __dir__))

    assert_includes initializer, "defined?(Current)"
    refute_includes initializer, "current_root_recording_resolver"
  end

  def test_install_guide_mentions_current_actor_and_optional_root_switcher
    install_guide = File.read(INSTALL_TEMPLATE_PATH)

    assert_includes install_guide, "Current.actor"
    assert_includes install_guide, "RecordingStudioRootSwitchable"
    assert_includes install_guide, "recording_studio_admin:migrations"
  end

  def test_migrations_generator_copies_admin_migration
    with_temp_app do |dir|
      generator = build_migrations_generator(dir)

      generator.stub(:say, nil) do
        generator.copy_migrations
      end

      migrations = Dir.glob(File.join(dir, "db/migrate/*_create_recording_studio_admin_admins.rb"))
      assert_equal 1, migrations.size
      assert_includes File.read(migrations.first), "create_table :recording_studio_admin_admins"
    end
  end

  def test_migrations_generator_skips_existing_migration_name
    with_temp_app do |dir|
      File.write(
        File.join(dir, "db/migrate/20260101000000_create_recording_studio_admin_admins.rb"),
        "# existing"
      )

      generator = build_migrations_generator(dir)

      generator.stub(:say, nil) do
        generator.copy_migrations
      end

      migrations = Dir.glob(File.join(dir, "db/migrate/*_create_recording_studio_admin_admins.rb"))
      assert_equal 1, migrations.size
      assert_equal "# existing", File.read(migrations.first)
    end
  end
end
