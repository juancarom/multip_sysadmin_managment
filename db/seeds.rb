# Seeds para MultiP Sysadmin Management
# Este archivo crea datos de ejemplo para desarrollo y testing

puts '🌱 Seeding database...'

# Limpiar datos existentes en desarrollo
if Rails.env.development?
  puts '🧹 Limpiando datos existentes...'
  UserProject.destroy_all
  Integration.destroy_all
  Project.destroy_all
  User.where.not(email: 'admin@example.com').destroy_all
end

# === USUARIOS ===
puts "\n👥 Creando usuarios..."

superadmin = User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.name = 'Super Admin'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = :superadmin
end
puts "  ✓ Superadmin: #{superadmin.email}"

admin1 = User.find_or_create_by!(email: 'manager@example.com') do |user|
  user.name = 'Project Manager'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = :admin
end
puts "  ✓ Admin: #{admin1.email}"

admin2 = User.find_or_create_by!(email: 'tech-lead@example.com') do |user|
  user.name = 'Tech Lead'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = :admin
end
puts "  ✓ Admin: #{admin2.email}"

users = []
5.times do |i|
  user = User.find_or_create_by!(email: "user#{i + 1}@example.com") do |u|
    u.name = "Usuario #{i + 1}"
    u.password = 'password123'
    u.password_confirmation = 'password123'
    u.role = :user
  end
  users << user
  puts "  ✓ User: #{user.email}"
end

# Admin User para ActiveAdmin
AdminUser.find_or_create_by!(email: 'admin@example.com') do |admin|
  admin.password = 'password'
  admin.password_confirmation = 'password'
end
puts '  ✓ AdminUser for ActiveAdmin: admin@example.com / password'

# === PROYECTOS ===
puts "\n📁 Creando proyectos..."

project1 = Project.find_or_create_by!(slug: 'ecommerce-platform') do |p|
  p.name = 'E-Commerce Platform'
  p.description = 'Plataforma de comercio electrónico principal con microservicios'
  p.active = true
  p.settings = {
    'environment' => 'production',
    'region' => 'us-east-1'
  }
end
puts "  ✓ #{project1.name}"

project2 = Project.find_or_create_by!(slug: 'mobile-app-backend') do |p|
  p.name = 'Mobile App Backend'
  p.description = 'API Backend para aplicaciones móviles iOS y Android'
  p.active = true
  p.settings = {
    'environment' => 'production',
    'region' => 'eu-west-1'
  }
end
puts "  ✓ #{project2.name}"

project3 = Project.find_or_create_by!(slug: 'data-analytics') do |p|
  p.name = 'Data Analytics Platform'
  p.description = 'Sistema de análisis de datos y reportes'
  p.active = true
  p.settings = {
    'environment' => 'production',
    'region' => 'us-west-2'
  }
end
puts "  ✓ #{project3.name}"

project4 = Project.find_or_create_by!(slug: 'internal-tools') do |p|
  p.name = 'Internal Tools'
  p.description = 'Herramientas internas para el equipo'
  p.active = false
  p.settings = {
    'environment' => 'staging'
  }
end
puts "  ✓ #{project4.name} (inactive)"

# === ASIGNACIÓN DE USUARIOS A PROYECTOS ===
puts "\n🔗 Asignando usuarios a proyectos..."

# Proyecto 1: E-Commerce
UserProject.find_or_create_by!(user: admin1, project: project1) do |up|
  up.role = :admin
end
puts "  ✓ #{admin1.name} → #{project1.name} (admin)"

[users[0], users[1], users[2]].each do |user|
  UserProject.find_or_create_by!(user: user, project: project1) do |up|
    up.role = :member
  end
  puts "  ✓ #{user.name} → #{project1.name} (member)"
end

# Proyecto 2: Mobile Backend
UserProject.find_or_create_by!(user: admin2, project: project2) do |up|
  up.role = :admin
end
puts "  ✓ #{admin2.name} → #{project2.name} (admin)"

[users[1], users[2], users[3]].each do |user|
  UserProject.find_or_create_by!(user: user, project: project2) do |up|
    up.role = :member
  end
  puts "  ✓ #{user.name} → #{project2.name} (member)"
end

# Proyecto 3: Data Analytics
UserProject.find_or_create_by!(user: admin1, project: project3) do |up|
  up.role = :admin
end
puts "  ✓ #{admin1.name} → #{project3.name} (admin)"

[users[3], users[4]].each do |user|
  UserProject.find_or_create_by!(user: user, project: project3) do |up|
    up.role = :member
  end
  puts "  ✓ #{user.name} → #{project3.name} (member)"
