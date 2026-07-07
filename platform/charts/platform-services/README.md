# platform-services chart

This Helm chart is a platform-owned wrapper for shared GitOps guardrails.

Current render scope:

- Argo CD AppProject `platform`
- Argo CD AppProject `applications`

This chart must not render Traderoo application manifests.
