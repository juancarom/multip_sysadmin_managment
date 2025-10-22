#!/bin/bash
set -e

echo "🚀 Setting up MultiP Sysadmin Management..."

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
  echo "📝 Creating .env file..."
  cp .env.example .env
  echo "✅ .env file created. Please update with your credentials."
fi

# Build Docker images
echo "🐳 Building Docker images..."
docker-compose build

# Start services
echo "🚢 Starting services..."
docker-compose up -d db redis

# Wait for database
echo "⏳ Waiting for database..."
sleep 5

# Create and migrate database
echo "🗄️  Creating database..."
docker-compose run --rm web rails db:create db:migrate

# Seed database
echo "🌱 Seeding database..."
docker-compose run --rm web rails db:seed

# Start all services
echo "🎉 Starting all services..."
docker-compose up -d

echo ""
echo "✨ Setup complete!"
echo ""
echo "📍 Services available at:"
echo "   - Rails App: http://localhost:3000"
echo "   - Nginx: http://localhost"
echo "   - Sidekiq: http://localhost:3000/sidekiq (superadmin only)"
echo ""
echo "🔑 Default credentials (from seeds):"
echo "   - Superadmin: admin@example.com / password123"
echo "   - Admin: manager@example.com / password123"
echo "   - User: user@example.com / password123"
echo ""
echo "📚 Useful commands:"
echo "   - View logs: docker-compose logs -f"
echo "   - Rails console: docker-compose run --rm web rails console"
echo "   - Stop services: docker-compose down"
echo "   - Restart services: docker-compose restart"
echo ""
