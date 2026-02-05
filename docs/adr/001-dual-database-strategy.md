# ADR 001: Dual Database Strategy (PostgreSQL + MongoDB)

**Status**: Accepted

**Date**: 2024-01-15

**Decision Makers**: Architecture Team

---

## Context

The SaaS boilerplate needs to handle two distinct types of data:

1. **Structured, relational data** requiring ACID guarantees (users, permissions, transactional records)
2. **Flexible, high-volume data** with varying schemas (logs, events, analytics)

We need to decide on a database strategy that optimally serves both use cases without over-complicating the architecture.

## Decision

We will use a **dual database strategy**:

- **PostgreSQL** (primary) for structured relational data
- **MongoDB** (secondary, optional) for flexible document storage

Both databases will be accessible via the repository pattern, with clear guidelines on when to use each.

## Rationale

### Why PostgreSQL as Primary?

1. **ACID Transactions**: Critical for user data, payments, permissions
2. **Strong Schema**: Ensures data integrity with foreign keys and constraints
3. **Mature Ecosystem**: SQLAlchemy provides excellent ORM support
4. **Complex Queries**: JOINs and aggregations are first-class citizens
5. **Industry Standard**: Most developers are familiar with SQL

### Why MongoDB as Secondary?

1. **Schema Flexibility**: Logs and events have varying structures
2. **High Write Throughput**: Optimized for append-only workloads
3. **Document Storage**: Nested data doesn't require complex joins
4. **TTL Indexes**: Automatic data expiration for temporary data
5. **Horizontal Scaling**: Easier to scale for high-volume logging

### Why Both Instead of One?

**PostgreSQL Alone**:
- [-] Storing flexible schemas requires JSON columns (loses MongoDB's query capabilities)
- [-] High-volume logging can impact transactional performance
- [-] Harder to implement TTL for temporary data

**MongoDB Alone**:
- [-] Weaker ACID guarantees (not suitable for critical transactional data)
- [-] Complex joins are inefficient
- [-] Schema validation is less robust than PostgreSQL constraints

**Dual Database**:
- [X] Right tool for each job
- [X] Performance isolation (logs don't slow down transactions)
- [X] Clear separation of concerns

## Implementation

### Database Assignment Rules

**PostgreSQL (MUST use for)**:
- User authentication and profiles
- Roles and permissions (RBAC)
- Financial transactions
- Relational data with foreign keys
- Data requiring complex joins
- Critical data needing ACID guarantees

**MongoDB (OPTIONAL, use for)**:
- Application logs and audit trails
- Event sourcing
- User activity tracking
- Analytics data
- Temporary/cached data
- Data with varying structure

**Never**:
- [-] Store same logical data in both databases
- [-] Use MongoDB for critical transactional data
- [-] Use PostgreSQL for high-volume append-only logs

### Code Organization

```
backend/app/
├── models/
│ ├── postgres/ # SQLAlchemy models
│ │ ├── user.py
│ │ └── item.py
│ └── mongodb/ # Beanie documents
│ └── event.py
├── repositories/
│ ├── user_repository.py # PostgreSQL repo
│ └── event_repository.py # MongoDB repo
└── db/
 ├── postgres.py # PostgreSQL connection
 ├── mongodb.py # MongoDB connection
 └── unit_of_work.py # Cross-DB transactions (if needed)
```

### Making MongoDB Optional

Projects that don't need MongoDB can:
1. Remove MongoDB Docker service from `docker-compose.yml`
2. Remove MongoDB dependencies from `pyproject.toml`
3. Delete `app/models/mongodb/` directory
4. Remove MongoDB repositories
5. Update `app/main.py` to skip MongoDB initialization

## Consequences

### Positive

- [X] **Performance**: Each database optimized for its workload
- [X] **Scalability**: Can scale PostgreSQL and MongoDB independently
- [X] **Flexibility**: Easy to add new features requiring flexible schemas
- [X] **Reliability**: Logs don't impact critical transactional performance
- [X] **Developer Experience**: Clear guidelines on which database to use

### Negative

- [-] **Complexity**: Two databases to manage, backup, and monitor
- [-] **Operations**: More infrastructure components
- [-] **Learning Curve**: Developers need to understand both SQL and MongoDB
- [-] **Consistency**: Cross-database transactions are complex
- [-] **Cost**: Running two database services (mitigated by making MongoDB optional)

### Mitigations

1. **Clear Documentation**: Provide decision framework for database selection
2. **Repository Pattern**: Abstract database operations behind clean interfaces
3. **Optional MongoDB**: Make MongoDB truly optional for simpler projects
4. **Avoid Cross-DB Transactions**: Design features to minimize cross-database dependencies
5. **Tooling**: Provide scripts for backing up, restoring, and monitoring both databases

## Alternatives Considered

### Alternative 1: PostgreSQL Only

**Pros**:
- Simpler architecture
- One database to manage
- No cross-database consistency issues

**Cons**:
- Must store flexible schemas in JSONB (loses query power)
- High-volume logging impacts transactional workload
- TTL management is manual

**Decision**: Rejected due to performance and scalability concerns for high-volume logging.

### Alternative 2: MongoDB Only

**Pros**:
- Simpler architecture
- Flexible schemas everywhere
- Horizontal scaling

**Cons**:
- Weaker ACID guarantees for critical data
- Complex joins are inefficient
- Less mature permission/role management
- Most developers less familiar with MongoDB

**Decision**: Rejected due to ACID requirements for user/payment data.

### Alternative 3: PostgreSQL + Redis (for caching)

**Pros**:
- PostgreSQL for all persistent data
- Redis for caching and temporary data
- Both are industry standards

**Cons**:
- Redis is not suitable for persistent logs
- No flexible schema storage for varying event structures
- Redis memory-only (need persistence layer)

**Decision**: Not mutually exclusive. Redis can be added later for caching alongside PostgreSQL + MongoDB.

### Alternative 4: NewSQL (CockroachDB, TiDB)

**Pros**:
- ACID guarantees with horizontal scaling
- Single database for everything

**Cons**:
- Less mature ecosystem
- Higher learning curve
- Not suitable for flexible schemas
- Vendor lock-in concerns

**Decision**: Rejected. Too new, less tooling, doesn't solve flexible schema problem.

## Experience Report

### What Worked Well

- **Clear Separation**: Teams understand when to use each database
- **Performance**: Logs don't impact user queries
- **Flexibility**: Easy to add new event types without migrations

### What Didn't Work

- **Initial Confusion**: Developers unsure which database for new features
- **Testing**: Need separate test setups for both databases
- **Backups**: More complex backup strategy

### Lessons Learned

1. **Documentation is Critical**: Decision framework must be prominent in docs
2. **Make MongoDB Truly Optional**: Many projects don't need it initially
3. **Avoid Cross-DB Joins**: Design APIs to minimize cross-database queries
4. **Repository Pattern Works**: Abstracts database details effectively

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Choosing the Right Database](https://martinfowler.com/articles/polyglot-persistence.html)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)

## Revisit

This decision should be revisited if:
- MongoDB usage remains at zero for extended period → Consider removing
- Cross-database queries become common → Rearchitect data model
- NewSQL databases mature significantly → Re-evaluate single-DB approach
- High costs from running two databases → Consolidate if possible

---

**Last Updated**: 2026-02-05
