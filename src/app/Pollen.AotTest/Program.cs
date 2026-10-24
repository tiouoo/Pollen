using System;
using System.IO;
using Avalonia;

namespace Pollen.AotTest;

internal static class Program
{
    [STAThread]
    public static int Main(string[] args)
    {
        if (args.Length != 1)
        {
            Console.Error.WriteLine("Usage: Pollen.AotTest <report-path>");
            return 2;
        }

        try
        {
#if POLLEN_WINDOWS_NATIVE_BUNDLE
            WindowsNativeBundle.Initialize();
#endif
            return Pollen.Desktop.Program.BuildAvaloniaApp()
                .AfterSetup(builder => AotSmokeTest.Attach(builder, args[0]))
                .StartWithClassicDesktopLifetime([]);
        }
        catch (Exception exception)
        {
            File.WriteAllText(args[0], exception.ToString());
            return 1;
        }
    }
}
