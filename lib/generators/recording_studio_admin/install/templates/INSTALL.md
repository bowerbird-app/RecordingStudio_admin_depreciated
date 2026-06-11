RecordingStudioAdmin install complete.

Next steps:

1. Review `config/initializers/recording_studio_admin.rb`.
2. Install the engine migrations with `bin/rails generate recording_studio_admin:migrations`.
3. Apply the migrations with `bin/rails db:migrate`.
4. Ensure your app sets `Current.actor` (or update the initializer resolver).
5. If your host app wants direct access management on other roots, declare them with `recording_studio_recordable` and enable `RecordingStudio.enable_capability(:accessible, on: self)`.
6. Mount `RecordingStudioAccessible` so the admin page can authorize access and link to the shared root-level access UI.
7. If you also use `RecordingStudioRootSwitchable`, mount it and expose `current_root_recording` in your controller layer.
8. Run `bin/rails tailwindcss:build` to pick up the admin engine and FlatPack component sources used by the mounted UI.
