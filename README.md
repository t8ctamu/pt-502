# PT-502

Our CSCE 431 group project. Built with Ruby on Rails and PostgreSQL.

Start Docker Desktop, then run these from the project folder in PowerShell.
Replace `YOUR_CONTAINER` with your container name from `docker ps -a`.

```powershell
powershell -ExecutionPolicy Bypass -File .\script\lab.ps1 setup -Container YOUR_CONTAINER
powershell -ExecutionPolicy Bypass -File .\script\lab.ps1 test -Container YOUR_CONTAINER
powershell -ExecutionPolicy Bypass -File .\script\lab.ps1 lint -Container YOUR_CONTAINER
```

Open `coverage/index.html` to see test coverage.
