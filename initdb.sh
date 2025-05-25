#/usr/bin/env bash
set -euo pipefail

if ! command -v sqlx >/dev/null; then
    echo "sqlx command is missing, install sqlx with:" >&2
    echo "    cargo install sqlx-cli --no-default-features -F postgres" >&2
    exit 1
fi

if ! command -v psql >/dev/null; then
    echo "psql command is missing, install psql with your package manager" >&2
    exit 1
fi

# vars used by the docker image to setup postgres on _fresh_ start
# see https://github.com/docker-library/docs/blob/master/postgres/README.md#environment-variables
# database superuser name (don't confuse with linux superuser)
# see https://www.postgresql.org/docs/current/role-attributes.html#ROLE-ATTRIBUTES
: ${POSTGRES_USER:=postgres}
: ${POSTGRES_PASSWORD:=password} # database superuser password
: ${POSTGRES_DB:=newsletter} # database name

# forward this local port to postgres instance inside container
: ${LOCAL_PORT:=5432}

# lines below mean:
# `-p "$LOCAL_PORT":5432` - forward LOCAL_PORT to 5432 inside container
# `-d` - detach to background
# `postgres` - docker image name
# `postgres -N 1000` - start postgres server with max 1000 connections
docker run \
    -e POSTGRES_USER="$POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e POSTGRES_DB="$POSTGRES_DB" \
    -p "$LOCAL_PORT":5432 \
    -d \
    postgres \
    postgres -N 1000

# see https://www.postgresql.org/docs/17/libpq-envars.html
export PGPASSWORD="$POSTGRES_PASSWORD"
# wait for server to start (`\quit` below is a meta-command to quit psql)
while ! psql -U "$POSTGRES_USER" -h localhost -p "$LOCAL_PORT" -d "$POSTGRES_DB" -c '\quit'; do
    echo "postgres is not ready yet, sleeping 1s" >&2
    sleep 1
done

# tell sqlx where the database is (see https://github.com/launchbadge/sqlx/blob/main/sqlx-cli/README.md#usage)
# using postgres connection uri (see https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING-URIS)
export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${LOCAL_PORT}/${POSTGRES_DB}"
sqlx database create
sqlx migrate run
