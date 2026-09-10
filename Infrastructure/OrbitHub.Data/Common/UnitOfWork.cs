using LinqToDB.Data;
using Microsoft.Extensions.Logging;

namespace OrbitHub.Data.Common;

/// <summary>
/// Default implementation of <see cref="IUnitOfWork"/> that wraps a linq2db <see cref="DataConnection"/>
/// and manages transaction lifecycle.
/// </summary>
public class UnitOfWork : IUnitOfWork
{
    private readonly DataConnection _dataConnection;
    private readonly ILogger<UnitOfWork>? _logger;
    private bool _disposed;

    /// <summary>
    /// Initializes a new unit of work with the given DataConnection.
    /// The connection is expected to be already open or opened on first query.
    /// </summary>
    public UnitOfWork(DataConnection dataConnection, ILogger<UnitOfWork>? logger = null)
    {
        _dataConnection = dataConnection ?? throw new ArgumentNullException(nameof(dataConnection));
        _logger = logger;
    }

    /// <inheritdoc/>
    public DataConnection DataConnection => _dataConnection;

    /// <inheritdoc/>
    public async Task BeginTransactionAsync(CancellationToken ct = default)
    {
        if (_dataConnection.Transaction is not null)
        {
            _logger?.LogDebug("Transaction already active on this connection — skipping BeginTransaction.");
            return;
        }

        _logger?.LogDebug("Beginning database transaction.");
        await _dataConnection.BeginTransactionAsync(ct);
    }

    /// <inheritdoc/>
    public async Task CommitAsync(CancellationToken ct = default)
    {
        if (_dataConnection.Transaction is null)
        {
            _logger?.LogWarning("CommitAsync called but no transaction is active.");
            return;
        }

        _logger?.LogDebug("Committing database transaction.");
        await _dataConnection.CommitTransactionAsync(ct);
    }

    /// <inheritdoc/>
    public async Task RollbackAsync(CancellationToken ct = default)
    {
        if (_dataConnection.Transaction is null)
        {
            _logger?.LogWarning("RollbackAsync called but no transaction is active.");
            return;
        }

        _logger?.LogDebug("Rolling back database transaction.");
        await _dataConnection.RollbackTransactionAsync(ct);
    }

    /// <inheritdoc/>
    public async ValueTask DisposeAsync()
    {
        if (_disposed)
            return;

        _disposed = true;

        // Rollback any uncommitted transaction on dispose
        if (_dataConnection.Transaction is not null)
        {
            _logger?.LogWarning("Disposing UnitOfWork with uncommitted transaction — rolling back.");
            try
            {
                await _dataConnection.RollbackTransactionAsync(CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error rolling back transaction during UnitOfWork disposal.");
            }
        }

        await _dataConnection.DisposeAsync();
    }
}