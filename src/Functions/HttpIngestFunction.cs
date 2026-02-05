using System.Net;
using System.Text.Json;
using System.Threading.Tasks;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;

namespace FnCast.Functions
{
    /// <summary>
    /// HTTP-triggered ingestion function that processes events via the pipeline orchestrator.
    /// </summary>
    public class HttpIngestFunction
    {
        private readonly IPipelineOrchestrator _orchestrator;

        /// <summary>
        /// Initializes a new instance of the <see cref="HttpIngestFunction"/> class.
        /// </summary>
        public HttpIngestFunction(IPipelineOrchestrator orchestrator)
        {
            _orchestrator = orchestrator;
        }

        /// <summary>
        /// Handles POST requests containing a raw payload and optional content type.
        /// </summary>
        [Function("HttpIngest")]
        public async Task<HttpResponseData> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestData req,
            FunctionContext context)
        {
            var body = await req.ReadAsStringAsync();
            var contentType = req.Headers.TryGetValues("Content-Type", out var values) ? string.Join(",", values) : "application/json";
            var evt = new InferenceEvent(null, null, body, contentType);

            var result = await _orchestrator.ProcessAsync(evt, context.CancellationToken);

            var resp = req.CreateResponse(HttpStatusCode.OK);
            await resp.WriteAsJsonAsync(new
            {
                success = result.Success,
                output = result.Output,
                metadata = result.Metadata,
                errors = result.Errors
            });
            return resp;
        }
    }
}
