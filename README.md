# duckdb-debian

Debian and Ubuntu packaging for [DuckDB](https://duckdb.org) — a fast,
in-process analytical SQL database ("SQLite for analytics"). It reads and
writes CSV, Parquet and JSON directly, speaks rich SQL with excellent
performance on analytical workloads, and installs extensions (httpfs,
spatial, …) at runtime from the official extension repository.

The package ships the official `duckdb` CLI, built from upstream's glibc
release binaries so runtime extension installs (`INSTALL httpfs;`) match the
official `linux_amd64`/`linux_arm64` extension platforms.

DuckDB is an embedded database: it runs inside the calling process, so there
is no server daemon, no configuration and no systemd unit — install it and
run `duckdb`.

Packages are built automatically from official upstream releases (usually
within hours) and served from **[deb.griffo.io](https://deb.griffo.io)** for
Debian (bookworm, trixie, forky, sid) and Ubuntu (jammy, noble, questing,
resolute) on amd64 and arm64 (the architectures upstream publishes Linux
CLI binaries for).

## Install

```bash
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list > /dev/null
sudo apt update
sudo apt install -y duckdb
```

Then:

```bash
duckdb              # in-memory interactive shell
duckdb mydb.duckdb  # persistent database file
```

## How it works

- `check-upstream.yml` polls upstream hourly; a new release dispatches `release.yml`.
- `release.yml` builds binary packages (Docker, per suite × architecture, from
  the upstream release binaries) and source packages (`.dsc`), then publishes
  a GitHub release tagged `<version>+<build>`.
- The deb.griffo.io mirror ingests published releases automatically.

Manual build: `./build.sh <version> <build> [arch|all]` (e.g. `./build.sh 1.5.4 1 all`).

## Links

- Upstream: https://github.com/duckdb/duckdb
- Site page: https://deb.griffo.io/install-latest-duckdb-in-debian.html
- Repository: https://deb.griffo.io
