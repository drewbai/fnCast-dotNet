using System.Collections.Generic;

namespace FnCast.Api.Contracts
{
    /// <summary>
    /// Represents the minimal response returned by the ingestion endpoint.
    /// </summary>
    public sealed class IngestResponse
    {
        /// <summary>
        /// Indicates whether processing succeeded.
        /// </summary>
        public bool Success { get; set; }

        /// <summary>
        /// Gets or sets the primary output produced.
        /// </summary>
        public string Output { get; set; } = string.Empty;

        /// <summary>
        /// Gets or sets any metadata returned by the pipeline.
        /// </summary>
        public IReadOnlyDictionary<string, string> Metadata { get; set; } = new Dictionary<string, string>();

        /// <summary>
        /// Gets or sets any error messages.
        /// </summary>
        public IReadOnlyList<string> Errors { get; set; } = new List<string>();
    }
}
