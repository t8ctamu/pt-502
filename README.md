# PT-502
 
Physical Therapy Society member portal, built with Rails and PostgreSQL.
 
PT-502 lets a student organization manage its members, events, and point requirements in one place. Members sign in, complete a profile, check in to events, and track their progress toward point requirements. Officers manage members, dues, events, and approvals.
 
## Table of Contents
 
- [Features](#features)
- [Usage](#usage)
- [Requirements and Dependencies](#requirements-and-dependencies)
- [Environment Variables and Required Files](#environment-variables-and-required-files)
- [Configuration Ownership](#configuration-ownership)
- [Installation and Setup](#installation-and-setup)
- [Checks](#checks)
- [Deployment](#deployment)
- [Change Control](#change-control)
- [Help and Training](#help-and-training)
- [Documentation Links](#documentation-links)
- [Contact](#contact)
- [Credits and Acknowledgements](#credits-and-acknowledgements)
## Features
 
- Member profiles, roles, and dues tracking
- Events with location and a check-in radius for attendance
- Attendance records and RSVPs
- Points awarded per requirement and per semester, with progress toward totals
- Outside-event submissions that officers approve or deny
- Semesters and saved locations
- Officer tools for member management, roles, events, and approvals
## Usage
 
Once the app is running, sign in and choose **Help** in the navigation. Members can manage their profile, view points, check in to events, and submit outside events. Officers have additional pages for managing members, dues, points, roles, events, and approvals. See [Help and Training](#help-and-training) for the full guides.
 
## Requirements and Dependencies
 
**Internal requirements**
 
- Ruby, using the version in `.ruby-version`
- Ruby on Rails 8.1
- PostgreSQL
- Node.js (used to run the JavaScript tests)
- Git
**Third-party libraries**
 
- Gems are listed in `Gemfile` and locked in `Gemfile.lock`. Install them with `bundle install`.
- Key tools: Puma (web server), RSpec (tests), RuboCop (linting).
- Heroku (hosting and Heroku Postgres)

Current checked-in versions: Ruby **3.4.6** (`.ruby-version`), Rails **8.1.3.1**, Puma **8.0.2**, and RSpec Rails **8.0.4** (`Gemfile.lock`). CI uses PostgreSQL **17**, Node.js **22**, and Ubuntu **24.04**. These CI versions do not establish the customer's installed database or hosting versions; the hosting owner should record those in the turnover inventory. Google sign-in uses Devise and OmniAuth; spreadsheet imports use Roo. See [Gemfile.lock](Gemfile.lock) for the full dependency list.
  
## Environment Variables and Required Files
 
Variable names only. Never commit real values.
 
| Variable | Purpose |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string (set automatically by Heroku Postgres) |
| `RAILS_ENV` | `development`, `test`, or `production` |
| `GOOGLE_OAUTH_CLIENT_ID` / `GOOGLE_OAUTH_CLIENT_SECRET` | Google web OAuth client used for sign-in; required for real Google login. Set each environment's exact authorized callback URL to `https://YOUR-HOST/members/auth/google_oauth2/callback`. |
| `RAILS_MASTER_KEY` | Key matching this checkout's encrypted Rails credentials. Obtain it securely from the authorized owner; never generate an unrelated replacement for an existing deployment. |
| `DATABASE_HOST` / `DATABASE_USER` / `DATABASE_PASSWORD` | Local/CI database connection settings. Host defaults to `127.0.0.1`, user to `pt502`; password has no default. Local databases are `pt502_development` and `pt502_test`. Production uses `DATABASE_URL`. |
| `RAILS_MAX_THREADS` | Puma thread count and database pool setting. When unset, Puma defaults to 3 and the database pool to 5. |
| `PORT` | Web-server port; defaults to 3000 locally and is supplied by Heroku there. |
| `RAILS_LOG_LEVEL` | Production logging level; defaults to `info`. |
| `GEOCODER_USER_AGENT` | Identifying application/contact string sent to the Nominatim geocoder. Set a real support contact instead of the placeholder default. |
| `REDIS_URL` | Production Action Cable connection if Cable is used; defaults to `redis://localhost:6379/1`. Do not assume a hosted Redis service exists merely because this setting is in the code. |
| `SOLID_QUEUE_IN_PUMA` | Optional switch that starts the Solid Queue supervisor inside Puma when present. Leave unset unless that deployment is configured for it; the string `false` is still present. |
| `PIDFILE` | Optional Puma process-ID file path. |

The initial-owner task also accepts `EMAIL`, `FIRST_NAME`, and `LAST_NAME` for that command only; these are not permanent application settings. Follow the [bootstrap instructions](docs/system-guide.html) and use the approved owner's details. `CI` is supplied by GitHub Actions for test configuration.
 
Required files:
 
- `.ruby-version`: Ruby version to use
- `Gemfile` and `Gemfile.lock`: Ruby dependencies
- `config/database.yml`: database configuration
- `config/initializers/devise.rb`: Google OAuth configuration
- `config/puma.rb`, `config/cable.yml`, and `config/environments/production.rb`: server, Cable, and production settings
- `config/credentials.yml.enc` and its matching key supplied securely: encrypted Rails credentials
- `Procfile`: web command and release-phase migrations
- `.github/workflows/ci.yml`: automated checks and CI service versions

## Configuration Ownership

The app's Manager role does not grant GitHub, Heroku, or Google Cloud access. Keep service access with named, authorized people and record the final account/project identifiers in the Teams Turnover notebook.

| Service | Handoff contact and verification needed |
|---|---|
| Heroku app, database, billing and backups | Hudson is the customer hosting contact; the notebook contains the ownership screenshot. Confirm the authorized administrators, billing/recovery contact and backup access with him. |
| Production GitHub repository and deployment connection | Luke coordinates the handoff. Record the actual customer-owned repository and authorized maintainers once verified; do not assume the classroom or team repository is the final production source. |
| Google Cloud OAuth client | Confirm the authorized project owner and recovery contact with Luke/customer. The owner has not yet been recorded in this README. |
| Rails credentials and other secrets | Confirm the authorized custodian and transfer through the team's approved password manager or another agreed secure channel. Never put values in Git, the notebook, screenshots or chat. |

These contacts are not a claim that every transfer is complete. The notebook should hold the verified owner names, access checks and dates. Configure local values outside Git; use the hosting platform's protected settings for production.
## Installation and Setup
 
1. Clone the repository and move into it.
2. Install the Ruby version listed in `.ruby-version`.
3. Install gems: `bundle install`
4. Make sure PostgreSQL is running.
5. Set the environment variables listed above.
6. Create and migrate the database: `bundle exec rails db:prepare`
7. Create the first manager account with `system:bootstrap`. The steps are in [the system guide](docs/system-guide.html).
8. Start the server: `bin/rails server`
Before installing, open [the system guide](docs/system-guide.html) in a browser. It is the same document served in the app, and it covers local setup and initial manager setup. No private settings are stored in it.
 
## Checks
 
Use Ruby from `.ruby-version` and PostgreSQL. After local setup:
 
```sh
RAILS_ENV=test bundle exec rails db:prepare
bundle exec rspec spec/
bundle exec rubocop
bundle exec brakeman --no-pager
node --test spec/javascript/*.cjs
```
 
The test database is `pt502_test` and is disposable.

CI also runs the locked Brakeman version to scan Rails code for security warnings. Warnings or scan errors fail the check. Download the `brakeman-report` artifact from the Actions run for the JSON and text results, including when the scan fails. Review findings and fix confirmed issues; a clean scan does not replace sign-in and authorization tests.
 
## Deployment
 
The app is deployed on Heroku. The Procfile starts Puma and runs migrations during a Heroku release. It does not seed or import member data. Heroku operations, backups, import recovery, rollback, and costs are covered in the system guide (`/help/system`, officers only).

For the November 23 event-location migration, follow the [location migration and recovery instructions](docs/event-location-normalization.md). Back up the database, pause writes, and deploy the matching application and migration together. The old event location columns are removed. A code-only rollback cannot restore them; recovery requires a compatible app release and the database backup.

## Change Control

1. **Record the request.** Add a Jira story or bug with the problem, acceptance criteria, assigned developer, and any effect on customer scope or data.
2. **Agree on the change.** Luke coordinates approval with the customer. Record the decision in Jira; do not silently remove required scope or treat a suggested change as accepted.
3. **Implement and review.** Work on a branch and open a PR describing the story, acceptance criteria, changes and verification. Have a teammate review it, and resolve comments before merging. Run RSpec, RuboCop and the JavaScript tests listed above; link the actual CI result. Disclose failures or pending checks rather than calling them passed.
4. **Check staging.** Deploy the reviewed commit and try the affected workflow, including relevant invalid-input and permission cases. Record the tester, date and result. For a database change, check migration and backup/recovery requirements first.
5. **Release and record.** The authorized hosting maintainer deploys the approved commit to production. Record the Git SHA, Heroku release number, migration result and post-release checks in the turnover notebook or linked release record. Confirm production matches the tested code before marking the story done.
6. **Handle a failed release.** Stop rollout, preserve logs and record the issue and customer impact. Use the system guide's recovery procedure; confirm schema compatibility before rollback. Verify the recovered app and link the fix and rerun results.

This is the release procedure to follow, not evidence that a review, deployment or customer approval has already happened. An example change is the [event-location normalization](docs/event-location-normalization.md); its final production verification is recorded separately in the turnover notebook.
 
## Help and Training
 
Once the app is running, choose **Help** in the navigation, or open:
 
- `/help/member`: sign-in, profiles, points, events, attendance, and outside-event requests.
- `/help/officer`: member management, dues, points, roles, events, and approvals (officers only).
- `/help/system`: installation, Heroku operations, backups, import recovery, rollback, and costs (officers only).
Screenshots contain fictional training data.
 
## Documentation Links
 
- [System guide](docs/system-guide.html): installation, setup, Heroku operations, backups, and rollback
- [Help maintenance checklist](docs/help-maintenance.md): what to update when features change
- Member and officer guides: available in the app under **Help**
## Contact
 
Luke Chambers: [lukechambers0217@gmail.com](mailto:lukechambers0217@gmail.com)
 
## Credits and Acknowledgements
 
- Built with [Ruby on Rails](https://rubyonrails.org/) and [PostgreSQL](https://www.postgresql.org/).
- Hosted on [Heroku](https://www.heroku.com/).
- Team Members: Luke Chambers, Brendan Larson, Tayte Chowdhury, Fernando Munoz Garza, and Richard Ngo.
- Instruction: Pauline Wade
- Organization: Texas A&M CSCE 431
- **AI use:**: AI tools were used to generate parts of the code, which our team reviewed before using it; they helped us a great deal, but all of the application logic and design decisions came from team.
 
