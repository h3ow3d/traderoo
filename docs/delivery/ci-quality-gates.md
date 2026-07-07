# Traderoo CI Quality Gates

## 1. Purpose

This document defines the CI and quality gate expectations for Traderoo.

Traderoo should use GitHub Actions to validate pull requests before merge.

The purpose of CI is to make sure each delivery chunk remains:

```text
working
tested
safe
reviewable
paper-only
aligned with the documented architecture
```

CI should support the incremental delivery model defined in:

```text
docs/delivery/chunk-plan.md
docs/delivery/validation-matrix.md
docs/delivery/definition-of-done.md
```

---

## 2. Core CI rule

Every pull request must be validated before merge.

CI should run on:

```text
pull_request targeting main
push to main
manual workflow_dispatch
```

Pull request checks should be required before merging to `main`.

---

## 3. CI principles

## 3.1 Keep checks boring

CI should be simple, deterministic, and easy to debug.

Prefer clear jobs over clever automation.

## 3.2 Match the current chunk

CI should grow as Traderoo grows.

Do not add complex checks for components that do not exist yet.

## 3.3 Fail closed on safety issues

If CI detects unsafe trading functionality, it should fail.

## 3.4 Keep local and CI commands aligned

The same checks should be runnable locally through `make` where practical.

## 3.5 Do not depend on the local k3d cluster in GitHub CI

GitHub CI should not assume access to the developer’s local k3d cluster.

Cluster-level debugging remains a local VS Code Copilot Agent task.

GitHub CI should validate manifests and run tests, not deploy to the local machine.

---

## 4. Initial CI scope

For early chunks, CI should validate:

```text
repository structure
documentation presence
YAML syntax
Kustomize render
paper-only configuration
Makefile syntax where practical
no obvious live broker configuration
```

Initial workflow:

```text
.github/workflows/ci.yml
```

Initial jobs:

```text
repo-checks
kubernetes-manifest-checks
paper-only-policy-checks
```

---

## 5. Python CI scope

From Chunk 1 onward, when Python application code exists, CI should add:

```text
Python dependency install
unit tests
linting
format checking
type checking, if configured
```

Preferred checks:

```text
pytest
ruff check
ruff format --check
mypy, if type checking is configured
```

If `mypy` is too noisy early, introduce it only once the project has stable typed models.

---

## 6. Kubernetes CI scope

For Kubernetes manifests, CI should validate:

```text
platform-services chart lint succeeds
platform-services chart templates to AppProject resources
Kustomize base renders
Kustomize local overlay renders
required namespace exists in rendered output
required ConfigMap exists in rendered output
EXECUTION_MODE is PAPER_ONLY
REVIEW_PROVIDER is mock
no broker secrets exist
```

CI should not apply manifests to a real cluster unless explicitly added later.

Expected validation command shape:

```bash
helm lint platform/charts/platform-services
helm template platform-services platform/charts/platform-services --dry-run=client
kubectl kustomize applications/traderoo/k8s/base
kubectl kustomize applications/traderoo/k8s/overlays/local
```

---

## 7. Safety policy checks

CI should protect the MVP paper-only boundary.

Checks should fail if obvious prohibited terms appear in executable/configuration areas.

Prohibited concepts include:

```text
live broker adapter
real broker credentials
real order placement
CFDs
spread betting
options trading
leverage
real-money execution
```

The check should avoid blocking documentation files that describe prohibited features as out of scope.

Apply safety scanning mainly to:

```text
app/
applications/
platform/
scripts/
tests/
.github/workflows/
```

Do not treat `docs/safety/` as a violation source because those documents intentionally list prohibited features.

---

## 8. Recommended workflow names

Use stable workflow and job names so branch protection can require them.

Recommended workflow:

```text
CI
```

Recommended initial jobs:

```text
repo-checks
kubernetes-manifest-checks
paper-only-policy-checks
```

Recommended future jobs:

```text
python-quality
python-tests
container-build
```

---

## 9. Branch protection

The `main` branch should be protected.

Recommended rules:

```text
require pull request before merge
require status checks before merge
require branches to be up to date before merge
require conversation resolution before merge
block direct pushes to main
```

Required checks should include the stable CI job names.

---

## 10. Chunk-by-chunk CI expectations

| Chunk | CI expectation                                                       |
| ----- | -------------------------------------------------------------------- |
| 0     | Repo, docs, platform chart, Kubernetes manifest, Kustomize, paper-only policy checks |
| 1     | Add Python install, FastAPI health tests, lint/format checks         |
| 2     | Add database model tests and migration/init checks                   |
| 3     | Add ingestion tests with mocked provider                             |
| 4     | Add feature calculation and observer tests                           |
| 5     | Add candidate generation tests                                       |
| 6     | Add review schema and mock provider tests                            |
| 7     | Add deterministic risk gate tests                                    |
| 8     | Add manual approval and paper execution safety tests                 |
| 9     | Add watcher and alert tests                                          |
| 10    | Add outcome evaluation tests                                         |
| 11    | Add OpenAI provider tests using fake client only                     |
| 12    | Add final Kubernetes/workflow polish checks                          |

---

## 11. CI must not do

CI must not:

```text
deploy to the user’s local k3d cluster
require real broker credentials
require OpenAI credentials for normal PR tests
place real trades
call real broker APIs
depend on live market data for unit tests
depend on secrets for basic validation
```

OpenAI-specific tests should use fakes/mocks unless explicitly running an optional integration workflow.

---

## 12. Required PR evidence

Every PR should state:

```text
which checks were added or updated
which tests were run locally
which CI checks are expected to pass
whether PAPER_ONLY guardrails remain intact
```

The PR should not be marked ready if CI is failing.

---

## 13. Copilot instruction

When Copilot implements a chunk, it must check whether CI needs updating.

Copilot should not treat CI as optional.

For each chunk, Copilot should answer:

```text
Does this change add code?
Does this change add Kubernetes manifests?
Does this change add domain logic?
Does this change add safety-sensitive behaviour?
Does CI validate the new behaviour?
Are local validation commands aligned with CI?
```

If the answer shows a gap, update CI as part of the same chunk.

---

## 14. Summary

Traderoo CI should act as the project’s quality gate.

The desired state is:

```text
Copilot implements a small chunk.
CI validates the chunk.
GitHub Copilot reviews the PR.
The user reviews the result.
Only passing, reviewed PRs merge to main.
```

CI is not separate from delivery.

CI is part of the definition of done.
