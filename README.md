# MultiP Sysadmin Management

Sistema SaaS modular de administración para sysadmins con integraciones a Jira, GitHub y GitLab.

## 🚀 Características

- **Autenticación**: Devise con soporte para múltiples roles (superadmin, admin, user)
- **Autorización**: Pundit para control de acceso granular
- **Integraciones Modulares**:
  - Jira (proyectos, usuarios, tickets)
  - GitHub (repositorios, collaborators)
  - GitLab (proyectos, miembros)
- **Jobs en Background**: Sidekiq + Redis para sincronización automática
- **Panel Administrativo**: ActiveAdmin para gestión de configuraciones
- **Seguridad**: ActiveRecord Encryption para credenciales sensibles
- **Docker**: Stack completo dockerizado (Rails + PostgreSQL + Redis + Sidekiq + Nginx)

## 📋 Requisitos

- Docker >= 20.10
- Docker Compose >= 2.0
- (Opcional) Ruby 3.0.5 para desarrollo local

## 🛠️ Instalación

### Setup Rápido con Docker

```bash
# Clonar el repositorio
git clone <repository-url>
cd multip_sysadmin_managment

# Ejecutar script de setup
./setup.sh
```

El script automáticamente:
1. Crea el archivo `.env` desde `.env.example`
2. Construye las imágenes Docker
3. Levanta los servicios (PostgreSQL, Redis)
4. Crea y migra la base de datos
5. Carga datos de prueba (seeds)
6. Inicia todos los servicios

### Setup Manual

```bash
# 1. Copiar variables de entorno
cp .env.example .env

# 2. Editar .env con tus credenciales
nano .env

# 3. Generar claves de encriptación
docker-compose run --rm web rails db:encryption:init

# 4. Actualizar .env con las claves generadas

# 5. Construir y levantar servicios
docker-compose build
docker-compose up -d

# 6. Crear y migrar base de datos
docker-compose run --rm web rails db:create db:migrate

# 7. Cargar seeds
docker-compose run --rm web rails db:seed
```

## 🌐 Acceso

- **Aplicación Rails**: http://localhost:3000
- **Nginx (proxy)**: http://localhost
- **Sidekiq Dashboard**: http://localhost:3000/sidekiq (solo superadmin)

### Credenciales por Defecto

| Rol | Email | Password |
|-----|-------|----------|
| Superadmin | admin@example.com | password123 |
| Admin | manager@example.com | password123 |
| User | user@example.com | password123 |

## 📁 Estructura del Proyecto

```
multip_sysadmin_managment/
├── app/
│   ├── controllers/      # Controladores principales
│   ├── models/          # User, Project, Integration, UserProject
│   ├── policies/        # Políticas de Pundit
│   ├── services/        # Service Objects (IntegrationService, etc)
│   ├── jobs/            # Background jobs (SyncIntegrationJob, etc)
│   └── views/           # Vistas ERB
├── lib/
│   └── integration_adapters/  # Adapters modulares
│       ├── base_adapter.rb
│       ├── jira_adapter.rb
│       ├── github_adapter.rb
│       └── gitlab_adapter.rb
├── config/
│   ├── initializers/    # Devise, Pundit, Sidekiq, etc
│   └── routes.rb
├── db/
│   ├── migrate/         # Migraciones
│   └── seeds.rb         # Datos iniciales
├── docker-compose.yml   # Orquestación de servicios
├── Dockerfile           # Imagen de Rails
└── nginx.conf           # Configuración de Nginx
```

## 🔧 Comandos Útiles

### Docker

```bash
# Ver logs
docker-compose logs -f
docker-compose logs -f web    # Solo Rails
docker-compose logs -f sidekiq

# Rails console
docker-compose run --rm web rails console

# Ejecutar migraciones
docker-compose run --rm web rails db:migrate

# Ejecutar tests
docker-compose run --rm web rspec

# Detener servicios
docker-compose down

# Reiniciar servicios
docker-compose restart

# Reconstruir imágenes
docker-compose build --no-cache
```

### Desarrollo Local (sin Docker)

