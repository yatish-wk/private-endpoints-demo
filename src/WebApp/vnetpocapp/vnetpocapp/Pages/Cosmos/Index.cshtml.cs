using Azure;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Azure.Amqp.Framing;
using Microsoft.Azure.Cosmos;
using System.Linq.Expressions;
using vnetpocapp.Models;

namespace vnetpocapp.Pages.Cosmos
{
  public class IndexModel : PageModel
  {
    private readonly IConfiguration _configuration;
    public IndexModel(IConfiguration configuration)
    {
      _configuration = configuration;
    }

    public CosmosData Data { get; set; } = default!;

    public string BlobData { get; set; }

    public string SendMessage { get; set; }

    public string CosmosError { get; set; }
    public string StorageError { get; set; }
    public string BusError { get; set; }

    public async Task OnGet()
    {
      await GetCosmosData();
      await GetStorageData();
      await SendReceiveServiceBus();
    }

    private async Task GetCosmosData()
    {
      try
      {
        using CosmosClient client = new(
               accountEndpoint: _configuration["COSMOS_ENDPOINT"],
               authKeyOrResourceToken: _configuration["COSMOS_KEY"]
            );

        var container = client.GetDatabase(id: "ToDoList").GetContainer("Items");
        try
        {
          Data = await container.ReadItemAsync<CosmosData>(
                      id: "1",
                      partitionKey: new PartitionKey("1")
                  );
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
          await container.CreateItemAsync(new CosmosData
          {
            Id = "1",
            PartitionKey = "1",
            Key = "SampleKey",
            Value = "SampleValue"
          });
          await GetCosmosData();
        }
      }
      catch (CosmosException ce)
      {

        CosmosError = $"{ce.Message}<br>{ce.StackTrace}";
      }
    }

    private async Task GetStorageData()
    {
      try
      {
        BlobServiceClient blobStore = new(_configuration["STORAGE_ENDPOINT"]);
        var container = blobStore.GetBlobContainerClient("mycontainer");
        await container.CreateIfNotExistsAsync();

        BlobClient blob;
        try
        {

          blob = container.GetBlobClient("Mytextfile.txt");

          BlobDownloadResult downloadResult = await blob.DownloadContentAsync();
          BlobData = downloadResult.Content.ToString();
        }
        catch (RequestFailedException rfe) when (rfe.ErrorCode == "BlobNotFound")
        {
          await container.UploadBlobAsync("Mytextfile.txt", BinaryData.FromString("sample blob data"));
          await GetStorageData();
        }

      }
      catch (Exception ce)
      {
        StorageError = $"{ce.Message}<br>{ce.StackTrace}";
      }
    }


    private async Task SendReceiveServiceBus()
    {
      try
      {
        // the client that owns the connection and can be used to create senders and receivers
        ServiceBusClient client;

        // the sender used to publish messages to the queue
        ServiceBusSender sender;

        // number of messages to be sent to the queue
        const int numOfMessages = 3;

        // The Service Bus client types are safe to cache and use as a singleton for the lifetime
        // of the application, which is best practice when messages are being published or read
        // regularly.
        //
        // set the transport type to AmqpWebSockets so that the ServiceBusClient uses the port 443. 
        // If you use the default AmqpTcp, you will need to make sure that the ports 5671 and 5672 are open

        // TODO: Replace the <NAMESPACE-CONNECTION-STRING> and <QUEUE-NAME> placeholders
        var clientOptions = new ServiceBusClientOptions()
        {
          TransportType = ServiceBusTransportType.AmqpWebSockets
        };
        client = new ServiceBusClient(_configuration.GetConnectionString("PoCBus"), clientOptions);
        sender = client.CreateSender("testqueue");

        // create a batch 
        using ServiceBusMessageBatch messageBatch = await sender.CreateMessageBatchAsync();

        for (int i = 1; i <= numOfMessages; i++)
        {
          // try adding a message to the batch
          if (!messageBatch.TryAddMessage(new ServiceBusMessage($"Message {i}")))
          {
            // if it is too large for the batch
            throw new Exception($"The message {i} is too large to fit in the batch.");
          }
        }

        try
        {
          // Use the producer client to send the batch of messages to the Service Bus queue
          await sender.SendMessagesAsync(messageBatch);
          SendMessage = $"A batch of {numOfMessages} messages has been published to the queue.";
        }
        finally
        {
          // Calling DisposeAsync on client types is required to ensure that network
          // resources and other unmanaged objects are properly cleaned up.
          await sender.DisposeAsync();
          await client.DisposeAsync();
        }
      }
      catch (global::System.Exception ce)
      {

        BusError = $"{ce.Message}<br>{ce.StackTrace}";
      }
    }

  }
}
