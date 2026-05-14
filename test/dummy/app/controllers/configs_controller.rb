# frozen_string_literal: true

class ConfigsController < ApplicationController
  def index
    @setup_sections = [
      {
        title: "1. Add the gem and run the installer",
        subtitle: "Start in the host app root so the engine generator can wire the addon into the app.",
        file_path: "Gemfile",
        language: "ruby",
        snippet: <<~RUBY
          gem "recording_studio"
          gem "recording_studio_admin"
        RUBY
      },
      {
        title: "2. Install, copy migrations, and migrate",
        subtitle: "These are the generator and database commands the host app needs after adding the gem.",
        file_path: "Terminal",
        language: "bash",
        snippet: <<~BASH
          bundle install
          bin/rails generate recording_studio_admin:install
          bin/rails generate recording_studio_admin:migrations
          bin/rails db:migrate
        BASH
      },
      {
        title: "3. Set the current actor and root support",
        subtitle: "Put this in the host application controller so Recording Studio permissions and root switching resolve correctly.",
        file_path: "app/controllers/application_controller.rb",
        language: "ruby",
        snippet: <<~RUBY
          class ApplicationController < ActionController::Base
            before_action :authenticate_user!
            before_action { Current.actor = current_user }

            include RecordingStudio::RootSwitchable::ControllerSupport
          end
        RUBY
      },
      {
        title: "4. Mount the engines in routes",
        subtitle: "The admin UI is mounted at /admin and links into RecordingStudioAccessible for root-level access management.",
        file_path: "config/routes.rb",
        language: "ruby",
        snippet: <<~RUBY
          Rails.application.routes.draw do
            mount RecordingStudioAccessible::Engine, at: "/recording_studio_accessible"
            mount RecordingStudioRootSwitchable::Engine, at: "/recording_studio_root_switchable"
            mount RecordingStudioAdmin::Engine, at: "/admin"
          end
        RUBY
      },
      {
        title: "5. Configure actor resolution for access management",
        subtitle: "This initializer lets RecordingStudioAccessible resolve the signed-in user and display a stable label in the admin flows.",
        file_path: "config/initializers/recording_studio_accessible.rb",
        language: "ruby",
        snippet: <<~RUBY
          RecordingStudioAccessible.configure do |config|
            config.access_management_current_actor_resolver = ->(controller:) { Current.actor || controller.current_user }
            config.access_management_actor_label = ->(actor) { actor.email }
          end
        RUBY
      },
      {
        title: "6. Create the admin root",
        subtitle: "Seed or create a RecordingStudioAdmin::Admin recordable, then wrap it in a root recording so the mounted page has a root to work with.",
        file_path: "db/seeds.rb or rails console",
        language: "ruby",
        snippet: <<~RUBY
          admin = RecordingStudioAdmin::Admin.create!(
            name: "Admin",
            key: "admin"
          )

          root_recording = RecordingStudio::Recording.create!(recordable: admin)
        RUBY
      }
    ]
  end
end