```bash
# Instalar dependencias
bundle install

# Setup base de datos
rails db:create db:migrate db:seed

# Iniciar servidor
rails server

# Iniciar Sidekiq
bundle exec sidekiq

# Tests
rspec
```

## 🔐 Configuración de Integraciones

### Jira

1. Ir a ActiveAdmin → Integrations
2. Crear nueva integración tipo "jira"
3. Configurar credenciales:
   ```json
   {
     "access_token": "tu_token_jira",
     "site_domain": "tu-dominio.atlassian.net"
   }
   ```
4. Configurar settings:
   ```json
   {
     "default_project_key": "PROJ"
   }
   ```

### GitHub

1. Crear OAuth App en GitHub
2. Configurar integración en ActiveAdmin
3. Credenciales:
   ```json
   {
     "access_token": "ghp_xxxxxxxxxxxxx",
     "organization": "tu-organizacion"
   }
   ```
4. Settings:
   ```json
   {
     "default_repository": "nombre-repo"
   }
   ```

### GitLab

1. Crear Personal Access Token en GitLab
2. Configurar en ActiveAdmin
3. Credenciales:
   ```json
   {
     "access_token": "glpat-xxxxxxxxxxxxx",
     "base_url": "https://gitlab.com"
   }
   ```
4. Settings:
   ```json
   {
     "default_project_id": "12345"
   }
   ```

## 🏗️ Arquitectura

### Modelos Principales

- **User**: Usuarios del sistema con roles (superadmin, admin, user)
- **Project**: Proyectos que agrupan integraciones
- **Integration**: Configuración de integraciones externas
- **UserProject**: Relación many-to-many entre users y projects

### Adapters Pattern

Los adapters (`lib/integration_adapters/`) implementan una interfaz común:

```ruby
class BaseAdapter
  def sync              # Sincronizar datos
  def test_connection   # Probar conectividad
  def add_user_to_project(email, settings)
  def remove_user_from_project(email)
  def list_users
end
```

Cada integración (Jira, GitHub, GitLab) extiende `BaseAdapter` con su lógica específica.

### Background Jobs

- **SyncIntegrationJob**: Sincroniza una integración específica
- **UserProjectSyncJob**: Sincroniza usuarios cuando se agregan/remueven de proyectos
- **ScheduledSyncJob**: Cron job que sincroniza todas las integraciones activas cada 6 horas

## 🧪 Testing

```bash
# Ejecutar todos los tests
docker-compose run --rm web rspec

# Tests específicos
docker-compose run --rm web rspec spec/models
docker-compose run --rm web rspec spec/services

# Con coverage
docker-compose run --rm web rspec --format documentation
```

### VCR para APIs Externas

Los tests de integraciones usan VCR para grabar/reproducir respuestas HTTP:

```ruby
VCR.use_cassette('jira/list_projects') do
  projects = integration.adapter.list_projects
  expect(projects).to be_an(Array)
end
```

## 🔒 Seguridad

- **Credenciales**: Encriptadas con ActiveRecord::Encryption
- **Autorización**: Pundit policies en todos los controladores
- **CORS**: Configurado en `config/application.rb`
- **Secrets**: Nunca commitear `.env` o credenciales

### Generar Claves de Encriptación

```bash
docker-compose run --rm web rails db:encryption:init
```

Copiar el output a tu `.env`.

## 📊 Monitoreo

- **Sidekiq Web UI**: http://localhost:3000/sidekiq
- **Logs**: `docker-compose logs -f`
- **Health Check**: http://localhost:3000/health

## 🤝 Contribución

1. Fork el proyecto
2. Crear branch (`git checkout -b feature/amazing-feature`)
3. Commit cambios (`git commit -m 'Add amazing feature'`)
4. Push al branch (`git push origin feature/amazing-feature`)
5. Abrir Pull Request

## 📝 Licencia

MIT License - ver archivo LICENSE

## 👥 Soporte

Para dudas o issues: [GitHub Issues](https://github.com/tu-usuario/multip_sysadmin_managment/issues)

