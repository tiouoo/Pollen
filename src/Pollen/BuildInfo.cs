using Standard.Build;

namespace Pollen;

/// <summary>Build metadata injected into the Pollen assembly; local builds use development defaults.</summary>
public static class BuildInfo
{
    private static readonly AssemblyBuildValues Values = new(typeof(BuildInfo).Assembly);

    public static string Type => Values.GetValue("Pollen.Type") ?? "development";
    public static string Version => Values.GetValue("Pollen.Version") ?? BaseVersion;
    public static string BaseVersion => Values.GetValue("Pollen.BaseVersion") ?? "1.0.0";
    public static string? BuildTime => Values.GetValue("Pollen.BuildTime");
    public static string? Action => Values.GetValue("Pollen.Action");
    public static string? Commit => Values.GetValue("Pollen.Commit");
    public static string? Timestamp => Values.GetValue("Pollen.Timestamp");
    public static string? VersionTitle => Values.GetValue("Pollen.VersionTitle");
    public static string PackageType => Values.GetValue("Pollen.PackageType") ?? "development";
}
