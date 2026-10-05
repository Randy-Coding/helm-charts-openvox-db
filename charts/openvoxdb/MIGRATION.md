# PostgreSQL configuration and migration

## Migration from 0.1.x

This is a breaking configuration and storage change. Replace
`postgresql.internal.enabled` with `postgresql.enabled`, move internal image
and scheduling settings directly under `postgresql`, and move internal resources
and persistence settings under `postgresql.standalone`. Bundled database and
username settings now use `postgresql.auth.database` and `auth.username`.
The former internal password becomes `postgresql.auth.password`; an administrator
password is configured separately through `auth.postgresPassword`.

Existing installations require a database migration before upgrading. The former
standalone PVC and Secret are replaced by HelmForge's StatefulSet claim
(`data-<postgresql-statefulset>-0`) and auth Secret. HelmForge 2.0.5 does not expose
an `existingClaim` option. A normal Helm upgrade does not move existing data or
adapt the old credentials. The old database initialized `puppetdb` as the
bootstrap superuser, while HelmForge expects a `postgres` administrator and a
separate application account. Preserve the old PVC and credentials and migrate
the database into the new instance before retiring the old resources.

PostgreSQL remains on version 17.11. Choosing a new chart does not perform a
PostgreSQL major-version upgrade. Existing external connections retain their
`shared` and `external` settings and require the new enable flag.

## Bundled PostgreSQL configuration

Configure the subchart through native `postgresql.*` values.
OpenVoxDB follows its service name, port, database, application username,
and password Secret. Replication mode connects to the writable primary.
Use `postgresql.nameOverride` or `postgresql.fullnameOverride` for database names.

An existing `postgresql.auth.existingSecret` must contain `postgres-password`
and `user-password`, or the configured `auth.existingSecret*PasswordKey` keys.
Replication also requires its replication password key.
Extension initialization scripts run only on a fresh data directory.

The `prepare-read-database` init container creates or updates the query account
before each OpenVoxDB startup, including on already initialized databases.
Its password is stored separately and retained across upgrades.
Configure an existing read password Secret through `readDatabase.existingSecret`
and `readDatabase.passwordKey`. Administrator credentials are supplied only
to the provisioning container. Disable `readDatabase.enabled` when supplying
your own `customConfig.read-database.conf`.

## External PostgreSQL

Set `postgresql.enabled=false`, `postgresql.external.hostname`, and
`postgresql.shared.existingSecret`. The external credential Secret contains
`username` and `password` by default. The `postgresql.shared.*` settings
apply to external connections. Configure an independently managed query
account through `customConfig`; automatic provisioning applies to bundled PostgreSQL.
