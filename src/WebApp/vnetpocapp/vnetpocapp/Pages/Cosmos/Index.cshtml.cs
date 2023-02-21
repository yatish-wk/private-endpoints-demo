using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
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
    public string CosmosError { get; set; }
    public string StorageError { get; set; }

    public async Task OnGet()
    {
      try
      {
        using CosmosClient client = new(
               accountEndpoint: _configuration["COSMOS_ENDPOINT"],
               authKeyOrResourceToken: _configuration["COSMOS_KEY"]
            );

        var container = client.GetDatabase(id: "ToDoList").GetContainer("Items");

        Data = await container.ReadItemAsync<CosmosData>(
                    id: "1",
                    partitionKey: new PartitionKey("1")
                );
      }
      catch (CosmosException ce)
      {
        CosmosError = $"{ce.Message}<br>{ce.StackTrace}";
      }


      try
      {
        BlobContainerClient container = new BlobContainerClient(_configuration["STORAGE_ENDPOINT"], "mycontainer");
        var blob = container.GetBlobClient("Mytextfile.txt");

        BlobDownloadResult downloadResult = await blob.DownloadContentAsync();
        BlobData = downloadResult.Content.ToString();

      }
      catch (Exception ce)
      {
        StorageError = $"{ce.Message}<br>{ce.StackTrace}";
      }
    }
  }
}
