# openvoxdb

Standalone OpenVox DB (PuppetDB). Chart version 0.2.0, application version 8.15.0-main.

## Configuration

This standalone chart deploys OpenVoxDB with bundled or external PostgreSQL and an
external Puppet Server connection. It installs no certificate jobs, Puppetboard,
or OpenVox View.
The image and interface defaults were adapted from `.resources/openvox-helm-chart`
at commit `ad67791`.

Bundled PostgreSQL is provided by the pinned HelmForge PostgreSQL 2.0.5 subchart.
It uses the official PostgreSQL 17.11 image, initializes `pg_trgm` and `pgcrypto`
in the configured application database, and persists data in a 10Gi claim.
Run `helm dependency build charts/openvoxdb` before linting, testing, or installing
from this source directory. The release workflow includes the dependency in the
published chart.

Configure the subchart through native `postgresql.*` values, including
`auth.database`, `auth.username`, `auth.password`, and
`standalone.persistence`. OpenVoxDB follows the subchart's service name, port,
database, application username, and password Secret. Replication mode uses the
writable primary service. Parent name overrides do not rename the subchart;
use `postgresql.nameOverride` or `postgresql.fullnameOverride`.

HelmForge creates separate administrator and application passwords when empty.
An existing `postgresql.auth.existingSecret` must contain `postgres-password`
and `user-password`, or the configured `auth.existingSecret*PasswordKey` keys.
Replication also requires the replication password key. OpenVoxDB reads the
application password only. Initialization scripts run only on a fresh data directory.
The PostgreSQL image runs as UID and GID 999 with a read-only root filesystem
and writable mounts for data, runtime sockets, and temporary files.

For an external service such as CloudNativePG, set `postgresql.enabled=false`,
`postgresql.external.hostname`, and `postgresql.shared.existingSecret`.
The `postgresql.shared.*` values apply only to external connections. External
credential Secrets retain the `username` and `password` keys by default.
`extraEnv` overrides generated environment variables. `extraEnvSecret` supports
additional secret environment variables. Explicit environment values take
precedence over values imported from `extraEnvSecret`.

HTTPS is exposed at service port 8081 and HTTP at 8080. Certificate enrollment
remains the image's responsibility and requires a reachable Puppet Server and
appropriate certificate signing policy. `alternateServerNames` supplies
`DNS_ALT_NAMES`. Pre-provisioned certificates can be mounted with `extraVolumes`
and `extraVolumeMounts`, with matching configuration supplied through `customConfig`.
Set `puppetServer.enabled=false` to skip waiting for an external Puppet Server
and certificate enrollment (`USE_OPENVOXSERVER=false`). This supports standalone
HTTP operation. The setting controls enrollment and does not deploy a server.

Persistence defaults to a 10Gi ReadWriteOnce claim at
`/opt/puppetlabs/server/data/puppetdb`. `persistence.existingClaim` reuses a claim.
Disabling persistence uses an emptyDir and loses data on pod replacement.
A non-root `prepare-data` init container creates the log directory on the data
volume before Java starts. It uses the OpenVoxDB image, UID 64604, and GID 0.
The pod defaults to `fsGroup: 0` so the mounted volume is writable by that group.
User-supplied `extraInitContainers` run after data preparation.

Bundled PostgreSQL uses a separate `puppetdb_read` account for the query pool.
Configure it through `readDatabase.*`; the password is stored in a separate
Secret and retained across Helm upgrades. An existing Secret is supported through
`readDatabase.existingSecret` and `readDatabase.passwordKey`.
A non-root `prepare-read-database` init container connects as the PostgreSQL
administrator to create or update this account before OpenVoxDB starts. It grants
SELECT on existing tables and default read permissions on future migration objects,
and grants the read role to the writer for partition cleanup. This also supports
databases that have already completed migrations, without resetting their data.
The administrator password is available only to this provisioning container.
Generated `read-database.conf` references environment variables for credentials.
Set `readDatabase.enabled=false` to supply your own read-pool configuration.
Automatic provisioning applies only to bundled PostgreSQL. External databases
can use `customConfig` to configure an independently managed read-only account.
Custom `.conf` files are mounted individually into `/etc/puppetlabs/puppetdb/conf.d`
and changes trigger a rollout. SubPath-mounted files update when pods are replaced.

Enabling NetworkPolicy denies traffic except the supplied
`additionalIngressRules` and `additionalEgressRules`. Rules must allow the required
clients, DNS, PostgreSQL, Puppet Server, and monitoring traffic.

`metrics.enabled` adds a Prometheus exporter and its service port. Its default
query URL uses local HTTP. HTTPS can be configured through `metrics.url`,
`metrics.extraEnv`, and certificate volume mounts. `metrics.serviceMonitor.enabled`
requires the Prometheus Operator ServiceMonitor CRD and `metrics.enabled: true`.

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

