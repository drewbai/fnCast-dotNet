using System.Threading;
using System.Threading.Tasks;
using FnCast.Domain.Models;

namespace FnCast.Application.Abstractions
{
    /// <summary>
    /// Validates inbound events prior to processing.
    /// </summary>
    public interface IEventValidator
    {
        /// <summary>
        /// Validates the provided <see cref="InferenceEvent"/>.
        /// </summary>
        /// <param name="evt">The inbound event.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>A <see cref="ValidationResult"/> indicating success or failure.</returns>
        Task<ValidationResult> ValidateAsync(InferenceEvent evt, CancellationToken cancellationToken = default);
    }
}
