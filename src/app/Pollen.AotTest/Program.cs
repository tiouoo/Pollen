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
            return AppBuilder.Configure<App>()
                .UsePlatformDetect()
                .WithInterFont()
                .LogToTrace()
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
