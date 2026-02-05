using System.Collections.Generic;

namespace FnCast.Domain.Models
{
    /// <summary>
    /// Represents the result of executing inference on an event.
    /// </summary>
    public sealed class InferenceResult
    {
        /// <summary>
        /// Indicates whether inference succeeded.
        /// </summary>
        public bool Success { get; }

        /// <summary>
        /// Gets the primary output produced by inference (placeholder string for now).
        /// </summary>
        public string Output { get; }

        /// <summary>
        /// Gets any metadata produced or propagated by the pipeline.
        /// </summary>
        public IReadOnlyDictionary<string, string> Metadata { get; }

        /// <summary>
        /// Gets any error messages collected during processing.
        /// </summary>
        public IReadOnlyList<string> Errors { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="InferenceResult"/> class.
        /// </summary>
        /// <param name="success">Whether inference succeeded.</param>
        /// <param name="output">Primary output.</param>
        /// <param name="metadata">Optional metadata.</param>
        /// <param name="errors">Optional errors.</param>
        public InferenceResult(
            bool success,
            string output,
            IReadOnlyDictionary<string, string>? metadata = null,
            IReadOnlyList<string>? errors = null)
        {
            Success = success;
            Output = output;
            Metadata = metadata ?? new Dictionary<string, string>();
            Errors = errors ?? new List<string>();
        }
    }
}
