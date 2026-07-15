using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace REOS.Core;

internal static class Program
{
    private static readonly TimeSpan PollInterval = TimeSpan.FromSeconds(1);
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    public static async Task Main()
    {
        string stateDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "REOS");
        Directory.CreateDirectory(stateDirectory);

        string statePath = Path.Combine(stateDirectory, "state.json");
        using Mutex singleInstance = new(true, "Local\\REOS.Core", out bool createdNew);
        if (!createdNew)
        {
            return;
        }

        while (true)
        {
            try
            {
                ReosState state = WindowInventory.Capture();
                await WriteAtomicallyAsync(statePath, state).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                string errorPath = Path.Combine(stateDirectory, "core-error.log");
                await File.AppendAllTextAsync(
                    errorPath,
                    $"{DateTimeOffset.Now:O} {ex}\r\n").ConfigureAwait(false);
            }

            await Task.Delay(PollInterval).ConfigureAwait(false);
        }
    }

    private static async Task WriteAtomicallyAsync(string path, ReosState state)
    {
        string temporaryPath = path + ".tmp";
        string json = JsonSerializer.Serialize(state, JsonOptions);
        await File.WriteAllTextAsync(temporaryPath, json, new UTF8Encoding(false)).ConfigureAwait(false);
        File.Move(temporaryPath, path, true);
    }
}

internal static class WindowInventory
{
    private const int GwlExStyle = -20;
    private const long WsExToolWindow = 0x00000080L;
    private const int DwmwaCloaked = 14;
    private const uint GaRootOwner = 3;

    public static ReosState Capture()
    {
        nint foregroundHandle = NativeMethods.GetForegroundWindow();
        List<ApplicationWindow> applications = [];
        HashSet<long> seenRootOwners = [];

        NativeMethods.EnumWindows((handle, _) =>
        {
            try
            {
                if (!NativeMethods.IsWindowVisible(handle))
                {
                    return true;
                }

                nint rootOwner = NativeMethods.GetAncestor(handle, GaRootOwner);
                if (rootOwner == nint.Zero)
                {
                    rootOwner = handle;
                }

                long rootValue = rootOwner.ToInt64();
                if (!seenRootOwners.Add(rootValue))
                {
                    return true;
                }

                long extendedStyle = NativeMethods.GetWindowLongPtr(rootOwner, GwlExStyle).ToInt64();
                if ((extendedStyle & WsExToolWindow) != 0)
                {
                    return true;
                }

                int cloaked = 0;
                _ = NativeMethods.DwmGetWindowAttribute(
                    rootOwner,
                    DwmwaCloaked,
                    out cloaked,
                    Marshal.SizeOf<int>());
                if (cloaked != 0)
                {
                    return true;
                }

                string title = NativeMethods.ReadWindowTitle(rootOwner);
                if (string.IsNullOrWhiteSpace(title) || IsExcludedTitle(title))
                {
                    return true;
                }

                _ = NativeMethods.GetWindowThreadProcessId(rootOwner, out uint processId);
                Process? process = null;
                try
                {
                    process = Process.GetProcessById((int)processId);
                }
                catch
                {
                    // A window may close between enumeration and process lookup.
                }

                string processName = process?.ProcessName ?? "unknown";
                bool minimized = NativeMethods.IsIconic(rootOwner);
                bool active = rootOwner == foregroundHandle || handle == foregroundHandle;

                applications.Add(new ApplicationWindow(
                    Handle: rootValue,
                    Process: processName,
                    Title: title,
                    ReosLabel: ApplicationClassifier.Classify(processName),
                    IsMinimized: minimized,
                    IsActive: active));
            }
            catch
            {
                // One malformed or inaccessible window must not stop the inventory.
            }

            return true;
        }, nint.Zero);

        List<ApplicationWindow> ordered = applications
            .OrderByDescending(application => application.IsActive)
            .ThenByDescending(application => application.IsMinimized)
            .ThenBy(application => application.ReosLabel, StringComparer.OrdinalIgnoreCase)
            .ToList();

        return new ReosState(
            SchemaVersion: 1,
            GeneratedUtc: DateTimeOffset.UtcNow,
            ActiveApplication: ordered.FirstOrDefault(application => application.IsActive),
            MinimizedApplications: ordered.Where(application => application.IsMinimized).Take(12).ToList(),
            Applications: ordered);
    }

