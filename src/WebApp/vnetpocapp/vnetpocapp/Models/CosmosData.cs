namespace vnetpocapp.Models
{
  public class CosmosData
  {
    public string PartitionKey { get; set; } = string.Empty;
    public string Key { get; set; } = string.Empty;

    public string Value { get; set; } = string.Empty;
  }
}
