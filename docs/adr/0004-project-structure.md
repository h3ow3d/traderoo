# ADR 0004: Project structure for Traderoo

## Status

Accepted

## Context

Traderoo is a local Kubernetes-hosted AI trading control plane proof of concept.

The MVP is paper-only and is intended to prove the full decision lifecycle:

1. Ingest market data.
2. Build features.
3. Generate observations.
4. Create candidate paper trades.
5. Review candidates against the trade triangle:

   * Signal / Edge
   * Safety / Risk
   * Situation / Context
6. Apply a deterministic risk gate.
7. Allow manual approval.
8. Open simulated paper positions.
9. Monitor positions.
10. Evaluate outcomes.
11. Present observations, trades, alerts, and performance in a visual interface.

The project will be built incrementally in chunks using GitHub Copilot. Each chunk must be independently understandable, testable, and deployable.

The project also needs a clear separation between:

* application code
* Kubernetes deployment manifests
* local platform bootstrap files
* documentation
* ADRs
* scripts
* tests

This separation is required so the system can grow safely without becoming an unstructured prototype.

## Decision

Use the following top-level repository structure:

```text
traderoo/
├── app/
├── applications/
├── platform/
├── docs/
├── scripts/
├── tests/
├── .gitignore
├── Makefile
└── README.md
```

### `app/`

Contains the Traderoo application code.

Initially, Traderoo will be built as a modular monolith rather than as multiple microservices. This keeps the proof of concept simple while still allowing clear subsystem boundaries inside the codebase.

Expected future structure:

```text
app/
├── main.py
├── config.py
├── db.py
├── models/
├── services/
├── workers/
├── templates/
└── static/
```

Application responsibilities will include:

* API routes
* server-rendered UI
* database models
* ingestion services
* feature builders
* observers
* candidate generation
* review providers
* risk gate
* paper execution
* watchers
* outcome evaluation

### `applications/`

Contains application-owned GitOps configuration for Traderoo.

This directory represents application runtime state that Argo CD will sync into the local Kubernetes cluster.

Structure:

```text
applications/
└── traderoo/
    ├── argocd/
    │   └── poc.yaml
    └── k8s/
        ├── base/
        │   ├── configmap.yaml
        │   └── kustomization.yaml
        └── overlays/
            └── poc/
                ├── kustomization.yaml
                └── configmap-patch.yaml
```

The `base/` directory contains reusable Kubernetes manifests.

The `overlays/poc/` directory contains active POC environment configuration.

Argo CD will point at the active POC overlay.

### `platform/`

Contains local platform bootstrap configuration that is not part of the application deployment itself.

Structure:

```text
platform/
├── k3d/
│   └── cluster.yaml
└── bootstrap/
    └── argocd/
        ├── install.md
        └── root-platform-application.yaml
```

This is where local Kubernetes and Argo CD bootstrap material lives.

The distinction is:

* `platform/` creates or documents the local platform.
* `applications/` deploys Traderoo onto that platform.

### `docs/`

Contains architecture, setup, ADRs, and product notes.

Structure:

```text
docs/
├── c4/
├── adr/
├── setup/
└── product/
```

#### `docs/c4/`

Contains C4-style architecture documentation.

Expected files:

```text
docs/c4/01-system-context.md
docs/c4/02-container-view.md
docs/c4/03-component-view.md
```

#### `docs/adr/`

Contains architectural decision records.

Initial ADRs:

```text
docs/adr/0001-local-kubernetes-with-k3d.md
docs/adr/0002-gitops-with-argocd.md
docs/adr/0003-paper-only-mvp.md
docs/adr/0004-project-structure.md
```

#### `docs/setup/`

Contains repeatable setup instructions.

Expected files:

```text
docs/setup/00-prerequisites.md
docs/setup/01-local-cluster.md
docs/setup/02-argocd.md
docs/setup/03-github-repo.md
docs/setup/04-validation.md
```

#### `docs/product/`

Contains product and MVP notes.

Expected files:

```text
docs/product/mvp-scope.md
docs/product/subsystem-map.md
docs/product/glossary.md
```

### `scripts/`

Contains helper scripts that are useful for setup, validation, local testing, or operational tasks.

Scripts should be small, explicit, and safe to run locally.

No secrets should be committed into this directory.

### `tests/`

Contains automated tests.

The test suite should grow with each implementation chunk.

Examples:

* API health tests
* database model tests
* ingestion tests
* feature calculation tests
* observer rule tests
* candidate generation tests
* risk gate tests
* paper execution tests
* watcher tests
* outcome evaluator tests

### `Makefile`

Provides repeatable project commands.

The Makefile is the primary operator interface during the POC phase.

It should include commands for:

* creating the local k3d cluster
* deleting the local cluster
* checking cluster status
* installing Argo CD
* retrieving the Argo CD password
* port-forwarding Argo CD
* applying the Argo CD Application
* syncing the Argo CD app
* validating local Kubernetes manifests

Future chunks may add commands for:

* running the app locally
* running tests
* building the container image
* applying database migrations
* seeding data
* running ingestion
* running observers
* generating candidates
* running reviews
* running the risk gate
* running watchers
* evaluating outcomes

### `README.md`

The root README is the entry point for the project.

It should explain:

* what Traderoo is
* what the MVP does and does not do
* paper-only safety constraint
* repository structure
* chunk roadmap
* local setup
* GitOps setup
* validation commands

## Key principles

### 1. Paper-only by default

The project structure must reinforce that Traderoo is a paper-only POC.

Live broker integration, real-money execution, leverage, CFDs, and spread betting are outside the MVP scope.

### 2. Modular monolith first

Traderoo should start as a modular monolith, not a distributed microservice system.

Subsystems should be separated in code, but not prematurely split into independent services.

This allows the project to remain understandable while still supporting later extraction if needed.

### 3. GitOps from the beginning

Kubernetes manifests live under `applications/`.

Argo CD syncs from GitHub into the local Kubernetes cluster.

Application deployment state should be reviewable in Git.

### 4. Documentation is part of the system

Architecture, setup instructions, ADRs, and MVP scope must live in the repository.

This is important because the system will be built incrementally with AI assistance. Clear documentation reduces drift and prevents Copilot from making inconsistent assumptions between chunks.

### 5. Each chunk must be independently testable

The structure should support incremental development.

A chunk should add a small amount of functionality, tests, and validation instructions without requiring future chunks to exist.

## Consequences

### Positive

* The project has a clear home for every type of artefact.
* GitOps deployment can be validated before application code exists.
* Documentation and ADRs are present from the start.
* Copilot can be given bounded implementation chunks.
* The system can grow without immediately becoming a microservice architecture.
* Platform bootstrap and application deployment are cleanly separated.

### Negative

* The initial structure may feel heavier than a throwaway prototype.
* Some directories will contain only placeholder files during Chunk 0.
* The modular monolith may need refactoring later if the system grows significantly.
* Maintaining documentation and ADRs requires discipline.

## Alternatives considered

### Flat prototype structure

A flat structure with app files, manifests, scripts, and notes all in the root would be faster initially.

Rejected because Traderoo is intended to grow through multiple subsystems and Copilot-assisted chunks. A flat structure would become confusing quickly.

### Microservices from the start

A separate service for ingestion, observation, review, risk, execution, watchers, and UI would create strong boundaries.

Rejected for the MVP because it would add unnecessary distributed-system complexity before the core decision loop is proven.

### Infrastructure and application in separate repositories

A separate platform repository and application repository would create a cleaner production-style split.

Rejected for the POC because a single repository is simpler, easier to bootstrap, and easier for Copilot-assisted development.

## Decision outcome

Traderoo will use a single repository with clear top-level separation between application code, deployment configuration, platform bootstrap, documentation, scripts, and tests.

The initial project structure is accepted as the baseline for Chunk 0 and should be used by all future implementation chunks.
