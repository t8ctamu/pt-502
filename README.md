# PT-502

Member and officer portal for the Texas A&M Physical Therapy Society, built with Ruby on Rails and PostgreSQL.

## Table of Contents

- [Description](#description)
- [Features](#features)
- [Usage](#usage)
- [Requirements](#requirements)
- [Environment Variables and Required Files](#environment-variables-and-required-files)
- [Installation and Setup](#installation-and-setup)
- [Running the Application](#running-the-application)
- [Tests](#tests)
- [Deployment](#deployment)
- [CI/CD](#cicd)
- [Documentation](#documentation)
- [Support](#support)
- [Contact](#contact)
- [Credits and Acknowledgements](#credits-and-acknowledgements)

## Description

PT-502 gives members a place to view events, check in, track semester points, maintain their profiles, and submit outside-event point requests. Officers manage membership, events, attendance, dues, and approvals. Managers also control roles and point requirements.

The project was developed for CSCE 431. This repository is a copy with the original Git history. The [team repository](https://github.com/FA26-CSCE431-software-engineering/PT-502) contains the original project and pull requests.

## Features

- Google sign-in for Texas A&M accounts and the configured club account.
- Member profiles with graduation term, PT school application cycle, carpool availability, and optional phone sharing.
- Event listings, calendar downloads, QR check-in, and location checks for attendance.
- Semester point totals, category requirements, active status, and officer point adjustments.
- Outside-event submissions with officer approval or denial.
- Member, event, and attendance imports, with validation and import results.
- Officer tools for membership, dues, removal/restoration, and semester history.
- Manager controls for access levels, point types, and requirements.
- Member, officer, and system help guides with training examples.

## Usage

- [Production application](https://pt-502-production-ba165c0958f0.herokuapp.com/)
- [Staging application](https://pt-502-staging-72bf8fe2fdec.herokuapp.com/)

Choose Google sign-in and use your approved account. Complete your profile when prompted. Members use Home, Events, and Point Requests. Officer and manager tools appear according to the signed-in account's role.

For QR check-in, scan the event's QR code, sign in if needed, and follow the location prompt. Use HTTPS on a phone when testing location access. Use staging and designated test data for practice. Choose **Help** for instructions for your role.

## Requirements

### Internal Requirements

Versions below come from the checked-in configuration and lockfile. CI uses PostgreSQL 17 and Node.js 22.

| Component | Version / purpose |
| --- | --- |
| Ruby | 3.4.6, specified in `.ruby-version` |
| Rails | 8.1.3.1, locked in `Gemfile.lock` |
| Bundler | 2.7.2, specified in `Gemfile.lock` |
| PostgreSQL | 17 in CI; required for development and tests |
| Node.js | 22 in CI, for JavaScript tests |
| Browser | Google sign-in and geolocation support for phone check-in |

JavaScript is served through Rails import maps. A Node package install or Yarn build is not required to run the application.

### External Dependencies

- [Git](https://git-scm.com/downloads) for source control.
- [Ruby](https://www.ruby-lang.org/en/downloads/), Bundler, PostgreSQL, and Node.js for local development and checks.
- [Google Cloud Console](https://console.cloud.google.com/) for the organization's OAuth web client.
- [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) and an approved Heroku app/database for deployment.
- [Docker](https://www.docker.com/) is optional. The checked-in `Dockerfile` builds a production image; it is not a complete local development stack.
- OpenStreetMap tiles and Nominatim support the event location picker. Manual coordinates are available when address lookup is unavailable.

### Third-Party Libraries

| Library | Purpose |
| --- | --- |
| Devise, OmniAuth, omniauth-google-oauth2 | Google authentication |
| pg, Puma | PostgreSQL connection and web server |
| Turbo, Stimulus, importmap-rails, Propshaft | Browser interactions and assets |
| rqrcode | Event check-in QR codes |
| Pagy | Pagination |
| CSV, Roo | CSV and spreadsheet imports |
| Leaflet 1.9.4 | Event location map |
| dotenv-rails | Local development/test environment variables |
| RSpec, Capybara, Factory Bot, SimpleCov | Tests, fixtures, and coverage |
| RuboCop Rails Omakase, Brakeman | Ruby style and optional security analysis |

See `Gemfile`, `Gemfile.lock`, and `config/importmap.rb` for the complete configuration. The application does not integrate a generative AI API at runtime.

## Environment Variables and Required Files

Create an untracked `.env` for local development. Replace these placeholders with settings for your local database and approved Google client:

```dotenv
DATABASE_HOST=127.0.0.1
DATABASE_USER=pt502
DATABASE_PASSWORD=YOUR_LOCAL_DATABASE_PASSWORD
GOOGLE_OAUTH_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID
GOOGLE_OAUTH_CLIENT_SECRET=YOUR_GOOGLE_WEB_CLIENT_SECRET
GEOCODER_USER_AGENT=PT502/1.0 (YOUR_PROJECT_CONTACT)
```

| Variable / file | Use |
| --- | --- |
| `DATABASE_HOST`, `DATABASE_USER`, `DATABASE_PASSWORD` | Local PostgreSQL connection. Host and user default to `127.0.0.1` and `pt502`. |
| `DATABASE_URL` | Production database connection, normally supplied by Heroku Postgres. Keep production values out of local/test environments. |
| `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET` | Organization's Google OAuth web client. |
| `RAILS_MASTER_KEY` / `config/master.key` | Key matching this application's encrypted Rails credentials. Obtain through the team's private handover process. |
| `RAILS_ENV` | Set to `production` on deployed apps or `test` when preparing the test database. |
| `GEOCODER_USER_AGENT` | Identifies the application and a project contact to Nominatim. |
| `PORT`, `RAILS_MAX_THREADS`, `RAILS_LOG_LEVEL` | Optional server/runtime settings. Heroku supplies the port. |

Register `http://localhost:3000/members/auth/google_oauth2/callback` as an authorized redirect URI for local sign-in. Register each deployed app's exact HTTPS URL followed by `/members/auth/google_oauth2/callback` as well.

The `.env` files and credentials keys are ignored by Git. Share their real values through the team's private credential handover process.

## Installation and Setup

These commands use a POSIX shell. On Windows, use WSL Ubuntu for the Ruby/PostgreSQL workflow and open the app in your Windows browser.

1. Clone the repository and enter its directory:

   ```sh
   git clone https://github.com/t8ctamu/pt-502.git
   cd pt-502
   ```

2. Install Ruby 3.4.6, PostgreSQL, and Node.js 22. Start PostgreSQL and create a local database role with permission to create databases. For a fresh PostgreSQL installation using the default local role:

   ```sh
   sudo -u postgres createuser --createdb --pwprompt pt502
   ```

3. Create `.env` using the variables above, then install the locked dependencies:

   ```sh
   gem install bundler -v 2.7.2
   bundle install
   ```

4. Create the database and run migrations:

   ```sh
   bundle exec rails db:create db:migrate
   ```

5. For a new empty installation, create the agreed initial manager and default point types. Replace the example identity with the approved owner's Texas A&M account:

   ```sh
   bundle exec rake system:bootstrap EMAIL=owner@tamu.edu FIRST_NAME=First LAST_NAME=Last
   ```

   This task stops if a different manager already exists. It does not mark the profile complete or award points. After signing in, the manager should finish their profile and configure the semester and point requirements. The existing `db:seed` task assigns the original project accounts and sets Fall 2026 as the current semester; use `system:bootstrap` for a different organization's installation.

## Running the Application

```sh
bundle exec rails server
```

Open [localhost:3000](http://localhost:3000). Stop the server with Ctrl+C. The development database is `pt502_development`. The `/up` route provides the Rails health check.

## Tests

Prepare the separate, disposable `pt502_test` database and run the checks:

```sh
RAILS_ENV=test bundle exec rails db:prepare
bundle exec rspec spec/
bundle exec rubocop
node --test spec/javascript/*.cjs
```

RSpec covers models, requests, services, and rendered views. Request specs include sign-in/role restrictions, profiles, point requests, imports, events, and attendance. The Node tests exercise location controllers and the event location picker. SimpleCov writes a report to `coverage/index.html` when RSpec runs.

For a focused run, pass a spec path, for example:

```sh
bundle exec rspec spec/requests/profiles_spec.rb spec/requests/help_spec.rb
```

An optional separate security scan is available with `bundle exec brakeman`; the current CI workflow runs RSpec, RuboCop, and the Node tests.

## Deployment

Deploy the reviewed commit to the intended Heroku app using the Ruby buildpack and Heroku Postgres. Set its Rails and Google OAuth configuration before testing sign-in. The [system guide](docs/system-guide.html) covers initial setup, backups, recovery, and ownership handover.

For an existing configured Heroku app, replace `YOUR-APP` with its actual app name:

```sh
heroku login
heroku git:remote --app YOUR-APP
git push heroku HEAD:main
heroku releases --app YOUR-APP
heroku open --app YOUR-APP
```

The `Procfile` starts Puma with `bundle exec puma -C config/puma.rb`. Its release process runs `bundle exec rails db:migrate`; it does not seed or import member records. Bootstrap only a genuinely new installation using the task above.

Test `/up`, Google sign-in, a profile save, an event/check-in, points, and help in staging before deploying the same commit to production. A code rollback does not reverse database migrations. Follow the system guide when recovering a release or restoring a backup.

## CI/CD

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on pushes, pull requests, and manual **Run workflow** requests. It prepares PostgreSQL 17, uses the checked-in Ruby version, runs RSpec and RuboCop, runs JavaScript tests with Node.js 22, and uploads coverage artifacts. Review each step's recorded result in [GitHub Actions](https://github.com/t8ctamu/pt-502/actions).

This workflow checks code; it does not deploy to Heroku. Deployments use the configured team Heroku app and reviewed code. The personal repository's successful CI run alone does not establish which commit is deployed to the team's app.

## Documentation

Once the app is running, use **Help** or open:

- `/help/member`: sign-in, profiles, points, events, attendance, and outside-event requests.
- `/help/officer`: member management, dues, points, roles, events, and approvals (officers only).
- `/help/system`: installation, Heroku operations, backups, recovery, rollback, and costs (officers only).

The [standalone system guide](docs/system-guide.html) can be opened before installing the app. Use the [help maintenance checklist](docs/help-maintenance.md) when changing a feature. The older system guide's statement that spreadsheet import screens are unavailable predates the import routes now present in this repository; use the current import screens and their validation results for that workflow. Training screenshots use fictional data.

## Support

For a usage problem, start with **Help** and contact a Physical Therapy Society officer. For a code defect, [open an issue](https://github.com/t8ctamu/pt-502/issues) with the affected page, reproduction steps, expected behavior, observed behavior, and relevant commit or PR. Include redacted test evidence where useful.

For database connection errors, check PostgreSQL and the local database variables. For Google `redirect_uri_mismatch`, compare the exact callback URI with the Google client configuration. For deployment failures, check both the Heroku build and release logs.

## Contact

Project team: Luke Chambers, Brendan Larson, Fernando Munoz Garza, Richard Ngo, and Tayte Choudhury. Use the course team channel for project coordination and repository issues for code problems. Club officers handle member access and application ownership.

## Credits and Acknowledgements

Developed for the Texas A&M Physical Therapy Society as part of CSCE 431. Thanks to the customer and course staff for requirements, reviews, and testing feedback. The README structure follows the Week 10 Lab `README_example.md` supplied by the course.

Maps use Leaflet and OpenStreetMap contributors; address lookup uses Nominatim. Other dependencies are listed above and retain their respective licenses.

### AI Use

OpenAI Codex assisted with portions of implementation, tests, debugging, and documentation, including this README. The team is responsible for reviewing changes, checking acceptance criteria, and validating results before release.

