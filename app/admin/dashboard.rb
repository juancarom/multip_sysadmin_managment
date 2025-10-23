# frozen_string_literal: true

ActiveAdmin.register_page 'Dashboard' do
  menu priority: 0, label: '📊 Dashboard'

  content title: 'Panel de Control' do
    # Tarjetas de estadísticas principales
    columns do
      column do
        panel '📊 Estadísticas Generales' do
          div class: 'dashboard-stats' do
            div class: 'stat-row' do
              div class: 'stat-card stat-primary' do
                h2 Project.count, class: 'stat-number'
                span 'Proyectos Totales', class: 'stat-label'
              end

              div class: 'stat-card stat-success' do
                h2 Project.active.count, class: 'stat-number'
                span 'Proyectos Activos', class: 'stat-label'
              end

              div class: 'stat-card stat-info' do
                h2 User.count, class: 'stat-number'
                span 'Usuarios', class: 'stat-label'
              end

              div class: 'stat-card stat-warning' do
                h2 Integration.count, class: 'stat-number'
                span 'Integraciones', class: 'stat-label'
              end
            end
          end
        end
      end
    end

    columns do
      column span: 2 do
        panel '📁 Proyectos Recientes' do
          table_for Project.order(created_at: :desc).limit(5) do
            column('Nombre') { |p| link_to p.name, admin_project_path(p) }
            column('Slug') { |p| content_tag(:span, p.slug, class: 'slug-tag status_tag') }
            column('Estado') { |p| status_tag(p.active? ? 'Activo' : 'Inactivo', p.active? ? 'ok' : 'error') }
            column('Integraciones') { |p| p.integrations.count }
            column('Usuarios') { |p| p.users.count }
            column('Creado') { |p| time_ago_in_words(p.created_at) + ' atrás' }
          end
        end
      end

      column do
        panel '🔌 Estado de Integraciones' do
          div do
            integration_stats = {
              total: Integration.count,
              activas: Integration.active.count,
              inactivas: Integration.inactive.count,
              jira: Integration.where(integration_type: 'jira').count,
              github: Integration.where(integration_type: 'github').count,
              gitlab: Integration.where(integration_type: 'gitlab').count
            }

            ul class: 'integration-stats' do
              li do
                strong 'Total: '
                span integration_stats[:total]
              end
              li do
                status_tag 'Activas', 'ok'
                span " #{integration_stats[:activas]}"
              end
              li do
                status_tag 'Inactivas', 'error'
                span " #{integration_stats[:inactivas]}"
              end
              li class: 'divider' do
                '―――――――――――'
              end
              li do
                strong '📋 Jira: '
                span integration_stats[:jira]
              end
              li do
                strong '🐙 GitHub: '
                span integration_stats[:github]
              end
              li do
                strong '🦊 GitLab: '
                span integration_stats[:gitlab]
              end
            end
          end
        end
      end
    end

    columns do
      column do
        panel '👥 Usuarios por Rol' do
          div class: 'role-stats' do
            user_roles = {
              superadmin: User.superadmin.count,
              admin: User.admin.count,
              user: User.user.count
            }

            ul do
              li do
                status_tag 'Superadmin', 'error'
                span " #{user_roles[:superadmin]} usuario(s)"
              end
              li do
                status_tag 'Admin', 'warning'
                span " #{user_roles[:admin]} usuario(s)"
              end
              li do
                status_tag 'User', 'ok'
                span " #{user_roles[:user]} usuario(s)"
              end
            end
          end
        end
      end

      column do
        panel '🔄 Sincronizaciones Recientes' do
          integrations_with_sync = Integration.where.not(last_sync_at: nil)
                                              .order(last_sync_at: :desc)
                                              .limit(5)

          if integrations_with_sync.any?
            table_for integrations_with_sync do
              column('Integración') { |i| link_to i.name, admin_integration_path(i) }
              column('Estado') do |i|
                case i.sync_status
                when 'completed'
                  status_tag 'Completado', 'ok'
                when 'failed'
                  status_tag 'Fallido', 'error'
                when 'in_progress'
                  status_tag 'En Progreso', 'warning'
                else
                  status_tag 'Pendiente', 'default'
                end
              end
              column('Última Sync') { |i| time_ago_in_words(i.last_sync_at) + ' atrás' }
            end
          else
            para 'No hay sincronizaciones recientes', class: 'empty-message'
          end
        end
      end
    end

    columns do
      column do
        panel '🚀 Acciones Rápidas' do
          div class: 'quick-actions' do
            ul do
              li do
                link_to '➕ Nuevo Proyecto', new_admin_project_path, class: 'button'
              end
              li do
                link_to '➕ Nuevo Usuario', new_admin_user_path, class: 'button'
              end
              li do
                link_to '➕ Nueva Integración', new_admin_integration_path, class: 'button'
              end
              li do
                link_to '📊 Ver Todos los Proyectos', admin_projects_path, class: 'button'
              end
            end
          end
        end
      end

      column do
        panel 'ℹ️ Información del Sistema' do
          attributes_table_for nil do
            row('Versión Rails') { Rails.version }
            row('Versión Ruby') { RUBY_VERSION }
            row('Entorno') { status_tag Rails.env, Rails.env.production? ? 'error' : 'ok' }
            row('Base de Datos') { ActiveRecord::Base.connection.adapter_name }
            row('Última Actualización') { Time.current.strftime('%d/%m/%Y %H:%M:%S') }
          end
        end
      end
    end
  end
end
