using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using FnCast.Domain.Models;

namespace FnCast.Application.Abstractions
{
    /// <summary>
    /// Extracts metadata from the inbound event payload.
    /// </summary>
    public interface IMetadataExtractor
    {
        /// <summary>
        /// Extracts metadata from the event.
        /// </summary>
        /// <param name="evt">The inbound event.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>A dictionary of metadata values.</returns>
        Task<IReadOnlyDictionary<string, string>> ExtractAsync(InferenceEvent evt, CancellationToken cancellationToken = default);
    }
}
