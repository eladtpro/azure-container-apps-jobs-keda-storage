using OpenTofu;
using System.Diagnostics;
using Azure.Messaging.ServiceBus;

Processor processor = new Processor(MessageHandler);
await processor.ProcessAsync();
await processor.DisposeAsync();

static async Task MessageHandler(ProcessMessageEventArgs args)
{
    string fileName = "terraform.tfvars";//args.Message.MessageId;
    Console.WriteLine($"Received: {args.Message.Body}");

    string dateDir = DateTime.Now.ToString("yyyyMMdd");
    string timeDir = DateTime.Now.ToString("HHmmss");
    string cwdDir = Path.Combine(Configuration.MountPath, "runs", dateDir, timeDir);
    string templateDir = Path.Combine(Configuration.MountPath, "templates");
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
