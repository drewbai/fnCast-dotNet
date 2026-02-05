using System.Threading.Tasks;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;
using Microsoft.Azure.Functions.Worker;

namespace FnCast.Functions
{
    /// <summary>
    /// Queue-triggered ingestion function that processes events as messages.
    /// </summary>
    public class QueueIngestFunction
    {
        private readonly IPipelineOrchestrator _orchestrator;

        /// <summary>
        /// Initializes a new instance of the <see cref="QueueIngestFunction"/> class.
        /// </summary>
        public QueueIngestFunction(IPipelineOrchestrator orchestrator)
        {
            _orchestrator = orchestrator;
        }

        /// <summary>
        /// Processes messages from the queue named 'fncast-events'.
        /// </summary>
        [Function("QueueIngest")]
        public async Task Run(
            [QueueTrigger("fncast-events", Connection = "AzureWebJobsStorage")] string message,
            FunctionContext context)
        {
            var evt = new InferenceEvent(null, null, message, "text/plain");
            await _orchestrator.ProcessAsync(evt, context.CancellationToken);
        }
    }
}
