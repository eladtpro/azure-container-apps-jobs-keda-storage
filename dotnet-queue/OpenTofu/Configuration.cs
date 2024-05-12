namespace OpenTofu;

internal static class Configuration
{
    public static string ConnectionString { get; set; } = Environment.GetEnvironmentVariable("AZURE_SERVICE_BUS_CONNECTION_STRING");
    public static string RequestsQueue { get; set; } = Environment.GetEnvironmentVariable("SERVICE_BUS_REQUESTS_QUEUE_NAME");
    public static string MountPath { get; set; } = Environment.GetEnvironmentVariable("MOUNT_PATH");
    public static int WaitMS { get; set; } = int.Parse(Environment.GetEnvironmentVariable("PROCESS_WAIT_MS"));
}