    private static bool IsExcludedTitle(string title) => title is
        "Program Manager" or
        "Rainmeter" or
        "Windows Input Experience";
}

internal static class ApplicationClassifier
{
    private static readonly Dictionary<string, string> Labels =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["msedge"] = "RESEARCH TERMINAL",
            ["chrome"] = "RESEARCH TERMINAL",
            ["firefox"] = "RESEARCH TERMINAL",
            ["pwsh"] = "COMMAND TERMINAL",
            ["powershell"] = "COMMAND TERMINAL",
            ["WindowsTerminal"] = "COMMAND TERMINAL",
            ["cmd"] = "COMMAND TERMINAL",
            ["notepad++"] = "DOCUMENT EDITOR",
            ["notepad"] = "DOCUMENT EDITOR",
            ["devenv"] = "SOURCE DEVELOPMENT",
            ["Code"] = "SOURCE DEVELOPMENT",
            ["explorer"] = "FILE SERVICES",
            ["AcroRd32"] = "ENGINEERING DOCUMENTS",
            ["SumatraPDF"] = "ENGINEERING DOCUMENTS"
        };

    public static string Classify(string processName) =>
        Labels.TryGetValue(processName, out string? label)
            ? label
            : "APPLICATION SERVICE";
}

internal sealed record ReosState(
    int SchemaVersion,
    DateTimeOffset GeneratedUtc,
    ApplicationWindow? ActiveApplication,
    IReadOnlyList<ApplicationWindow> MinimizedApplications,
    IReadOnlyList<ApplicationWindow> Applications);

internal sealed record ApplicationWindow(
    long Handle,
    string Process,
    string Title,
    string ReosLabel,
    bool IsMinimized,
    bool IsActive);

internal static class NativeMethods
{
    internal delegate bool EnumWindowsProc(nint hWnd, nint lParam);

    [DllImport("user32.dll")]
    internal static extern bool EnumWindows(EnumWindowsProc callback, nint lParam);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool IsWindowVisible(nint hWnd);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool IsIconic(nint hWnd);

    [DllImport("user32.dll")]
    internal static extern nint GetForegroundWindow();

    [DllImport("user32.dll")]
    internal static extern nint GetAncestor(nint hWnd, uint flags);

    [DllImport("user32.dll")]
    internal static extern uint GetWindowThreadProcessId(nint hWnd, out uint processId);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowText(nint hWnd, StringBuilder text, int count);

    [DllImport("user32.dll")]
    private static extern int GetWindowTextLength(nint hWnd);

    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtr")]
    private static extern nint GetWindowLongPtr64(nint hWnd, int index);

    [DllImport("user32.dll", EntryPoint = "GetWindowLong")]
    private static extern nint GetWindowLongPtr32(nint hWnd, int index);

    [DllImport("dwmapi.dll")]
    internal static extern int DwmGetWindowAttribute(
        nint hWnd,
        int attribute,
        out int value,
        int size);

    internal static nint GetWindowLongPtr(nint hWnd, int index) =>
        nint.Size == 8
            ? GetWindowLongPtr64(hWnd, index)
            : GetWindowLongPtr32(hWnd, index);

    internal static string ReadWindowTitle(nint hWnd)
    {
        int length = GetWindowTextLength(hWnd);
        if (length <= 0)
        {
            return string.Empty;
        }

        StringBuilder builder = new(length + 1);
        _ = GetWindowText(hWnd, builder, builder.Capacity);
        return builder.ToString().Trim();
    }
}
