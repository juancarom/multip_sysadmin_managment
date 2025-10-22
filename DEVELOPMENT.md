# Guía de Desarrollo - MultiP Sysadmin Management

## 🚀 Quick Start

### 1. Levantar el proyecto con Docker

```bash
# Asegúrate de tener Docker y Docker Compose instalados
./setup.sh
```

Este script automáticamente:
- Crea variables de entorno
- Construye imágenes Docker
- Levanta PostgreSQL y Redis
- Crea y migra la base de datos
- Carga datos de prueba
- Inicia todos los servicios

### 2. Acceder a la aplicación

- **Rails App**: http://localhost:3000
- **ActiveAdmin**: http://localhost:3000/admin
- **Sidekiq**: http://localhost:3000/sidekiq

**Credenciales**:
- Superadmin: `admin@example.com` / `password123`
- ActiveAdmin: `admin@example.com` / `password`

## 📝 Desarrollo Local

### Setup sin Docker

```bash
# 1. Instalar dependencias
bundle install

# 2. Configurar PostgreSQL y Redis localmente
# Asegúrate de que estén corriendo

# 3. Configurar .env
cp .env.example .env

# 4. Generar claves de encriptación
rails db:encryption:init

# 5. Actualizar .env con las claves generadas

# 6. Crear y migrar DB
rails db:create db:migrate

# 7. Cargar seeds
rails db:seed

# 8. Iniciar servidor
rails server

# 9. En otra terminal, iniciar Sidekiq
bundle exec sidekiq
```

### Generar Migraciones Adicionales

```bash
# Ejemplo: agregar campo a User
rails generate migration AddPhoneToUsers phone:string

# Revisar y editar la migración en db/migrate/
# Luego ejecutar
rails db:migrate
```

### Crear Nuevos Adapters de Integración

Para agregar soporte a nuevas plataformas (ej: Trello, Asana):

1. **Crear el adapter**:

```ruby
# lib/integration_adapters/trello_adapter.rb
module IntegrationAdapters
  class TrelloAdapter < BaseAdapter
    def sync
      # Implementar lógica de sincronización
    end

    def test_connection
      # Probar conexión con API
    end

    def add_user_to_project(email, settings = {})
      # Agregar usuario a board de Trello
    end

    # ... otros métodos requeridos
  end
end
```

2. **Actualizar el modelo Integration**:

```ruby
# app/models/integration.rb
INTEGRATION_TYPES = %w[jira github gitlab trello].freeze

def adapter
  case integration_type
  when 'trello'
    IntegrationAdapters::TrelloAdapter.new(self)
  # ... otros casos
  end
end
```

3. **Agregar configuración a ActiveAdmin**:

```ruby
# app/admin/integrations.rb
scope("Trello") { |scope| scope.where(integration_type: 'trello') }
```

## 🧪 Testing

### Ejecutar Tests

```bash
# Todos los tests
docker-compose run --rm web rspec

# Tests específicos
docker-compose run --rm web rspec spec/models
docker-compose run --rm web rspec spec/services/jira_adapter_spec.rb

# Con cobertura
docker-compose run --rm web rspec --format documentation
```

### Escribir Tests para Integraciones

Usar VCR para grabar interacciones HTTP:

```ruby
RSpec.describe IntegrationAdapters::JiraAdapter do
  it 'fetches users successfully', :vcr do
    VCR.use_cassette('jira/list_users') do
      users = adapter.list_users
      expect(users).to be_an(Array)
    end
  end
end
```

### Grabar nuevas cassettes VCR

1. Configurar credenciales reales en variables de entorno
2. Ejecutar el test (grabará la interacción)
3. La cassette se guarda en `spec/vcr_cassettes/`
4. Los tokens se filtran automáticamente

## 🔐 Seguridad

### Encriptación de Credenciales

Las credenciales se encriptan automáticamente con ActiveRecord Encryption:

```ruby
integration.update_credentials!({
  'access_token' => 'mi_token_secreto',
  'api_key' => 'clave_api'
})

# Se guarda encriptado en la DB
# Para acceder:
creds = integration.formatted_credentials
token = creds['access_token']
```

### Generar Nuevas Claves

```bash
rails db:encryption:init
```

Copiar el output a `.env`:

```
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=...
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=...
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=...
```

## 📊 Monitoreo y Debugging

### Logs

```bash
# Todos los servicios
docker-compose logs -f

# Solo Rails
docker-compose logs -f web

# Solo Sidekiq
docker-compose logs -f sidekiq
```

### Rails Console

