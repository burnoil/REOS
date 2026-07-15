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

    public static async Task Main(string[] args)
    {
        if (args.Length == 2 && args[0].Equals("--restore", StringComparison.OrdinalIgnoreCase) &&
            long.TryParse(args[1], out long restoreHandle))
        {
            NativeMethods.RestoreWindow((nint)restoreHandle);
            return;
        }

        string stateDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "REOS");
        Directory.CreateDirectory(stateDirectory);

        string statePath = Path.Combine(stateDirectory, "state.json");
        string stowagePath = Path.Combine(stateDirectory, "stowage.txt");

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
                await WriteStowageFeedAsync(stowagePath, state).ConfigureAwait(false);
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

    private static async Task WriteStowageFeedAsync(string path, ReosState state)
    {
        // Legacy flat feed retained until the Rainmeter grouped-view implementation is ready.
        string text = state.MinimizedApplications.Count == 0
            ? "NO APPLICATIONS STOWED"
            : string.Join("  //  ", state.MinimizedApplications.Take(12).Select((application, index) =>
                $"{index + 1:00} {application.ReosLabel} | {Condense(application.Title, 38)} | H:{application.Handle}"));

        string temporaryPath = path + ".tmp";
        await File.WriteAllTextAsync(temporaryPath, text, new UTF8Encoding(false)).ConfigureAwait(false);
        File.Move(temporaryPath, path, true);
    }

    private static string Condense(string value, int maximum) =>
        value.Length <= maximum ? value : value[..(maximum - 1)] + "…";
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

        NativeMethods.EnumWindows((handle, lParam) =>
        {
            try
            {
                if (!NativeMethods.IsWindowVisible(handle)) return true;

                nint rootOwner = NativeMethods.GetAncestor(handle, GaRootOwner);
                if (rootOwner == nint.Zero) rootOwner = handle;

                long rootValue = rootOwner.ToInt64();
                if (!seenRootOwners.Add(rootValue)) return true;

                long extendedStyle = NativeMethods.GetWindowLongPtr(rootOwner, GwlExStyle).ToInt64();
                if ((extendedStyle & WsExToolWindow) != 0) return true;

                int cloaked = 0;
                _ = NativeMethods.DwmGetWindowAttribute(rootOwner, DwmwaCloaked, out cloaked, Marshal.SizeOf<int>());
                if (cloaked != 0) return true;

                string title = NativeMethods.ReadWindowTitle(rootOwner);
                if (string.IsNullOrWhiteSpace(title) || IsExcludedTitle(title)) return true;

                _ = NativeMethods.GetWindowThreadProcessId(rootOwner, out uint processId);
                Process? process = null;
                try { process = Process.GetProcessById((int)processId); } catch { }

                string processName = process?.ProcessName ?? "unknown";
                bool minimized = NativeMethods.IsIconic(rootOwner);
                bool active = rootOwner == foregroundHandle || handle == foregroundHandle;

                applications.Add(new ApplicationWindow(
                    rootValue,
                    processName,
                    title,
                    ApplicationClassifier.Classify(processName),
                    minimized,
                    active));
            }
            catch { }

            return true;
        }, nint.Zero);

        List<ApplicationWindow> ordered = applications
            .OrderByDescending(application => application.IsActive)
            .ThenByDescending(application => application.IsMinimized)
            .ThenBy(application => application.ReosLabel, StringComparer.OrdinalIgnoreCase)
            .ThenBy(application => application.Title, StringComparer.OrdinalIgnoreCase)
            .ToList();

        List<ApplicationWindow> minimized = ordered
            .Where(application => application.IsMinimized)
            .Take(24)
            .ToList();

        List<StowageGroup> groups = minimized
            .GroupBy(application => ApplicationClassifier.GetGroupKey(application.Process), StringComparer.OrdinalIgnoreCase)
            .Select(group =>
            {
                List<ApplicationWindow> windows = group
                    .OrderByDescending(application => application.IsActive)
                    .ThenBy(application => application.Title, StringComparer.OrdinalIgnoreCase)
                    .ToList();

                ApplicationWindow mostRecent = windows[0];
                string processName = mostRecent.Process;

                return new StowageGroup(
                    ApplicationClassifier.GetGroupKey(processName),
                    processName,
                    ApplicationClassifier.GetApplicationName(processName),
                    mostRecent.ReosLabel,
                    windows.Count,
                    mostRecent.Title,
                    mostRecent.Handle,
                    windows);
            })
            .OrderBy(group => group.ReosLabel, StringComparer.OrdinalIgnoreCase)
            .ThenBy(group => group.ApplicationName, StringComparer.OrdinalIgnoreCase)
            .ToList();

        return new ReosState(
            2,
            DateTimeOffset.UtcNow,
            ordered.FirstOrDefault(application => application.IsActive),
            minimized,
            groups,
            ordered);
    }

    private static bool IsExcludedTitle(string title) => title is
        "Program Manager" or "Rainmeter" or "Windows Input Experience" or "Desktop - File Explorer";
}

