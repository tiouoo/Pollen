using System;
using System.IO;
using Avalonia;

namespace Pollen.Desktop;

sealed class Program
{
    // Initialization code. Don't use any Avalonia, third-party APIs or any
    // SynchronizationContext-reliant code before AppMain is called: things aren't initialized
    // yet and stuff might break.
    [STAThread]
    public static int Main(string[] args)
    {
        // Exercise the actual published application; normal startup has no test callbacks.
        var smokeTest = args.Length == 2 && args[0] == "--aot-smoke-test";

        try
        {
#if POLLEN_WINDOWS_NATIVE_BUNDLE
            WindowsNativeBundle.Initialize();
#endif
            if (!smokeTest)
                return BuildAvaloniaApp().StartWithClassicDesktopLifetime(args);

            return BuildAvaloniaApp()
                .AfterSetup(builder => AotSmokeTest.Attach(builder, args[1]))
                .StartWithClassicDesktopLifetime(args);
        }
        catch (Exception exception) when (smokeTest)
        {
            File.WriteAllText(args[1], exception.ToString());
            return 1;
        }
    }

    // Avalonia configuration, don't remove; also used by visual designer.
    public static AppBuilder BuildAvaloniaApp()
        => AppBuilder.Configure<App>()
            .UsePlatformDetect()
            .WithInterFont()
            .LogToTrace();
}
