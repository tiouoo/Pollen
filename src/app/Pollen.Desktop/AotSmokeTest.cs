using System;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Threading;
using Avalonia.VisualTree;
using Pollen.Config.Build;
using Pollen.Localization;
using Pollen.Views;

namespace Pollen.Desktop;

// Run inside the published executable, without a separate test framework.
internal sealed class AotSmokeTest(IClassicDesktopStyleApplicationLifetime desktop, string reportPath)
{
    private readonly StringBuilder _log = new();
    private TextBlock? _welcome;
    private int _cultureIndex;

    private static readonly (string Culture, string Expected)[] Cultures =
    [
        ("zh-Hans", "欢迎使用 Pollen"),
        ("en", "Welcome to Pollen"),
        ("en-US", "Welcome to Pollen"),
        ("fr-FR", "欢迎使用 Pollen"),
        ("zh-Hans", "欢迎使用 Pollen")
    ];

    public static void Attach(AppBuilder builder, string reportPath)
    {
        var desktop = builder.Instance?.ApplicationLifetime as IClassicDesktopStyleApplicationLifetime
                      ?? throw new InvalidOperationException("Desktop lifetime was not initialized.");
        var test = new AotSmokeTest(desktop, reportPath);
        test.Post(test.CheckApplication);
    }

    private void CheckApplication()
    {
        Check(!RuntimeFeature.IsDynamicCodeSupported, "Native AOT runtime (no dynamic code)");
#if POLLEN_WINDOWS_AOT
        using (var documentation = typeof(AotSmokeTest).Assembly.GetManifestResourceStream("Pollen.Documentation.OvoUi.Lang.xml"))
            Check(documentation is { Length: > 0 }, "XML documentation embedded in the executable");
#endif
        var window = desktop.MainWindow as MainWindow;
        Check(window is { IsVisible: true, Icon: not null }, "Main window opened with its icon");
        var view = window!.GetVisualDescendants().OfType<MainView>().Single();
        _welcome = view.FindControl<TextBlock>("WelcomeText");
        Check(_welcome is not null && _welcome.Bounds.Width > 0 && _welcome.Bounds.Height > 0,
            "Welcome control loaded and laid out");

        // The workflow supplies these at publish time, not through runtime fallback.
        Check(BuildInfo.Type == "aot-test", "Embedded build type");
        Check(BuildInfo.Version == "9.8.7", "Embedded build version");
        Check(BuildInfo.BaseVersion == "1.0.0", "Embedded base version");
        Check(BuildInfo.Commit == "aot-smoke-commit", "Embedded commit");
        Check(BuildInfo.PackageType == "aot-test", "Embedded package type");
        Check(BuildInfo.BuildTime == "2026-10-18 00:00:00", "Embedded build time");
        Check(BuildInfo.Action == "aot-smoke-action", "Embedded action");
        Check(BuildInfo.Timestamp == "202610180000", "Embedded timestamp");
        Check(BuildInfo.VersionTitle == "aot-smoke-title", "Embedded version title");
        ChangeCulture();
    }

    private void ChangeCulture()
    {
        var (culture, expected) = Cultures[_cultureIndex];
        LocalizationService.SetCulture(CultureInfo.GetCultureInfo(culture));
        // Let the real XAML binding consume the observable before checking displayed text.
        Post(() =>
        {
            Check(_welcome!.Text == expected, $"Welcome binding for {culture}: {_welcome.Text}");
            Check(LocalizationService.CurrentCulture.Name == culture, $"Current culture: {culture}");
            if (++_cultureIndex < Cultures.Length)
            {
                ChangeCulture();
                return;
            }

            _log.AppendLine("AOT_SMOKE_TEST_PASSED");
            File.WriteAllText(reportPath, _log.ToString());
            desktop.Shutdown(0);
        });
    }

    private void Check(bool condition, string description)
    {
        if (!condition) throw new InvalidOperationException($"FAIL: {description}");
        _log.AppendLine($"PASS: {description}");
    }

    private void Post(Action step) => Dispatcher.UIThread.Post(() =>
    {
        try
        {
            step();
        }
        catch (Exception exception)
        {
            _log.AppendLine(exception.ToString());
            File.WriteAllText(reportPath, _log.ToString());
            desktop.Shutdown(1);
        }
    }, DispatcherPriority.ApplicationIdle);
}
