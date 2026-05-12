# Recording Studio Admin

Recording Studio Admin is a minimal Rails engine addon for `RecordingStudio` host applications that need a dedicated admin root.

The gem adds a single root recordable, `RecordingStudioAdmin::Admin`, and a small mounted admin interface that coordinates with the broader Recording Studio stack. It is intentionally narrow in scope: the gem creates the admin root, exposes a lightweight admin page, and integrates with `RecordingStudioAccessible` and `RecordingStudioRootSwitchable` when those pieces are present in the host app.

## What It Is For

This gem exists for apps that want one clearly defined admin root inside a larger Recording Studio environment.

Typical uses include:

- creating a dedicated admin root alongside standard workspace roots
- mounting a separate admin page for root-level operations
- connecting the admin root to shared access-management tooling
- keeping admin behavior compatible with current-root switching in host apps that use it

It is not a capability framework and it does not introduce a parallel authorization model. It stays close to the existing Recording Studio conventions so host apps can adopt it without restructuring their own access patterns.

## Public API

- Gem name: `recording_studio_admin`
- Ruby module: `RecordingStudioAdmin`
- Engine: `RecordingStudioAdmin::Engine`
- Root recordable: `RecordingStudioAdmin::Admin`
- Database table: `recording_studio_admin_admins`

## Key Behaviors

- registers `RecordingStudioAdmin::Admin` as a RecordingStudio recordable type during engine preparation
- provides a minimal admin-root model with `name` validation and optional `key`
- normalizes `name` and `key` before validation
- mounts a root admin page at the engine root
- links the active admin root to `RecordingStudioAccessible` when that engine is available
- stays compatible with `RecordingStudioRootSwitchable` when the host app exposes a current root
- ships with the runtime dependencies needed for the mounted UI: `flat_pack`, `importmap-rails`, and `tailwindcss-rails`

## Installation

Add the gem to your host application's Gemfile:

```ruby
gem "recording_studio"
gem "recording_studio_admin"
```

Then install dependencies and generate the engine setup:

```bash
bundle install
bin/rails generate recording_studio_admin:install
bin/rails generate recording_studio_admin:migrations
bin/rails db:migrate
```

The install generator configures the host app to mount the engine, writes the gem initializer, and adds the engine's Tailwind sources so the admin UI can render correctly.

## Host App Integration

### Current Actor

The engine expects the host application to set the current actor in the controller layer so Recording Studio permissions can resolve against the signed-in user.

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action { Current.actor = current_user }
end
```

### Root Switching

If the host app uses `RecordingStudioRootSwitchable`, expose the current root in the controller layer so the admin page can stay synchronized with the active recording root.

```ruby
class ApplicationController < ActionController::Base
  include RecordingStudio::RootSwitchable::ControllerSupport
end
```

### Mounting Engines

Mount the shared access engine and the admin engine in `config/routes.rb`:

```ruby
mount RecordingStudioAccessible::Engine, at: "/recording_studio_accessible"
mount RecordingStudioAdmin::Engine, at: "/admin"
```

The admin engine root renders the mounted admin page. The `RecordingStudioAccessible` mount is what gives the admin page a shared place to send root-level access workflows.

### Current Root Behavior

`RecordingStudioRootSwitchable` is optional. If the host app mounts it and exposes `current_root_recording`, the admin page will use that current root to keep its switcher link aligned with the configured scope.

## Model

Create an admin root the same way you would create other Recording Studio recordables:

```ruby
admin = RecordingStudioAdmin::Admin.create!(
  name: "Admin",
  key: "admin"
)

root_recording = RecordingStudio::Recording.create!(recordable: admin)
```

Behavior to keep in mind:

- `name` is required
- `key` is optional
- `key` is normalized to lowercase and stripped before validation
- `key` must be unique when present, ignoring case

## Admin Page

The mounted admin page is intentionally small. It is meant to be the root-facing entry point for the Recording Studio admin addon, not a broad dashboard framework.

The page is designed to:

- identify the active admin root
- connect to access-management tooling through `RecordingStudioAccessible`
- remain usable in hosts that also use root switching
- keep the UI implementation aligned with FlatPack conventions

## Dummy App

The dummy app in `test/dummy/` is the source of truth for how the gem behaves in a realistic host application.

It demonstrates:

- Devise authentication with a seeded admin user
- one `RecordingStudioAdmin::Admin` root
- one standard `Workspace` root
- `RecordingStudioAccessible` mounted for root-level access management
- `RecordingStudioRootSwitchable` mounted for current-root switching
- separate layouts for the host pages and the mounted admin page
- a working admin login flow and root-specific navigation

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

## Development

The repository root is the right place for the main validation suite:

```bash
bundle exec rake test
bundle exec rake test:dummy
```

If you change the dummy app setup, migrations, or dependencies, also verify the dummy application boots and prepares correctly:

```bash
cd test/dummy
bundle install
bin/rails db:prepare
```

## Documentation

The top-level README and the dummy app are the current source of truth for the addon.

Legacy template documentation remains in `docs/gem_template/` for architectural reference only. Those files are useful if you need background on how the template was originally structured, but they are not the primary documentation for this gem anymore.

## License

MIT. See [MIT-LICENSE](MIT-LICENSE).
