using LinqToDB.Data;

namespace OrbitHub.Data.Repositories.Common;

/// <summary>
/// Provides a unit-of-work scope for composing multiple stored procedure calls
/// within a single database transaction.
/// </summary>
public interface IUnitOfWork : IAsyncDisposable
{
    /// <summary>
    /// Begins a new database transaction. If a transaction is already active,
    /// this is a no-op (nested transaction support).
    /// </summary>
    Task BeginTransactionAsync(CancellationToken ct = default);

    /// <summary>
    /// Commits the current database transaction.
    /// </summary>
    Task CommitAsync(CancellationToken ct = default);

    /// <summary>
    /// Rolls back the current database transaction.
    /// </summary>
    Task RollbackAsync(CancellationToken ct = default);

    /// <summary>
    /// The underlying DataConnection used by SP repositories within this unit of work.
    /// All repositories should share the same connection to participate in the transaction.
    /// </summary>
    DataConnection DataConnection { get; }
}