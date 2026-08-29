using Microsoft.AspNetCore.Components;

namespace OrbitHub.Ui.Components;

/// <summary>
/// Footer for the MonacoDiffEditor showing diff statistics, navigation, and status.
/// </summary>
public partial class MonacoComparerFooter
{
    [Parameter] public int TotalDifferences { get; set; }
    [Parameter] public int Additions { get; set; }
    [Parameter] public int Deletions { get; set; }
    [Parameter] public int Modifications { get; set; }
    [Parameter] public double PercentageChanged { get; set; }
    [Parameter] public double SimilarityPercentage { get; set; }

    [Parameter] public int CurrentDifference { get; set; }
    [Parameter] public int TotalDifferencesForNav { get; set; }

    [Parameter] public string ComparisonStatus { get; set; } = "Comparison ready";
    [Parameter] public bool IsProcessing { get; set; }
    [Parameter] public bool HasError { get; set; }
    [Parameter] public string? ErrorMessage { get; set; }

    [Parameter] public bool ShowDiffStats { get; set; } = true;
    [Parameter] public bool ShowNavigation { get; set; } = true;
    [Parameter] public bool ShowStatus { get; set; } = true;
}