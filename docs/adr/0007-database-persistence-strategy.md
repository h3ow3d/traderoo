# ADR 0007: Database and Persistence Strategy

## Status

Accepted

## Date

2026-07-07

## Context

Traderoo will eventually need durable persistence for the core paper-trading lifecycle.

The system is expected to record and query:

* market observations
* derived features
* trade candidates
* AI reviews
* risk-gate decisions
* paper trades
* watcher events
* alerts
* outcome evaluations
* audit history

This data needs to be queryable, relational, auditable, and suitable for future multi-environment operation.

Traderoo is being designed to run in Kubernetes with a platform/application separation:

* the platform layer owns shared infrastructure and guardrails
* the application layer owns Traderoo application code, schema, migrations, and workload manifests
* each application environment should have its own isolated runtime boundary

The current active environment is only:

```text
traderoo-poc
```

Future environments may include:

```text
traderoo-dev
traderoo-staging
traderoo-demo
traderoo-production
```

The database implementation is not required for Chunk 1. Chunk 1 should remain a minimal runtime skeleton and should not introduce persistence.

## Decision

Traderoo will use PostgreSQL as its system-of-record database.

The Python application will use SQLAlchemy for database access.

Schema changes will be managed through Alembic migrations.

When Traderoo is ready to run PostgreSQL inside Kubernetes, the preferred platform-managed database operator will be CloudNativePG.

The platform layer will own database infrastructure.

The Traderoo application layer will own:

* SQLAlchemy models
* Alembic migrations
* application database access code
* migration jobs or migration execution workflow, when introduced

SQLite will not be used as the runtime persistence target.

Specialised time-series storage is deferred until market-data volume or query patterns prove PostgreSQL is insufficient.

## Current Scope

This ADR records the persistence decision only.

The current active implementation remains:

```text
PAPER_ONLY
REVIEW_PROVIDER=mock
```

Chunk 1 must not implement:

* PostgreSQL
* CloudNativePG
* Alembic
* SQLAlchemy models
* database migrations
* database credentials
* Kubernetes Secrets
* Vault integration
* External Secrets Operator integration

Chunk 1 may prepare the application shape so that persistence can be added cleanly later, but the application must not require a database to start or pass readiness checks.

## Ownership Model

The intended future ownership model is:

```text
Platform layer:
  - CloudNativePG operator
  - database cluster infrastructure
  - database namespaces or platform-owned database boundaries
  - secret delivery mechanism
  - backup/restore platform capability

Application layer:
  - schema models
  - migration history
  - migration execution
  - application database usage
  - app-level validation of database connectivity
```

The application must not hand-roll database infrastructure directly in its workload manifests.

## Environment Model

Each Traderoo environment should have an isolated persistence boundary.

Future examples:

```text
traderoo-poc database boundary
traderoo-dev database boundary
traderoo-staging database boundary
traderoo-demo database boundary
traderoo-production database boundary
```

The exact implementation may be one database per environment, one PostgreSQL cluster with separate databases, or another CloudNativePG-supported topology. That decision is deferred until the database implementation chunk.

## Rationale

PostgreSQL is a good fit because Traderoo needs durable relational records, auditability, constraints, indexes, transactions, and flexible querying.

The main persistence problem is not high-volume market tick storage at this stage. The first persistence problem is preserving the decision chain:

```text
observation
  → candidate
    → review
      → risk decision
        → paper trade
          → watcher event
            → outcome
```

This is well suited to PostgreSQL.

SQLAlchemy provides a mature Python database access layer.

Alembic provides explicit schema migration history and supports controlled database evolution.

CloudNativePG aligns with the platform model because database infrastructure should be operated as a platform capability, not embedded casually into the Traderoo application manifests.

## Alternatives Considered

### SQLite

SQLite would be simpler for early local development, but it does not represent the intended Kubernetes runtime model.

It was rejected as the runtime persistence target because Traderoo is being designed for multi-environment Kubernetes operation, auditability, and future production-like deployment patterns.

SQLite may still be used in tests if appropriate, but it must not become the runtime persistence architecture.

### Raw PostgreSQL StatefulSet

A manually maintained PostgreSQL StatefulSet would increase operational burden and blur platform/application responsibilities.

It was rejected for the intended Kubernetes database path.

### Cloud-hosted PostgreSQL

A cloud-hosted PostgreSQL service may be suitable in future real deployments, but the current project is a local Kubernetes POC.

This remains a future deployment option, not the current target.

### Time-series database

A specialised time-series database is not required yet.

Market data volume and query patterns should prove the need before adding another data platform component.

## Consequences

Positive consequences:

* clear persistence direction before app code is introduced
* avoids designing around SQLite and later replacing it
* supports audit-heavy workflows
* aligns with Kubernetes/platform ownership
* prepares for multi-environment isolation
* keeps Chunk 1 small and clean

Negative consequences:

* PostgreSQL introduces more operational complexity than SQLite
* CloudNativePG will require a future platform implementation chunk
* secrets management and database credentials must be designed carefully before persistence is enabled

## Follow-up Decisions

Future ADRs or implementation chunks should decide:

* CloudNativePG topology
* database-per-environment strategy
* backup and restore approach
* migration execution pattern
* secret delivery path
* whether migrations run as a Kubernetes Job, init container, CI step, or manual operator action
* database readiness behaviour
* retention model for observations, decisions, paper trades, and outcomes

## Guardrails

The following remain prohibited in the current POC stage:

* real broker credentials
* live trading credentials
* real order execution
* live trading mode
* database secrets committed to Git
* plaintext Kubernetes Secret values committed to Git
* Vault implementation before explicitly planned
* External Secrets Operator implementation before explicitly planned

Traderoo remains paper-only until a later explicit decision changes that.
