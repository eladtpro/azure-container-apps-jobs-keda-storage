using Azure.Messaging.ServiceBus;

namespace OpenTofu;

internal class Processor : IAsyncDisposable
{
    private readonly ServiceBusClient client;
    private readonly ServiceBusProcessor processor;
 
    public Processor(Func<ProcessMessageEventArgs, Task> MessageHandler)
    {
        ServiceBusClientOptions clientOptions = new ServiceBusClientOptions()
        {
            TransportType = ServiceBusTransportType.AmqpWebSockets
        };
        client = new ServiceBusClient(Configuration.ConnectionString, clientOptions);
        processor = client.CreateProcessor(Configuration.RequestsQueue, new ServiceBusProcessorOptions());
        
        processor.ProcessMessageAsync += MessageHandler;

        processor.ProcessErrorAsync += ErrorHandler;
    }

    public async Task ProcessAsync(CancellationToken cancellationToken = default)
    {
        await processor.StartProcessingAsync(cancellationToken);
        while(processor.IsProcessing)
        {
            await Task.Delay(1000);
        }
    }

    Task ErrorHandler(ProcessErrorEventArgs args)
    {
        Console.WriteLine(args.Exception.ToString());
        throw args.Exception;
    }

    public ValueTask DisposeAsync()
    {
        ValueTask value = default;
        if (processor != null)
            value = processor.DisposeAsync();
        if (client != null)
            value = client.DisposeAsync();

        if (value == default)
            value = new ValueTask(Task.CompletedTask);

        return value;
    }
}