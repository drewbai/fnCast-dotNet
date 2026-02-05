using System;
using System.Collections.Generic;

namespace FnCast.Domain.Models
{
    /// <summary>
    /// Represents an inbound event to be processed by the inference pipeline.
    /// </summary>
    public sealed class InferenceEvent
    {
        /// <summary>
        /// Gets the unique identifier for this event.
        /// </summary>
        public string Id { get; }

        /// <summary>
        /// Gets the timestamp when the event was received.
        /// </summary>
        public DateTimeOffset Timestamp { get; }

        /// <summary>
        /// Gets the raw payload for the event. Typically JSON.
        /// </summary>
        public string RawPayload { get; }

        /// <summary>
        /// Gets the MIME content type of the payload (e.g., application/json).
        /// </summary>
        public string ContentType { get; }

        /// <summary>
        /// Gets arbitrary attributes supplied with the event (headers, query, etc.).
        /// </summary>
        public IReadOnlyDictionary<string, string> Attributes { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="InferenceEvent"/> class.
        /// </summary>
        /// <param name="id">Unique event id (defaults to new GUID string if null).</param>
        /// <param name="timestamp">Event timestamp (defaults to UtcNow if null).</param>
        /// <param name="rawPayload">Raw payload data.</param>
        /// <param name="contentType">Payload content type.</param>
        /// <param name="attributes">Optional attributes.</param>
        public InferenceEvent(
            string? id,
            DateTimeOffset? timestamp,
            string rawPayload,
            string contentType,
            IReadOnlyDictionary<string, string>? attributes = null)
        {
            Id = id ?? Guid.NewGuid().ToString("N");
            Timestamp = timestamp ?? DateTimeOffset.UtcNow;
            RawPayload = rawPayload;
            ContentType = contentType;
            Attributes = attributes ?? new Dictionary<string, string>();
        }
    }
}
