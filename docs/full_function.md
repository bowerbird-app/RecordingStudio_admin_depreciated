# Recording Studio Admin

Recording Studio Admin is a minimal Rails engine addon for `RecordingStudio` applications that need a dedicated admin root.

The gem adds one root recordable, `RecordingStudioAdmin::Admin`, and a small mounted admin interface that works with the broader Recording Studio stack. Its purpose is deliberately focused: create the admin root, expose a lightweight admin page, and integrate cleanly with `RecordingStudioAccessible` and `RecordingStudioRootSwitchable` when those pieces are available in the host app.

## Overview

This gem is meant for hosts that already use Recording Studio and want a first-class admin root instead of building a separate admin system.

It is useful when you want to:

- create a dedicated admin root alongside standard workspace roots
- mount a separate page for root-level operations
- connect the admin root to shared access-management workflows
- keep the admin page compatible with current-root switching
- avoid introducing a second authorization model just for admin

The addon stays intentionally small. It does not define a capability framework, a registration abstraction, or a separate permissions layer. It leans on the existing Recording Studio conventions so host applications can adopt it without changing their overall structure.

## Package Identity

- Gem name: `recording_studio_admin`
- Ruby module: `RecordingStudioAdmin`
- Engine: `RecordingStudioAdmin::Engine`
- Root recordable: `RecordingStudioAdmin::Admin`
- Database table: `recording_studio_admin_admins`

## What the Gem Provides

### 1. Admin root recordable

`RecordingStudioAdmin::Admin` is the root recordable exposed by the gem. It is a small Active Record model with straightforward validation and normalization behavior.

### 2. Mounted admin page

The engine mounts a simple admin page at the engine root. This page is not a general dashboard framework. It is the admin-facing entry point for the addon and the place where root-level access workflows can begin.

### 3. Recording Studio integration

When the host app includes the broader Recording Studio pieces, the gem integrates with them automatically:

- it registers `RecordingStudioAdmin::Admin` as a recordable type
- it hooks into `RecordingStudioAccessible` for access-management flows
- it stays compatible with `RecordingStudioRootSwitchable` when the host app exposes a current root

### 4. UI runtime support

The mounted admin UI expects the runtime pieces already bundled with the gem:

- `flat_pack`
- `importmap-rails`
- `tailwindcss-rails`

## Installation

Add the gem to the host application's Gemfile:

```ruby
gem "recording_studio"
gem "recording_studio_admin"
```

Then install and migrate:

```bash
bundle install
bin/rails generate recording_studio_admin:install
bin/rails generate recording_studio_admin:migrations
bin/rails db:migrate
```

The install generator configures the host app to mount the engine, writes the gem initializer, and adds the Tailwind source entries needed for the admin UI.

## Host App Integration

### Current Actor

The host application should set the current actor in the controller layer so Recording Studio permissions can resolve against the signed-in user.

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action { Current.actor = current_user }
end
```

### Root Switching

If the host app uses `RecordingStudioRootSwitchable`, expose the current root in the controller layer so the admin page can stay aligned with the active recording root.

```ruby
class ApplicationController < ActionController::Base
  include RecordingStudio::RootSwitchable::ControllerSupport
end
```

### Routes

Mount the shared access engine and the admin engine in `config/routes.rb`:

```ruby
mount RecordingStudioAccessible::Engine, at: "/recording_studio_accessible"
mount RecordingStudioAdmin::Engine, at: "/admin"
```

The admin engine root serves the mounted admin page. The `RecordingStudioAccessible` mount provides the shared access-management destination that the admin page can link to.

### Optional root-switch support

`RecordingStudioRootSwitchable` is optional. If the host app mounts it and exposes `current_root_recording`, the admin page can keep its switcher behavior in sync with the active root scope.

## Model Behavior

Create an admin root the same way you would create other Recording Studio recordables:

```ruby
admin = RecordingStudioAdmin::Admin.create!(
  name: "Admin",
  key: "admin"
)

root_recording = RecordingStudio::Recording.create!(recordable: admin)
```

Model rules:

- `name` is required
- `key` is optional
- `name` is stripped before validation
- `key` is stripped and downcased before validation
- `key` must be unique when present, ignoring case

## Engine Behavior

The engine initializes in a conservative way so it can coexist with host apps that load pieces in different orders.

On preparation, it:

- checks whether `RecordingStudio` is available
- adds `RecordingStudioAdmin::Admin` to the configured recordable types when needed
- checks whether `RecordingStudioAccessible::AllowsAccessibleChildren` exists
- enables accessible children support for the admin root when available

This keeps the addon compatible with apps that load Recording Studio, access management, and the admin gem separately.

## Admin Page

The mounted page is intentionally small and focused.

It is designed to:

- identify the active admin root
- connect to the shared access-management flow
- remain usable when the host app also uses root switching
- keep the UI aligned with FlatPack conventions

This gem is not trying to replace a full admin framework. It is the root-facing entry point for admin in a Recording Studio host app.

## Dummy App

The dummy app in `test/dummy/` is the best reference for real integration behavior.

It demonstrates:

- Devise authentication with a seeded admin user
- one `RecordingStudioAdmin::Admin` root
- one standard `Workspace` root
- `RecordingStudioAccessible` mounted for root-level access management
- `RecordingStudioRootSwitchable` mounted for current-root switching
- separate layouts for the host pages and the mounted admin page
- a working login flow and root-specific navigation

Useful routes in the dummy app:

- `/` - host application home page
- `/admin` - mounted Recording Studio Admin page
- `/recording_studio` - mounted RecordingStudio engine
- `/recording_studio_accessible/recordings/:recording_id/accesses` - root-level access management
- `/recording_studio_root_switchable/v1/root_switch?scope=all_roots` - root switcher
- `/users/sign_in` - Devise sign-in page

Login credentials:

- Email: `admin@admin.com`
- Password: `Password`

## Development and Validation

From the repository root:

```bash
bundle exec rake test
bundle exec rake test:dummy
```

If you change dummy app setup, migrations, or dependencies, also verify the dummy app prepares cleanly:

```bash
cd test/dummy
bundle install
bin/rails db:prepare
```

## Relationship to the Main README

The top-level README is the primary getting-started document for the gem.

This file is a longer companion overview that can be used for documentation pages, internal references, or a more detailed explanation of what the addon does and how it fits into the Recording Studio ecosystem.

## Legacy Template Docs

Older template-oriented notes remain in `docs/gem_template/` for architectural reference.

Those files are useful if you need background on the original template structure, but they are not the main source of truth for the current addon behavior.

## License

MIT. See [MIT-LICENSE](../MIT-LICENSE).
