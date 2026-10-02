# openvoxdb

Standalone OpenVox DB (PuppetDB). Chart version 0.1.0, application version 8.15.0-main.

## Configuration

This standalone chart deploys OpenVoxDB with external PostgreSQL and Puppet Server
connections. It installs no PostgreSQL, certificate jobs, Puppetboard, or OpenVox View.
The image and interface defaults were adapted from `.resources/openvox-helm-chart`
at commit `ad67791`.

Set `postgresql.hostname`, `postgresql.existingSecret`, and `puppetServer.hostname`.
The credential secret defaults to keys `username` and `password`. The existing
secret is referenced directly and is never copied into a chart-managed Secret.
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
mounts and includes no privileged directory-setup init container. Startup of
`ghcr.io/openvoxproject/openvoxdb:8.15.0-main` under these defaults has not been
validated. The reference chart documents a root requirement. Container image
user, entrypoint writes, certificate enrollment, and volume permissions require
runtime validation. A successful Helm render does not establish runtime compatibility.

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
| `postgresql.hostname` | `""` | PostgreSQL hostname |
| `postgresql.username` | `puppetdb` | PostgreSQL username, used when existingSecret is empty |
| `postgresql.existingSecret` | `""` | Existing secret containing PostgreSQL credentials |
| `postgresql.usernameKey` | `username` | Username key in existingSecret |
| `postgresql.passwordKey` | `password` | Password key in existingSecret |
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
