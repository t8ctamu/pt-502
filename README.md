# PT-502
 
Physical Therapy Society member portal, built with Rails and PostgreSQL.
 
PT-502 lets a student organization manage its members, events, and point requirements in one place. Members sign in, complete a profile, check in to events, and track their progress toward point requirements. Officers manage members, dues, events, and approvals.
 
## Table of Contents
 
- [Features](#features)
- [Usage](#usage)
- [Requirements and Dependencies](#requirements-and-dependencies)
- [Environment Variables and Required Files](#environment-variables-and-required-files)
- [Installation and Setup](#installation-and-setup)
- [Checks](#checks)
- [Deployment](#deployment)
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
  
## Environment Variables and Required Files
 
Variable names only. Never commit real values.
 
| Variable | Purpose |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string (set automatically by Heroku Postgres) |
| `RAILS_ENV` | `development`, `test`, or `production` |
 
Required files:
 
- `.ruby-version`: Ruby version to use
- `Gemfile` and `Gemfile.lock`: Ruby dependencies
- `config/database.yml`: database configuration
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
bundle exec rails db:prepare
RAILS_ENV=test bundle exec rails db:prepare
bundle exec rspec spec/
bundle exec rubocop
node --test spec/javascript/*.cjs
```
 
The test database is `pt502_test` and is disposable.
 
## Deployment
 
The app is deployed on Heroku. The Procfile starts Puma and runs migrations during a Heroku release. It does not seed or import member data. Heroku operations, backups, import recovery, rollback, and costs are covered in the system guide (`/help/system`, officers only).
 
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
 