internal static class ApplicationClassifier
{
    private static readonly Dictionary<string, string> Labels = new(StringComparer.OrdinalIgnoreCase)
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
        ["WINWORD"] = "DOCUMENT EDITOR",
        ["devenv"] = "SOURCE DEVELOPMENT",
        ["Code"] = "SOURCE DEVELOPMENT",
        ["explorer"] = "FILE SERVICES",
        ["AcroRd32"] = "ENGINEERING DOCUMENTS",
        ["SumatraPDF"] = "ENGINEERING DOCUMENTS",
        ["SnippingTool"] = "CAPTURE SERVICES"
    };

    private static readonly Dictionary<string, string> ApplicationNames = new(StringComparer.OrdinalIgnoreCase)
    {
        ["msedge"] = "Microsoft Edge",
        ["chrome"] = "Google Chrome",
        ["firefox"] = "Mozilla Firefox",
        ["pwsh"] = "PowerShell 7",
        ["powershell"] = "Windows PowerShell",
        ["WindowsTerminal"] = "Windows Terminal",
        ["cmd"] = "Command Prompt",
        ["notepad++"] = "Notepad++",
        ["notepad"] = "Notepad",
        ["WINWORD"] = "Microsoft Word",
        ["devenv"] = "Visual Studio",
        ["Code"] = "Visual Studio Code",
        ["explorer"] = "File Explorer",
        ["AcroRd32"] = "Adobe Acrobat Reader",
        ["SumatraPDF"] = "SumatraPDF",
        ["SnippingTool"] = "Snipping Tool"
    };

    public static string Classify(string processName) =>
        Labels.TryGetValue(processName, out string? label) ? label : "APPLICATION SERVICE";

    public static string GetApplicationName(string processName) =>
        ApplicationNames.TryGetValue(processName, out string? name) ? name : processName;

    public static string GetGroupKey(string processName) => processName.ToUpperInvariant();
}

internal sealed record ReosState(
    int SchemaVersion,
    DateTimeOffset GeneratedUtc,
    ApplicationWindow? ActiveApplication,
    IReadOnlyList<ApplicationWindow> MinimizedApplications,
    IReadOnlyList<StowageGroup> StowageGroups,
    IReadOnlyList<ApplicationWindow> Applications);

internal sealed record StowageGroup(
    string GroupKey,
    string Process,
    string ApplicationName,
    string ReosLabel,
    int Count,
    string MostRecentTitle,
    long MostRecentHandle,
    IReadOnlyList<ApplicationWindow> Windows);

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

    [DllImport("user32.dll")] internal static extern bool EnumWindows(EnumWindowsProc callback, nint lParam);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool IsWindowVisible(nint hWnd);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool IsIconic(nint hWnd);
    [DllImport("user32.dll")] internal static extern nint GetForegroundWindow();
    [DllImport("user32.dll")] internal static extern nint GetAncestor(nint hWnd, uint flags);
    [DllImport("user32.dll")] internal static extern uint GetWindowThreadProcessId(nint hWnd, out uint processId);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern int GetWindowText(nint hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")] private static extern int GetWindowTextLength(nint hWnd);
    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtr")] private static extern nint GetWindowLongPtr64(nint hWnd, int index);
    [DllImport("user32.dll", EntryPoint = "GetWindowLong")] private static extern nint GetWindowLongPtr32(nint hWnd, int index);
    [DllImport("dwmapi.dll")] internal static extern int DwmGetWindowAttribute(nint hWnd, int attribute, out int value, int size);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool ShowWindowAsync(nint hWnd, int command);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool SetForegroundWindow(nint hWnd);

    internal static nint GetWindowLongPtr(nint hWnd, int index) =>
        nint.Size == 8 ? GetWindowLongPtr64(hWnd, index) : GetWindowLongPtr32(hWnd, index);

    internal static string ReadWindowTitle(nint hWnd)
    {
        int length = GetWindowTextLength(hWnd);
        if (length <= 0) return string.Empty;
        StringBuilder builder = new(length + 1);
        _ = GetWindowText(hWnd, builder, builder.Capacity);
        return builder.ToString().Trim();
    }

    internal static void RestoreWindow(nint hWnd)
    {
        if (hWnd == nint.Zero) return;
        _ = ShowWindowAsync(hWnd, 9);
        Thread.Sleep(100);
        _ = SetForegroundWindow(hWnd);
    }
}
