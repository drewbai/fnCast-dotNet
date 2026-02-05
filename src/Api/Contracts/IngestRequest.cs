namespace FnCast.Api.Contracts
{
    /// <summary>
    /// Represents the inbound request body for event ingestion.
    /// </summary>
    public sealed class IngestRequest
    {
        /// <summary>
        /// Gets or sets the raw payload string.
        /// </summary>
        public string Payload { get; set; } = string.Empty;

        /// <summary>
        /// Gets or sets the payload content type (defaults to application/json).
        /// </summary>
        public string ContentType { get; set; } = "application/json";
    }
}
