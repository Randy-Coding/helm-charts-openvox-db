# openvoxdb

Standalone OpenVox DB (PuppetDB). Chart version 0.1.0, application version 8.15.0-main.

## Configuration

This standalone chart deploys OpenVoxDB with bundled or external PostgreSQL and an
external Puppet Server connection. It installs no certificate jobs, Puppetboard,
or OpenVox View.
The image and interface defaults were adapted from `.resources/openvox-helm-chart`
at commit `ad67791`.

Bundled PostgreSQL uses the official PostgreSQL 17.11 image, enables `pg_trgm` and
`pgcrypto`, and generates a credential Secret when no password or existing Secret
is supplied. Set `postgresql.internal.enabled=false`,
`postgresql.external.hostname`, and `postgresql.shared.existingSecret` to use an
external service such as CloudNativePG.
The credential secret defaults to keys `username` and `password` and is referenced
directly.
Bundled PostgreSQL data persists in a 10Gi claim by default. The PostgreSQL image
runs as UID and GID 999 with a read-only root filesystem and writable mounts for
its data, runtime socket, and temporary files.
`extraEnv` overrides generated environment variables. `extraEnvSecret` supports
additional secret environment variables. Explicit environment values take
precedence over values imported from `extraEnvSecret`.

HTTPS is exposed at service port 8081 and HTTP at 8080. Certificate enrollment
remains the image's responsibility and requires a reachable Puppet Server and
appropriate certificate signing policy. `alternateServerNames` supplies
`DNS_ALT_NAMES`. Pre-provisioned certificates can be mounted with `extraVolumes`
and `extraVolumeMounts`, with matching configuration supplied through `customConfig`.

Persistence defaults to a 10Gi ReadWriteOnce claim at
`/opt/puppetlabs/server/data/puppetdb`. `persistence.existingClaim` reuses a claim.
Disabling persistence uses an emptyDir and loses data on pod replacement.
Custom `.conf` files are mounted individually into `/etc/puppetlabs/puppetdb/conf.d`
and changes trigger a rollout. SubPath-mounted files update when pods are replaced.

Enabling NetworkPolicy denies traffic except the supplied
`additionalIngressRules` and `additionalEgressRules`. Rules must allow the required
clients, DNS, PostgreSQL, Puppet Server, and monitoring traffic.

`metrics.enabled` adds a Prometheus exporter and its service port. Its default
query URL uses local HTTP. HTTPS can be configured through `metrics.url`,
`metrics.extraEnv`, and certificate volume mounts. `metrics.serviceMonitor.enabled`
requires the Prometheus Operator ServiceMonitor CRD and `metrics.enabled: true`.

## Runtime validation

The chart retains `runAsNonRoot: true`, dropped capabilities, no privilege
escalation, and a read-only root filesystem. It supplies writable data and `/tmp`
mounts and includes no privileged directory-setup init container. The OpenVoxDB
image reaches PostgreSQL successfully under these restrictions. Certificate
enrollment and complete service startup still require runtime validation against
an OpenVox Server.

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
| `podSecurityContext` | `{}` | Pod security context |
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
| `postgresql.shared.port` | `5432` | PostgreSQL port |
| `postgresql.shared.database` | `puppetdb` | PostgreSQL database name |
| `postgresql.shared.username` | `puppetdb` | PostgreSQL username |
| `postgresql.shared.existingSecret` | `""` | Existing secret containing PostgreSQL credentials |
| `postgresql.shared.usernameKey` | `username` | Username key in the credential Secret |
| `postgresql.shared.passwordKey` | `password` | Password key in the credential Secret |
| `postgresql.internal.enabled` | `true` | Deploy bundled PostgreSQL |
| `postgresql.internal.password` | `""` | Generated when bundled and empty |
| `postgresql.internal.image.repository` | `docker.io/library/postgres` | PostgreSQL image repository |
| `postgresql.internal.image.tag` | `17.11-bookworm` | PostgreSQL image tag |
| `postgresql.internal.image.pullPolicy` | `IfNotPresent` | PostgreSQL image pull policy |
| `postgresql.internal.resources` | `{}` | PostgreSQL resource requests and limits |
| `postgresql.internal.persistence.enabled` | `true` | Persist bundled PostgreSQL data |
| `postgresql.internal.persistence.existingClaim` | `""` | Existing PostgreSQL PVC name |
| `postgresql.internal.persistence.accessModes` | `[ReadWriteOnce]` | PostgreSQL PVC access modes |
| `postgresql.internal.persistence.storageClass` | `""` | PostgreSQL storage class |
| `postgresql.internal.persistence.annotations` | `{}` | PostgreSQL PVC annotations |
| `postgresql.internal.persistence.size` | `10Gi` | PostgreSQL storage size |
| `postgresql.external.hostname` | `""` | External PostgreSQL or CloudNativePG hostname |
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