```bash
docker-compose run --rm web rails console

# Ejemplos:
> User.count
> Project.first.integrations
> Integration.active.count
```

### Sidekiq Web UI

Acceder a http://localhost:3000/sidekiq

- Ver jobs en cola
- Monitorear workers
- Ver jobs fallidos y reintentarlos

### DB Console

```bash
docker-compose run --rm web rails dbconsole

# O directamente con psql
docker-compose exec db psql -U postgres multip_sysadmin_managment_development
```

## 🔄 Background Jobs

### Ejecutar Job Manualmente

```ruby
# En rails console
integration = Integration.find(1)
SyncIntegrationJob.perform_async(integration.id)
```

### Configurar Cron Jobs

Editar `config/initializers/sidekiq_cron.rb`:

```ruby
Sidekiq::Cron::Job.load_from_hash({
  'sync_every_hour' => {
    'cron' => '0 * * * *',  # Cada hora
    'class' => 'ScheduledSyncJob',
    'description' => 'Sync every hour'
  }
})
```

## 🎨 Frontend

### Vistas Personalizadas

Las vistas están en `app/views/`:

- `layouts/application.html.erb` - Layout principal
- `dashboard/index.html.erb` - Dashboard
- `projects/` - Vistas de proyectos
- `integrations/` - Vistas de integraciones

### Estilos

Los estilos inline pueden moverse a:

```css
/* app/assets/stylesheets/application.css */
```

### JavaScript (Stimulus)

Para interactividad:

```javascript
// app/javascript/controllers/integration_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    // Lógica para toggle de integración
  }
}
```

## 📡 API

### Endpoints Disponibles

```
GET    /api/v1/projects
POST   /api/v1/projects
GET    /api/v1/projects/:id
PATCH  /api/v1/projects/:id
DELETE /api/v1/projects/:id

GET    /api/v1/projects/:project_id/integrations
POST   /api/v1/projects/:project_id/integrations
PATCH  /api/v1/projects/:project_id/integrations/:id/toggle
POST   /api/v1/projects/:project_id/integrations/:id/sync
```

### Ejemplo de uso

```bash
# Login (si implementas autenticación por token)
curl -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}'

# Listar proyectos
curl http://localhost:3000/api/v1/projects \
  -H "Authorization: Bearer YOUR_TOKEN"

# Activar integración
curl -X PATCH http://localhost:3000/api/v1/projects/1/integrations/1/toggle \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🚢 Deployment

### Preparación para Producción

1. **Variables de Entorno**:

```bash
# Generar secret key
rails secret

# Configurar en producción
RAILS_ENV=production
SECRET_KEY_BASE=...
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
```

2. **Precompilar Assets**:

```bash
RAILS_ENV=production rails assets:precompile
```

3. **Migrar DB**:

```bash
RAILS_ENV=production rails db:migrate
```

### Docker en Producción

```bash
# Build para producción
docker-compose -f docker-compose.prod.yml build

# Deploy
docker-compose -f docker-compose.prod.yml up -d
```

## 🐛 Troubleshooting

### Error de conexión a PostgreSQL

```bash
# Verificar que PostgreSQL esté corriendo
docker-compose ps

# Reiniciar servicios
docker-compose restart db

# Ver logs
docker-compose logs db
```

### Error de conexión a Redis

```bash
# Verificar Redis
docker-compose exec redis redis-cli ping
# Debe responder: PONG
```

### Jobs de Sidekiq no se ejecutan

```bash
# Ver logs de Sidekiq
docker-compose logs -f sidekiq

# Verificar conexión a Redis
docker-compose exec web rails console
> Sidekiq.redis { |c| c.ping }
```

### Credenciales no se descifran

Verificar que las claves de encriptación estén configuradas:

```bash
# En .env
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=...
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=...
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=...
```

## 📚 Recursos Adicionales

- [Rails Guides](https://guides.rubyonrails.org/)
- [Devise Documentation](https://github.com/heartcombo/devise)
- [Pundit Documentation](https://github.com/varvet/pundit)
- [Sidekiq Documentation](https://github.com/sidekiq/sidekiq)
- [ActiveAdmin Documentation](https://activeadmin.info/)
- [VCR Documentation](https://github.com/vcr/vcr)

## 🤝 Contribuir

1. Fork el proyecto
2. Crear feature branch (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

### Convenciones de Código

- Usar Rubocop para linting
- Tests para todo nuevo código
- Documentar métodos públicos
- Seguir las convenciones de Rails

```bash
# Ejecutar Rubocop
docker-compose run --rm web rubocop

# Auto-corregir
docker-compose run --rm web rubocop -A
```
