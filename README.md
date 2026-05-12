# Recording Studio Admin

Recording Studio Admin is a small Rails engine addon for `RecordingStudio`.

It adds one root recordable type, `RecordingStudioAdmin::Admin`, plus a minimal mounted admin page that hands off root-level user management to `RecordingStudioAccessible`.

## Public API

- Product/module: `RecordingStudioAdmin`
- Gem: `recording_studio_admin`
- Engine: `RecordingStudioAdmin::Engine`
- Root recordable: `RecordingStudioAdmin::Admin`

## What the gem does

- registers `RecordingStudioAdmin::Admin` as a RecordingStudio recordable type
- provides a lightweight `recording_studio_admin_admins` table
- validates `name` and supports an optional `key`
- mounts a FlatPack-based admin page
- links the current root to the standard `RecordingStudioAccessible` access-management UI
- stays compatible with `RecordingStudioRootSwitchable` when the host app exposes a current root

## Non-goals

- no capability framework
- no `AdminCapability` model
- no registration abstraction
- no separate authorization system beyond the existing RecordingStudio access stack

## Installation

Add the gem to your host app:

```ruby
gem "recording_studio"
gem "recording_studio_admin"
```

Then run:

```bash
bundle install
bin/rails generate recording_studio_admin:install
bin/rails generate recording_studio_admin:migrations
bin/rails db:migrate
```

The install generator:

- mounts the engine (default: `/admin`)
- creates `config/initializers/recording_studio_admin.rb`
- adds Tailwind `@source` entries for the engine views and FlatPack components
- relies on the gem's bundled `flat_pack`, `importmap-rails`, and `tailwindcss-rails` runtime dependencies for the mounted admin UI

## Host app setup

Set the current actor in your controller layer:

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action { Current.actor = current_user }
end
```

If your app also uses `RecordingStudioRootSwitchable`, expose the current root in the controller layer:

```ruby
class ApplicationController < ActionController::Base
  include RecordingStudio::RootSwitchable::ControllerSupport
end
```

Mount `RecordingStudioAccessible` so the admin page can authorize access by role and link to the shared root-level access UI:

```ruby
mount RecordingStudioAccessible::Engine, at: "/recording_studio_accessible"
mount RecordingStudioAdmin::Engine, at: "/admin"
```

`RecordingStudioRootSwitchable` remains optional. When it is mounted and your controller exposes `current_root_recording`, the admin page will keep its root-switch link in sync with the configured switcher scopes.

## Model

```ruby
admin = RecordingStudioAdmin::Admin.create!(
  name: "Admin",
  key: "admin"
)

root_recording = RecordingStudio::Recording.create!(recordable: admin)
```

`name` is required. `key` is optional and normalized to lowercase.

## Dummy app

The dummy app in `test/dummy/` is the source of truth for integration behavior.

It demonstrates:

- one admin root
- one standard workspace root
- an admin user with access to both
- a standard host layout for `/`
- a dedicated admin layout for `/admin`
- top nav root switching through `RecordingStudioRootSwitchable`

Login:

- Email: `admin@admin.com`
- Password: `Password`

## Validation

From the repository root:

```bash
bundle exec rake test
bundle exec rake test:dummy
```

If dummy app migrations or dependencies change, also validate the dummy app setup path:

```bash
cd test/dummy
bundle install
bin/rails db:prepare
```

## Documentation

Legacy template notes remain in `docs/gem_template/` for reference only.
The README and dummy app are the current source of truth.
