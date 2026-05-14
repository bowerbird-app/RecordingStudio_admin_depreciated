# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

TEST_PASSWORD = "Password"

def ensure_user(email)
  User.find_or_create_by!(email: email) do |user|
    user.password = TEST_PASSWORD
    user.password_confirmation = TEST_PASSWORD
  end
end

def ensure_root_access(user:, root_recording:, role:)
  access = RecordingStudio::Access.find_or_create_by!(actor: user, role: role)

  RecordingStudio::Recording.unscoped.find_or_create_by!(
    root_recording_id: root_recording.id,
    parent_recording_id: root_recording.id,
    recordable: access
  )
end

admin_user = ensure_user("admin@admin.com")
editor_user = ensure_user("editor@admin.com")
viewer_user = ensure_user("viewer@admin.com")
workspace_admin_user = ensure_user("workspace-admin@admin.com")

admin_root = RecordingStudioAdmin::Admin.find_or_create_by!(key: "admin") do |admin|
  admin.name = "Admin"
end

workspace = Workspace.find_or_create_by!(name: "Client Workspace")

admin_root_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  recordable: admin_root,
  parent_recording_id: nil
)

workspace_root_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  recordable: workspace,
  parent_recording_id: nil
)

Current.actor = admin_user

ensure_root_access(user: admin_user, root_recording: admin_root_recording, role: :admin)
ensure_root_access(user: admin_user, root_recording: workspace_root_recording, role: :admin)
ensure_root_access(user: editor_user, root_recording: admin_root_recording, role: :edit)
ensure_root_access(user: viewer_user, root_recording: admin_root_recording, role: :view)
ensure_root_access(user: workspace_admin_user, root_recording: workspace_root_recording, role: :admin)

puts "Seeded users:"
puts "- admin@admin.com / #{TEST_PASSWORD} (admin on admin root and workspace root)"
puts "- editor@admin.com / #{TEST_PASSWORD} (edit on admin root only)"
puts "- viewer@admin.com / #{TEST_PASSWORD} (view on admin root only)"
puts "- workspace-admin@admin.com / #{TEST_PASSWORD} (admin on workspace root only)"
puts "Seeded admin root: #{admin_root.name}"
puts "Seeded workspace root: #{workspace.name}"
