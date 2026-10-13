@echo off
setlocal
cd /d "%~dp0" || goto :failed

where docker >nul 2>&1
if errorlevel 1 (
    echo Docker was not found. Install and start Docker Desktop, then retry.
    goto :failed
)

docker compose version >nul 2>&1
if errorlevel 1 (
    echo Docker Compose is unavailable. Update Docker Desktop, then retry.
    goto :failed
)

if not exist .env (
    if not exist .env.example (
        echo .env.example is missing.
        goto :failed
    )
    copy .env.example .env >nul
    if errorlevel 1 (
        echo Could not create .env from .env.example.
        goto :failed
    )
    echo Created .env with development-only placeholders. Review it before production use.
)

docker compose up --build -d
if errorlevel 1 (
    echo Docker Compose startup failed. Review the error above.
    goto :failed
)

docker compose ps
if errorlevel 1 goto :failed
echo Stack started. Apply the database migration before checking readiness:
echo docker compose run --rm backend alembic upgrade head
echo API: http://localhost:8000/docs
pause
exit /b 0

:failed
echo Startup did not complete. No database volumes were removed.
pause
exit /b 1
