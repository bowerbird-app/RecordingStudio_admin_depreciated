# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

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

Current.actor = user

[admin_root_recording, workspace_root_recording].each do |root_recording|
  access = RecordingStudio::Access.find_or_create_by!(actor: user, role: :admin)
  RecordingStudio::Recording.unscoped.find_or_create_by!(
    root_recording_id: root_recording.id,
    parent_recording_id: root_recording.id,
    recordable: access
  )
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded admin root: #{admin_root.name}"
puts "Seeded workspace root: #{workspace.name}"
