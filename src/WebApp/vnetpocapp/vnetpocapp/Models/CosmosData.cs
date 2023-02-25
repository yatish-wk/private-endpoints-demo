using Newtonsoft.Json;

namespace vnetpocapp.Models
{
  public class CosmosData
  {
    [JsonProperty(PropertyName = "id", Required = Required.Always)]
    public string Id { get; set; }

    [JsonProperty(PropertyName = "partitionKey", Required = Required.Always, NullValueHandling = NullValueHandling.Ignore)]
    public string PartitionKey { get; set; } = string.Empty;
    public string Key { get; set; } = string.Empty;

    public string Value { get; set; } = string.Empty;
  }
}
