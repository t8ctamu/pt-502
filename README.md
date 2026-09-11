# PT-502

Rails starter for the team project, using the course Docker image
`paulinewade/csce431:sp26v1` (Ruby 3.4.6), PostgreSQL, RSpec, SimpleCov,
and RuboCop. The earlier `csce431/test_app` practice project is unchanged.

## Windows: use your course container

Start Docker Desktop. Open PowerShell in this repository. Find your container name
with `docker ps -a` (names differ between teammates).

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\lab.ps1 setup -Container admiring_liskov
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\lab.ps1 test -Container admiring_liskov
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\lab.ps1 lint -Container admiring_liskov
Start-Process .\coverage\index.html
```

Replace `admiring_liskov` with YOUR container name. You do not need Ruby installed
directly on Windows. Run setup after cloning; run test and lint before pushing.

If you have no course container yet, create one from the same image:

```powershell
docker run -dit --name pt502-dev -p 3000:3000 paulinewade/csce431:sp26v1 bash
```

Then use `-Container pt502-dev` above. Port 3000 must be available.

The helper copies the latest files from this repo into a fresh temporary directory
inside the container, runs the requested command, copies back the lockfile/schema
and coverage report, then removes that temporary copy. Edit code in THIS host repo;
do not edit the temporary container copy. No Docker bind-mount change is needed.
The database and installed gems persist inside your container. A separate local
`pt502` PostgreSQL role and databases are used; the practice app is untouched.
Local database credentials live only in `/root/.pt502-database-env` in the container.

For a development server (Ctrl+C to stop):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\lab.ps1 server -Container admiring_liskov
```

Open http://localhost:3000/up for the Rails health check. Restart this command after
editing host files to copy your changes into the container. This is a starter app;
no team feature UI has been implemented yet.

## Team workflow

One person sets up these shared files. Everyone pulls them and runs local setup.
Each member should create their own branch, implement their assigned contribution,
run tests/lint, commit, push, and open a pull request. Pulling alone is not a commit.

```powershell
git pull --ff-only
git switch -c your-feature-branch
# Edit the app and add specs, then run the test/lint commands above.
git add <specific-files-you-changed>
git commit -m "Describe your contribution"
git push -u origin your-feature-branch
```

Commit source code, tests, Gemfile/Gemfile.lock, schemas/migrations, and CI config.
Do not commit coverage reports, evidence output, local databases, or secrets.

## What is verified

The initial suite checks `/up`, a missing route, and a real connection to
`pt502_test`. These are infrastructure checks, not completed backlog features.
SimpleCov starts before Rails loads and includes all Ruby files under `app/`.
The starter has only 9 executable application lines, so its initial 100% coverage
does not mean the future team project is fully tested. Add meaningful specs as
features are implemented. RuboCop uses Rails' generated Omakase configuration.

The workflow in `.github/workflows/ci.yml` runs on pushes and pull requests with
PostgreSQL 17, prepares the database, runs RSpec and RuboCop, and uploads coverage.
Local command output is saved in `evidence/`; the HTML report is in `coverage/`.

## Remaining group-lab work

- Implement a real model association appropriate to the team's agreed data model.
- Add a test for an actual backlog feature.
- Capture that association code for the submission form.
- Write the team's actual risk plan and record each member's contribution.
- Obtain the customer's Heroku/account evidence and follow the course deployment
  instructions. No customer account or deployment is created by this setup.

## References

- RSpec installation: https://github.com/rspec/rspec-rails
- SimpleCov configuration: https://github.com/simplecov-ruby/simplecov

## Earlier repository note

The original README said: "This feature is traked in jira and will be integrate in a pull request."
