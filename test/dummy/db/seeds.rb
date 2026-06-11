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

def bootstrap_access(user:, root_recording:, role:)
  RecordingStudioAccessible::AccessCreationContext.allow do
    RecordingStudio.root_recording_or_self(root_recording).record(
      RecordingStudio::Access,
      actor: user,
      parent_recording: root_recording
    ) do |access|
      access.actor = user
      access.role = role
    end
  end
end

def ensure_root_access(user:, root_recording:, role:, manager_actor: nil)
  return bootstrap_access(user: user, root_recording: root_recording, role: role) if manager_actor.nil?

  result = RecordingStudioAccessible.grant_access(
    recording: root_recording,
    actor: user,
    role: role,
    manager_actor: manager_actor
  )

  return result if result.success?

  raise Array(result.errors).presence || result.error || "Could not grant #{role} access to #{user.email}"
end

admin_user = ensure_user("admin@admin.com")
editor_user = ensure_user("editor@admin.com")
viewer_user = ensure_user("viewer@admin.com")
workspace_admin_user = ensure_user("workspace-admin@admin.com")

admin_root = RecordingStudioAdmin::Admin.find_or_create_by!(key: "admin") do |admin|
  admin.name = "Admin"
end

workspace = Workspace.find_or_create_by!(name: "Client Workspace")

admin_root_recording = RecordingStudio.root_recording_for(admin_root)
workspace_root_recording = RecordingStudio.root_recording_for(workspace)

Current.actor = admin_user

ensure_root_access(user: admin_user, root_recording: admin_root_recording, role: :admin)
ensure_root_access(user: admin_user, root_recording: workspace_root_recording, role: :admin)
ensure_root_access(user: editor_user, root_recording: admin_root_recording, role: :edit, manager_actor: admin_user)
ensure_root_access(user: viewer_user, root_recording: admin_root_recording, role: :view, manager_actor: admin_user)
ensure_root_access(
  user: workspace_admin_user,
  root_recording: workspace_root_recording,
  role: :admin,
  manager_actor: admin_user
)

puts "Seeded users:"
puts "- admin@admin.com / #{TEST_PASSWORD} (admin on admin root and workspace root)"
puts "- editor@admin.com / #{TEST_PASSWORD} (edit on admin root only)"
puts "- viewer@admin.com / #{TEST_PASSWORD} (view on admin root only)"
puts "- workspace-admin@admin.com / #{TEST_PASSWORD} (admin on workspace root only)"
puts "Seeded admin root: #{admin_root.name}"
puts "Seeded workspace root: #{workspace.name}"