## Runtime validation

The chart retains `runAsNonRoot: true`, dropped capabilities, no privilege
escalation, and a read-only root filesystem. It supplies writable data and `/tmp`
mounts and includes no privileged directory-setup init container. Certificate
enrollment and complete service startup require runtime validation against an
OpenVox Server. HelmForge integration is verified by local rendering and unit
tests; the replacement has not been deployed to Kubernetes.

## Values

| Key | Default | Description |
| --- | --- | --- |
| `nameOverride` | `""` | Override the chart name |
| `fullnameOverride` | `""` | Override the fully qualified app name |
| `image.repository` | `ghcr.io/openvoxproject/openvoxdb` | Image repository |
| `image.tag` | `8.15.0-main` | Image tag |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy |
| `imagePullSecrets` | `[]` | Image pull secrets for private registries |
| `replicaCount` | `1` | Number of replicas |
| `extraEnv` | `{}` | Additional environment variables as key-value pairs |
| `extraEnvSecret` | `""` | Name of an existing secret to use as additional environment variables |
| `resources` | `{}` | Container resource requests and limits |
| `securityContext.runAsNonRoot` | `true` |  |
| `securityContext.allowPrivilegeEscalation` | `false` |  |
| `securityContext.readOnlyRootFilesystem` | `true` |  |
| `podSecurityContext` | `fsGroup: 0`, `fsGroupChangePolicy: OnRootMismatch` | Pod security context for writable OpenVoxDB data |
| `nodeSelector` | `{}` | Node selector for pod assignment |
| `tolerations` | `[]` | Tolerations for pod assignment |
| `affinity` | `{}` | Affinity rules for pod assignment |
| `topologySpreadConstraints` | `[]` | Topology spread constraints for pod assignment |
| `priorityClassName` | `""` | Priority class name |
| `podAnnotations` | `{}` | Additional pod annotations |
| `podLabels` | `{}` | Additional pod labels |
| `updateStrategy.type` | `Recreate` |  |
| `terminationGracePeriodSeconds` | `30` | Termination grace period in seconds |
| `serviceAccount.create` | `false` | Create a service account |
| `serviceAccount.name` | `""` | Service account name (generated if empty and create is true) |
| `serviceAccount.annotations` | `{}` | Service account annotations |
| `podDisruptionBudget.enabled` | `false` | Enable PDB |
| `podDisruptionBudget.minAvailable` | `1` | Minimum available pods |
| `podDisruptionBudget.maxUnavailable` | `""` | Maximum unavailable pods (mutually exclusive with minAvailable) |
| `livenessProbe` | `{}` | Liveness probe configuration |
| `readinessProbe` | `{}` | Readiness probe configuration |
| `startupProbe` | `{}` | Startup probe configuration |
| `extraContainers` | `[]` | Additional sidecar containers |
| `extraVolumes` | `[]` | Additional volumes |
| `extraVolumeMounts` | `[]` | Additional volume mounts |
| `extraInitContainers` | `[]` | Additional init containers |
| `service.type` | `ClusterIP` | Service type |
| `service.port` | `8081` | Service port |
| `service.httpPort` | `8080` | HTTP service port |
| `service.annotations` | `{}` | Service annotations |
| `service.labels` | `{}` | Service labels |
| `postgresql.enabled` | `true` | Deploy the HelmForge PostgreSQL subchart |
| `postgresql.architecture` | `standalone` | Standalone or replication architecture |
| `postgresql.nameOverride` | `""` | Override the subchart name |
| `postgresql.fullnameOverride` | `""` | Override the subchart resource name |
| `postgresql.image.repository` | `docker.io/library/postgres` | PostgreSQL image repository |
| `postgresql.image.tag` | `17.11-bookworm` | PostgreSQL image tag |
| `postgresql.image.pullPolicy` | `IfNotPresent` | PostgreSQL image pull policy |
| `postgresql.auth.database` | `puppetdb` | Bundled application database |
| `postgresql.auth.username` | `puppetdb` | Bundled application username |
| `postgresql.auth.postgresPassword` | `""` | Administrator password, generated when empty |
| `postgresql.auth.password` | `""` | Application password, generated when empty |
| `postgresql.auth.existingSecret` | `""` | Existing administrator and application password Secret |
| `postgresql.auth.existingSecretPostgresPasswordKey` | `postgres-password` | Administrator password key |
| `postgresql.auth.existingSecretUserPasswordKey` | `user-password` | Application password key used by OpenVoxDB |
| `postgresql.service.port` | `5432` | Bundled PostgreSQL port |
| `postgresql.standalone.resourcesPreset` | `none` | PostgreSQL resource preset |
| `postgresql.standalone.resources` | `{}` | Explicit PostgreSQL resources |
| `postgresql.standalone.persistence.enabled` | `true` | Persist bundled PostgreSQL data |
| `postgresql.standalone.persistence.accessModes` | `[ReadWriteOnce]` | PostgreSQL PVC access modes |
| `postgresql.standalone.persistence.storageClass` | `""` | PostgreSQL storage class |
| `postgresql.standalone.persistence.size` | `10Gi` | PostgreSQL storage size |
| `postgresql.securityContext` | See values.yaml | Non-root, read-only container configuration |
| `postgresql.podSecurityContext` | See values.yaml | PostgreSQL filesystem permissions |
| `postgresql.extraVolumes` | Runtime and temporary emptyDirs | Writable PostgreSQL runtime volumes |
| `postgresql.extraVolumeMounts` | `/var/run/postgresql`, `/tmp` | Writable runtime mount paths |
| `postgresql.initdb.scripts` | Extension initialization script | Initialize pg_trgm and pgcrypto in the application database |
| `postgresql.shared.port` | `5432` | External PostgreSQL port |
| `postgresql.shared.database` | `puppetdb` | PostgreSQL database name |
| `postgresql.shared.username` | `puppetdb` | PostgreSQL username |
| `postgresql.shared.existingSecret` | `""` | Existing secret containing PostgreSQL credentials |
| `postgresql.shared.usernameKey` | `username` | Username key in the credential Secret |
| `postgresql.shared.passwordKey` | `password` | Password key in the credential Secret |
| `postgresql.external.hostname` | `""` | External PostgreSQL or CloudNativePG hostname |
| `puppetServer.enabled` | `true` | Wait for an external Puppet Server and enroll TLS certificates |
| `readDatabase.enabled` | `true` | Provision a separate query account for bundled PostgreSQL |
| `readDatabase.username` | `puppetdb_read` | Read-only database account |
| `readDatabase.password` | `""` | Read-only password, generated and retained when empty |
| `readDatabase.existingSecret` | `""` | Existing read-only password Secret |
| `readDatabase.passwordKey` | `password` | Read-only password key |
| `puppetServer.hostname` | `""` | Puppet Server hostname |
| `puppetServer.port` | `8140` | Puppet Server port |
| `javaArgs` | `""` | JVM arguments (extraEnv.PUPPETDB_JAVA_ARGS takes precedence) |
| `alternateServerNames` | `""` | Additional certificate DNS names, comma separated |
| `customConfig` | `{}` | Custom conf.d files keyed by filename, mounted individually |
| `persistence.enabled` | `true` | Create or mount persistent storage instead of emptyDir |
| `persistence.existingClaim` | `""` | Existing PVC name (suppresses PVC creation) |
| `persistence.accessModes` | `[ReadWriteOnce]` | PVC access modes |
| `persistence.storageClass` | `""` | Storage class, empty uses cluster default, '-' disables dynamic provisioning |
| `persistence.annotations` | `{}` | PVC annotations |
| `persistence.size` | `10Gi` | Requested storage size |
| `networkPolicy.enabled` | `false` | Create a NetworkPolicy |
| `networkPolicy.policyTypes` | `[Ingress, Egress]` | Policy directions |
| `networkPolicy.additionalIngressRules` | `[]` | Allowed incoming traffic, including clients and monitoring |
| `networkPolicy.additionalEgressRules` | `[]` | Allowed outgoing traffic, including DNS, PostgreSQL and Puppet Server |
| `metrics.enabled` | `false` | Deploy the exporter sidecar and expose its port |
| `metrics.image.repository` | `camptocamp/prometheus-puppetdb-exporter` |  |
| `metrics.image.tag` | `1.1.0` |  |
| `metrics.image.pullPolicy` | `IfNotPresent` |  |
| `metrics.port` | `9635` | Exporter port |
| `metrics.interval` | `30s` | Exporter scrape interval |
| `metrics.resources` | `{}` | Exporter resource requests and limits |
| `metrics.extraEnv` | `{}` | Exporter environment overrides, including certificate paths for HTTPS |
| `metrics.extraEnvSecret` | `""` | Secret containing exporter environment variables |
| `metrics.url` | `http://localhost:8080/pdb/query` | Exporter target URL. HTTPS credentials can be mounted using extraVolumes. |
| `metrics.serviceMonitor.enabled` | `false` |  |
| `metrics.serviceMonitor.namespace` | `""` |  |
| `metrics.serviceMonitor.additionalLabels` | `{}` |  |
| `metrics.serviceMonitor.interval` | `30s` |  |
| `metrics.serviceMonitor.scrapeTimeout` | `""` |  |
| `metrics.serviceMonitor.honorLabels` | `true` |  |
| `metrics.serviceMonitor.relabelings` | `[]` |  |
| `metrics.serviceMonitor.metricRelabelings` | `[]` |  |