end

# === INTEGRACIONES ===
puts "\n🔌 Creando integraciones..."

# Jira para E-Commerce
jira1 = Integration.find_or_create_by!(project: project1, integration_type: 'jira') do |i|
  i.name = 'Jira - E-Commerce'
  i.active = true
  i.settings = {
    'site_domain' => 'ecommerce.atlassian.net',
    'default_project_key' => 'ECOM'
  }
  i.credentials = {
    'access_token' => 'example_jira_token_ecom',
    'site_domain' => 'ecommerce.atlassian.net'
  }.to_json
  i.sync_status = :completed
  i.last_sync_at = 2.hours.ago
end
puts "  ✓ #{jira1.name} (active)"

# GitHub para E-Commerce
github1 = Integration.find_or_create_by!(project: project1, integration_type: 'github') do |i|
  i.name = 'GitHub - E-Commerce Repos'
  i.active = true
  i.settings = {
    'organization' => 'ecommerce-corp',
    'default_repository' => 'platform-api'
  }
  i.credentials = {
    'access_token' => 'ghp_example_token_ecom',
    'organization' => 'ecommerce-corp'
  }.to_json
  i.sync_status = :completed
  i.last_sync_at = 1.hour.ago
end
puts "  ✓ #{github1.name} (active)"

# GitLab para Mobile Backend
gitlab1 = Integration.find_or_create_by!(project: project2, integration_type: 'gitlab') do |i|
  i.name = 'GitLab - Mobile Backend'
  i.active = true
  i.settings = {
    'base_url' => 'https://gitlab.com',
    'default_project_id' => '12345'
  }
  i.credentials = {
    'access_token' => 'glpat_example_token_mobile',
    'base_url' => 'https://gitlab.com'
  }.to_json
  i.sync_status = :completed
  i.last_sync_at = 30.minutes.ago
end
puts "  ✓ #{gitlab1.name} (active)"

# Jira para Mobile Backend
jira2 = Integration.find_or_create_by!(project: project2, integration_type: 'jira') do |i|
  i.name = 'Jira - Mobile Team'
  i.active = true
  i.settings = {
    'site_domain' => 'mobile-team.atlassian.net',
    'default_project_key' => 'MOB'
  }
  i.credentials = {
    'access_token' => 'example_jira_token_mobile',
    'site_domain' => 'mobile-team.atlassian.net'
  }.to_json
  i.sync_status = :failed
  i.error_message = 'Connection timeout after 30s'
  i.last_sync_at = 5.hours.ago
end
puts "  ✓ #{jira2.name} (active, last sync failed)"

# GitHub para Data Analytics (inactiva)
github2 = Integration.find_or_create_by!(project: project3, integration_type: 'github') do |i|
  i.name = 'GitHub - Analytics'
  i.active = false
  i.settings = {
    'organization' => 'data-analytics-team',
    'default_repository' => 'data-pipeline'
  }
  i.credentials = {
    'access_token' => 'ghp_example_token_analytics',
    'organization' => 'data-analytics-team'
  }.to_json
  i.sync_status = :pending
end
puts "  ✓ #{github2.name} (inactive)"

# GitLab para Internal Tools (sin credenciales)
gitlab2 = Integration.find_or_create_by!(project: project4, integration_type: 'gitlab') do |i|
  i.name = 'GitLab - Internal'
  i.active = false
  i.settings = {
    'base_url' => 'https://gitlab.company.com',
    'default_project_id' => '99999'
  }
  i.sync_status = :pending
end
puts "  ✓ #{gitlab2.name} (inactive, no credentials)"

# === RESUMEN ===
puts "\n✅ Seeding completado!"
puts "\n📊 Resumen:"
puts "  • Usuarios: #{User.count} (#{User.superadmin.count} superadmins, #{User.admin.count} admins, #{User.user.count} users)"
puts "  • Proyectos: #{Project.count} (#{Project.active.count} activos)"
puts "  • Integraciones: #{Integration.count} (#{Integration.active.count} activas)"
puts "  • Asignaciones: #{UserProject.count}"

puts "\n🔑 Credenciales de acceso:"
puts '  Superadmin: admin@example.com / password123'
puts '  Admin:      manager@example.com / password123'
puts '  User:       user1@example.com / password123'
puts '  ActiveAdmin: admin@example.com / password'

puts "\n🌐 URLs:"
puts '  App:        http://localhost:3000'
puts '  ActiveAdmin: http://localhost:3000/admin'
puts '  Sidekiq:    http://localhost:3000/sidekiq'
puts ''
