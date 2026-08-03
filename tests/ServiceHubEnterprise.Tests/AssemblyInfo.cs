using Xunit;

// bUnit component tests that render pages with simulated network delays (Task.Delay)
// can race under parallel execution. Run sequentially for deterministic results.
[assembly: CollectionBehavior(DisableTestParallelization = true)]
