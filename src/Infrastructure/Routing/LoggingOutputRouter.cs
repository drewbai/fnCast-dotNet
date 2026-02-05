using System.Threading;
using System.Threading.Tasks;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;
using Microsoft.Extensions.Logging;

namespace FnCast.Infrastructure.Routing
{
    /// <summary>
    /// Routes pipeline results to the configured logger.
    /// </summary>
    public sealed class LoggingOutputRouter : IOutputRouter
    {
        private readonly ILogger<LoggingOutputRouter> _logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="LoggingOutputRouter"/> class.
        /// </summary>
        public LoggingOutputRouter(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<LoggingOutputRouter>();
        }

        /// <inheritdoc />
        public Task RouteAsync(InferenceEvent evt, InferenceResult result, CancellationToken cancellationToken = default)
        {
            if (result.Success)
            {
                _logger.LogInformation("Inference succeeded for {EventId}: {Output}", evt.Id, result.Output);
            }
            else
            {
                _logger.LogWarning("Inference failed for {EventId}: {Errors}", evt.Id, string.Join("; ", result.Errors));
            }

            return Task.CompletedTask;
        }
    }
}
