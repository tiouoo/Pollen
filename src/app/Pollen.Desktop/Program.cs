using System;
using Avalonia;

namespace Pollen.Desktop;

sealed class Program
{
    [STAThread]
    public static int Main(string[] args)
    {
#if POLLEN_WINDOWS_NATIVE_BUNDLE
        WindowsNativeBundle.Initialize();
#endif
        return BuildAvaloniaApp().StartWithClassicDesktopLifetime(args);
    }

    public static AppBuilder BuildAvaloniaApp()
        => AppBuilder.Configure<App>()
            .UsePlatformDetect()
            .WithInterFont()
            .LogToTrace();
}
