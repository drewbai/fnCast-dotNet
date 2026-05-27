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
        private static readonly Action<ILogger, string, string?, Exception?> LogSuccess =
            LoggerMessage.Define<string, string?>(LogLevel.Information, new EventId(1, "InferenceSucceeded"),
                "Inference succeeded for {EventId}: {Output}");

        private static readonly Action<ILogger, string, string, Exception?> LogFailure =
            LoggerMessage.Define<string, string>(LogLevel.Warning, new EventId(2, "InferenceFailed"),
                "Inference failed for {EventId}: {Errors}");

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
                LogSuccess(_logger, evt.Id, result.Output, null);
            }
            else
            {
                LogFailure(_logger, evt.Id, string.Join("; ", result.Errors), null);
            }

            return Task.CompletedTask;
        }
    }
}
