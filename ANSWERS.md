Inventory first:
List all ingress objects, annotations (rewrites, auth, timeouts, TLS, canary), hosts, and which controllers own them. Highlight anything that's non-portable i.e. nginx specific snippets or custom Configmaps.

Stand up Gateway API in parallel:
Install Gateway API CRDs and a controller (Envoy Gateway, etc) alongside ingress-nginx. Create a Gateway and sample HTTPRoutes without touching existing traffic.

Translate in batches:
Convert Ingress to HTTPRoute/Gateway (and ReferenceGrants where cross-namespace). Prefer tooling (ingress2gateway) and then handfix annotations nginx specific ones that don't have equivalents.

Dual-publish DNS / shared entrypoint:
Point a test hostname (or weighted DNS / second VIP) to the new Gateway, check paths, TLS, headers and backends for a pilot set of apps.

Shift traffic gradually:
Move cohorts of hostnames (or utilize traffic splitting, if supported) to the new controller. Leave the old Ingress objects in place until the cohort has been proven stable.

Decommission:
Once all hosts have been migrated, delete the Ingress objects, than uninstall ingress-nginx.

What I expect to break:

Nginx-only annotations (configuration-snippet, force-ssl-redirect quirks, custom error pages) with no Gateway equivalent.

Subtle path/rewrite and header behaviour differences.

TLS edge cases (SNI, shared certs, redirect chains).

Observability gaps until dashboards/alerts are rewired to the new controller.

Cross-namespace backend refs without ReferenceGrants.

Risk posture: parallel run + batch cutover beats a big-bang switch; every step is reversible until the final uninstall.
