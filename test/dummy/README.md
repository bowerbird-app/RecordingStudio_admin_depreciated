# Dummy App

This Rails app exists to validate Recording Studio Admin in a realistic host application.

## What It Covers

- Devise authentication with a seeded admin user
- one `RecordingStudioAdmin::Admin` root
- one standard `Workspace` root
- RecordingStudio 3 declarations with `RecordingStudio.enable_capability(:accessible, on: self)` on accessible roots
- `RecordingStudioAccessible` mounted for root-level access management
- `RecordingStudioRootSwitchable` mounted for current-root switching
- different layouts for the dummy host pages and the mounted admin page

## Quick Start

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/rails tailwindcss:build
bin/dev
```

Run the commands above from the dummy app directory, not the repository root.

Then open the app and sign in with one of these seeded accounts:

- `admin@admin.com` / `Password` - admin on the admin root and the workspace root
- `editor@admin.com` / `Password` - edit access on the admin root only
- `viewer@admin.com` / `Password` - view access on the admin root only
- `workspace-admin@admin.com` / `Password` - admin on the workspace root only

## Useful Routes

- `/` - dummy host home page
- `/admin` - mounted Recording Studio Admin page
- `/recording_studio` - mounted RecordingStudio engine
- `/recording_studio_accessible/recordings/:recording_id/accesses` - root-level access-management page
- `/recording_studio_root_switchable/v1/root_switch?scope=all_roots` - root switcher
- `/users/sign_in` - Devise sign-in page
- `/up` - Rails health check

## Why This App Exists

Use this app to verify the addon with the same pieces a host app will use in production: current actor wiring, RecordingStudio 3 declarations, capability-enabled root access management, root switching, mounted admin navigation, and the shared access-management screen.
