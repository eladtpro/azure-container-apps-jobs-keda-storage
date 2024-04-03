﻿using Azure.Messaging.ServiceBus;
using System;
using System.Diagnostics;
using System.Threading.Tasks;

// the client that owns the connection and can be used to create senders and receivers
ServiceBusClient client;

// the processor that reads and processes messages from the queue
ServiceBusProcessor processor;

string connectionString = Environment.GetEnvironmentVariable("AZURE_SERVICE_BUS_CONNECTION_STRING");
string queueName = Environment.GetEnvironmentVariable("SERVICE_BUS_QUEUE_NAME");


// The Service Bus client types are safe to cache and use as a singleton for the lifetime
// of the application, which is best practice when messages are being published or read
// regularly.
//
// Set the transport type to AmqpWebSockets so that the ServiceBusClient uses port 443. 
// If you use the default AmqpTcp, make sure that ports 5671 and 5672 are open.

// TODO: Replace the <NAMESPACE-CONNECTION-STRING> and <QUEUE-NAME> placeholders
var clientOptions = new ServiceBusClientOptions()
{
    TransportType = ServiceBusTransportType.AmqpWebSockets
};
client = new ServiceBusClient(connectionString, clientOptions);

// create a processor that we can use to process the messages
// TODO: Replace the <QUEUE-NAME> placeholder
processor = client.CreateProcessor(queueName, new ServiceBusProcessorOptions());

try
{
    // add handler to process messages
    processor.ProcessMessageAsync += MessageHandler;

    // add handler to process any errors
    processor.ProcessErrorAsync += ErrorHandler;

    // start processing 
    await processor.StartProcessingAsync();

    Console.WriteLine("Wait for a minute and then press any key to end the processing");
    Console.ReadKey();

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
    // subprocess.run(['chmod', 'u+x', 'runner.sh'])
    // subprocess.run(['./runner.sh', cwd_dir, destination_blob.blob_name, template_dir])


    string body = args.Message.Body.ToString();
    Console.WriteLine($"Received: {body}");
    ProcessStartInfo startInfo = new ProcessStartInfo();
    startInfo.FileName = "/bin/bash";
    startInfo.Arguments = $"./runner.sh cwd_dir destination_blob.blob_name ${template_dir}",
    RedirectStandardOutput = true

    // complete the message. message is deleted from the queue. 
    await args.CompleteMessageAsync(args.Message);
}

// handle any errors when receiving messages
Task ErrorHandler(ProcessErrorEventArgs args)
{
    Console.WriteLine(args.Exception.ToString());
    return Task.CompletedTask;
}