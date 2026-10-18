#if POLLEN_WINDOWS_NATIVE_BUNDLE
using System;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;

namespace Pollen.Desktop;

// Native AOT cannot use the SDK's managed single-file bundler. Keep the native DLLs as
// resources and load their verified copies before Avalonia, SkiaSharp or HarfBuzz starts.
internal static class WindowsNativeBundle
{
    private const string ResourcePrefix = "Pollen.Native.";

    public static void Initialize()
    {
        var assembly = typeof(WindowsNativeBundle).Assembly;
        var resources = assembly.GetManifestResourceNames()
            .Where(name => name.StartsWith(ResourcePrefix, StringComparison.Ordinal))
            .Order(StringComparer.Ordinal)
            .ToArray();
        if (resources.Length == 0) throw new InvalidOperationException("The Windows native bundle is empty.");

        var hashes = resources.Select(name =>
        {
            using var resource = OpenResource(assembly, name);
            return SHA256.HashData(resource);
        }).ToArray();
        using var bundleHash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
        for (var index = 0; index < resources.Length; index++)
        {
            bundleHash.AppendData(Encoding.UTF8.GetBytes(resources[index]));
            bundleHash.AppendData(hashes[index]);
        }

        // Share the standard single-file extraction override, including for isolated CI runs.
        var root = Environment.GetEnvironmentVariable("DOTNET_BUNDLE_EXTRACT_BASE_DIR")
                   ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Pollen", "native");
        var directory = Path.GetFullPath(Path.Combine(root, Convert.ToHexString(bundleHash.GetHashAndReset())));
        Directory.CreateDirectory(directory);
        for (var index = 0; index < resources.Length; index++)
        {
            var name = resources[index];
            var path = Path.Combine(directory, name[ResourcePrefix.Length..]);
            if (!MatchesHash(path, hashes[index]))
            {
                var temporary = Path.Combine(directory, $"{Guid.NewGuid():N}.tmp");
                try
                {
                    using (var source = OpenResource(assembly, name))
                    using (var destination = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                        source.CopyTo(destination);
                    try
                    {
                        File.Move(temporary, path, overwrite: true);
                    }
                    catch (Exception exception) when (
                        (exception is IOException or UnauthorizedAccessException) && MatchesHash(path, hashes[index]))
                    {
                        // Another process already installed the same bytes, possibly loading the DLL.
                    }
                }
                finally
                {
                    File.Delete(temporary);
                }
            }
        }

        // Keep the handles for the lifetime of the process. Windows reuses these modules
        // when the libraries request them by name through LoadLibrary or P/Invoke.
        foreach (var name in resources)
            NativeLibrary.Load(Path.Combine(directory, name[ResourcePrefix.Length..]));
    }

    private static Stream OpenResource(Assembly assembly, string name) =>
        new GZipStream(assembly.GetManifestResourceStream(name)
                       ?? throw new InvalidOperationException($"Missing native resource: {name}"), CompressionMode.Decompress);

    private static bool MatchesHash(string path, byte[] expected)
    {
        if (!File.Exists(path)) return false;
        using var file = File.OpenRead(path);
        return SHA256.HashData(file).AsSpan().SequenceEqual(expected);
    }
}
#endif
