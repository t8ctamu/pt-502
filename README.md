# PT-502

Physical Therapy Society member portal, built with Rails and PostgreSQL.

## Help and training

Once the app is running, choose **Help** in the navigation, or open:

- `/help/member`: sign-in, profiles, points, events, attendance, and outside-event requests.
- `/help/officer`: member management, dues, points, roles, events, and approvals (officers only).
- `/help/system`: installation, Heroku operations, backups, import recovery, rollback, and costs (officers only).

Before installation, open [the system guide](docs/system-guide.html) in a browser.
It is the same document served in the app. It includes local setup and initial
manager setup using `system:bootstrap`; no private settings are stored in it.

For feature changes, use [the help maintenance checklist](docs/help-maintenance.md).
Screenshots contain fictional training data.

## Checks

Use Ruby from `.ruby-version` and PostgreSQL. After local setup:

```sh
bundle exec rails db:prepare
RAILS_ENV=test bundle exec rails db:prepare
bundle exec rspec spec/
bundle exec rubocop
node --test spec/javascript/*.cjs
```

The test database is `pt502_test` and is disposable. The Procfile starts Puma
and runs migrations during a Heroku release; it does not seed or import member data.

