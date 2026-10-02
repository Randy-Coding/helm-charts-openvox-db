# openvox-db

OpenVox DB (PuppetDB) chart scaffold. Chart version: 0.1.0.

## Status

This chart does not deploy OpenVox DB yet. Only optional service-account creation
is implemented. Workload, networking, database connectivity, TLS, storage, and
probe configuration are pending. The image repository, image tag, and application
version will be selected during implementation.

[values.yaml](values.yaml) includes every required value from
`docs/chart-standards.md`, including workload settings and secure defaults.
Only naming overrides and service-account settings are currently wired to
templates. Remaining values will be wired during implementation.

## Validation

```bash
helm lint charts/openvoxdb --strict
helm unittest charts/openvoxdb
helm-docs --chart-search-root charts/openvoxdb
```

`README.md.gotmpl` supplies the status text and values table for helm-docs regeneration.
