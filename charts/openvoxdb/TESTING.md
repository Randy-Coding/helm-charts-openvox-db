# Testing OpenVoxDB

## Local chart checks

From the repository root, with Helm and the helm-unittest plugin installed:

```sh
helm dependency build charts/openvoxdb
helm lint charts/openvoxdb
helm unittest charts/openvoxdb
```

Dependency build is needed when dependencies are missing or the lock file changes.
The unit tests render templates locally. They require no Kubernetes cluster.

## API smoke test

Prerequisites: a running release with `puppetServer.enabled=false`, access to its
HTTP port, and `curl`. Forward the service's HTTP port to local port 8080 using
your existing namespace. The commands below assume that forwarding is active.

Create `facts.json` with a current UTC timestamp:

```sh
cat > facts.json <<EOF
{
  "certname": "openvoxdb-test-node",
  "environment": "testing",
  "producer": "manual-test",
  "producer_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "values": {
    "hostname": "openvoxdb-test-node",
    "test_marker": "openvoxdb-smoke-test"
  }
}
EOF
```

Submit the facts:

```sh
curl --fail-with-body \
  -H 'Content-Type: application/json' \
  --data-binary @facts.json \
  'http://localhost:8080/pdb/cmd/v1?command=replace_facts&version=5&certname=openvoxdb-test-node'
```

Expect a JSON response containing a command UUID. Query the node's facts:

```sh
curl --fail-with-body --get \
  --data-urlencode 'query=["=","certname","openvoxdb-test-node"]' \
  'http://localhost:8080/pdb/query/v4/facts'
```

Expect `test_marker` to equal `openvoxdb-smoke-test`.
Commands process asynchronously. If the result is `[]`, retry after a few seconds.
This checks command acceptance, database writes, and query-pool reads.
The sample node remains in the database after this test.
See the [command API](https://github.com/puppetlabs/puppetdb/blob/main/documentation/api/command/v1/commands.markdown)
for the facts payload format.

## Validation status

Local chart tests and standalone startup with bundled PostgreSQL passed.
The facts submission/query smoke test passed on the deployed release.

The following runtime checks remain unverified:

- Data persistence after application and database restarts.
- Credential and data retention across Helm upgrades.
- Server enrollment and HTTPS with an OpenVox Server.
