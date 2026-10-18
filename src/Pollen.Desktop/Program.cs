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
        if (args.Length != 2 || args[0] != "--aot-smoke-test")
            return BuildAvaloniaApp().StartWithClassicDesktopLifetime(args);

        try
        {
            return BuildAvaloniaApp()
                .AfterSetup(builder => AotSmokeTest.Attach(builder, args[1]))
                .StartWithClassicDesktopLifetime(args);
        }
        catch (Exception exception)
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
