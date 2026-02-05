using System.Threading.Tasks;
using Azure.Messaging.EventGrid;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;
using Microsoft.Azure.Functions.Worker;

namespace FnCast.Functions
{
    /// <summary>
    /// Event Grid-triggered ingestion function that processes CloudEvent payloads.
    /// </summary>
    public class EventGridIngestFunction
    {
        private readonly IPipelineOrchestrator _orchestrator;

        /// <summary>
        /// Initializes a new instance of the <see cref="EventGridIngestFunction"/> class.
        /// </summary>
        public EventGridIngestFunction(IPipelineOrchestrator orchestrator)
        {
            _orchestrator = orchestrator;
        }

        /// <summary>
        /// Handles Event Grid events and forwards payload to the orchestrator.
        /// </summary>
        [Function("EventGridIngest")]
        public async Task Run([EventGridTrigger] EventGridEvent evtGrid, FunctionContext context)
        {
            var payload = evtGrid.Data.ToString();
            var contentType = "application/json";
            var evt = new InferenceEvent(null, null, payload, contentType);
            await _orchestrator.ProcessAsync(evt, context.CancellationToken);
        }
    }
}
