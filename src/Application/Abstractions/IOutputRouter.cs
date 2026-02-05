using System.Threading;
using System.Threading.Tasks;
using FnCast.Domain.Models;

namespace FnCast.Application.Abstractions
{
    /// <summary>
    /// Routes the pipeline output to sinks such as logs or storage.
    /// </summary>
    public interface IOutputRouter
    {
        /// <summary>
        /// Routes the <see cref="InferenceResult"/>.
        /// </summary>
        /// <param name="evt">The original event.</param>
        /// <param name="result">The inference result.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        Task RouteAsync(InferenceEvent evt, InferenceResult result, CancellationToken cancellationToken = default);
    }
}
