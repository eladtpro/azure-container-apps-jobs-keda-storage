using Azure.Messaging.ServiceBus;
using System.Diagnostics;

// the client that owns the connection and can be used to create senders and receivers
ServiceBusClient client;

// the processor that reads and processes messages from the queue
ServiceBusProcessor processor;

string AZURE_SERVICE_BUS_CONNECTION_STRING = Environment.GetEnvironmentVariable("AZURE_SERVICE_BUS_CONNECTION_STRING");
string SERVICE_BUS_REQUESTS_QUEUE_NAME = Environment.GetEnvironmentVariable("SERVICE_BUS_REQUESTS_QUEUE_NAME");
string MOUNT_PATH = Environment.GetEnvironmentVariable("MOUNT_PATH");
int PROCESS_WAIT_MS = int.Parse(Environment.GetEnvironmentVariable("PROCESS_WAIT_MS"));


// The Service Bus client types are safe to cache and use as a singleton for the lifetime
// of the application, which is best practice when messages are being published or read
// regularly.
//
// Set the transport type to AmqpWebSockets so that the ServiceBusClient uses port 443. 
// If you use the default AmqpTcp, make sure that ports 5671 and 5672 are open.
var clientOptions = new ServiceBusClientOptions()
{
    TransportType = ServiceBusTransportType.AmqpWebSockets
};
client = new ServiceBusClient(AZURE_SERVICE_BUS_CONNECTION_STRING, clientOptions);

// create a processor that we can use to process the messages
// TODO: Replace the <QUEUE-NAME> placeholder
processor = client.CreateProcessor(SERVICE_BUS_REQUESTS_QUEUE_NAME, new ServiceBusProcessorOptions());

try
{
    // add handler to process messages
    processor.ProcessMessageAsync += MessageHandler;

    // add handler to process any errors
    processor.ProcessErrorAsync += ErrorHandler;

    // start processing 
    await processor.StartProcessingAsync();

    Console.WriteLine($"Waiting for {PROCESS_WAIT_MS/1000} secondes for item in queue for processing");
    Thread.Sleep(PROCESS_WAIT_MS);
    // Console.ReadKey();

    // stop processing 
    Console.WriteLine("\nStopping the receiver...");
    await processor.StopProcessingAsync();
    Console.WriteLine("Stopped receiving messages");
}
finally
{
    // Calling DisposeAsync on client types is required to ensure that network
    // resources and other unmanaged objects are properly cleaned up.
    await processor.DisposeAsync();
    await client.DisposeAsync();
}

// handle received messages
async Task MessageHandler(ProcessMessageEventArgs args)
{
    string body = args.Message.Body.ToString();
    string fileName = "terraform.tfvars";//args.Message.MessageId;
    Console.WriteLine($"Received: {args.Message.Body}");

    string dateDir = DateTime.Now.ToString("yyyyMMdd");
    string timeDir = DateTime.Now.ToString("HHmmss");
    string cwdDir = Path.Combine(MOUNT_PATH, "runs", dateDir, timeDir);
    string templateDir = Path.Combine(MOUNT_PATH, "templates");
    Directory.CreateDirectory(cwdDir);

    using (FileStream downloadFile = File.Create(Path.Combine(cwdDir, fileName)))
    {
        byte[] data = args.Message.Body.ToArray();
        downloadFile.Write(data, 0, data.Length);
    }
    Console.WriteLine($"Blob {fileName} downloaded to {cwdDir}");

    Process.Start("chmod", "u+x runner.sh");
    Process.Start("./runner.sh", $"{cwdDir} {fileName} {templateDir}");

    Console.WriteLine($"Blob {fileName} processed");

    // ProcessStartInfo startInfo = new ProcessStartInfo();
    // startInfo.FileName = "/bin/bash";
    // startInfo.Arguments = $"./runner.sh cwd_dir destination_blob.blob_name ${template_dir}",
    // RedirectStandardOutput = true

    // complete the message. message is deleted from the queue. 
    await args.CompleteMessageAsync(args.Message);
}

// handle any errors when receiving messages
Task ErrorHandler(ProcessErrorEventArgs args)
{
    Console.WriteLine(args.Exception.ToString());
    return Task.CompletedTask;
}