#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
action="${1:-test}"
service postgresql start
# Keep local database credentials outside the copied repo and out of Git.
credentials=/root/.pt502-database-env
if [ ! -f "$credentials" ]; then
  umask 077
  password=$(ruby -rsecurerandom -e 'print SecureRandom.hex(24)')
  printf 'export DATABASE_USER=pt502\nexport DATABASE_PASSWORD=%s\nexport DATABASE_HOST=127.0.0.1\n' "$password" > "$credentials"
fi
source "$credentials"
if ! runuser -u postgres -- psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='pt502'" | grep -q 1; then
  runuser -u postgres -- createuser --createdb pt502
fi
runuser -u postgres -- psql -c "ALTER ROLE pt502 PASSWORD '$DATABASE_PASSWORD'" >/dev/null
bundle check || bundle install
case "$action" in
  setup)
    bundle exec rails db:prepare db:migrate
    bundle exec rake db:test:prepare
    ;;
  test)
    RAILS_ENV=test bundle exec rails db:prepare db:migrate
    bundle exec rake db:test:prepare
    bundle exec rspec spec/
    ;;
  lint) bundle exec rubocop ;;
  server)
    bundle exec rails db:prepare db:migrate
    bundle exec rails server -b 0.0.0.0 -p 3000
    ;;
  *) echo "Expected setup, test, lint, or server" >&2; exit 2 ;;
esac
