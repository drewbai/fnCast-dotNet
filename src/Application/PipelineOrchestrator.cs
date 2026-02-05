using System.Threading;
using System.Threading.Tasks;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;

namespace FnCast.Application
{
    /// <summary>
    /// Default pipeline orchestrator coordinating all stages via dependency injection.
    /// </summary>
    public sealed class PipelineOrchestrator : IPipelineOrchestrator
    {
        private readonly IEventValidator _validator;
        private readonly IMetadataExtractor _metadataExtractor;
        private readonly IInferenceExecutor _inferenceExecutor;
        private readonly IOutputRouter _outputRouter;

        /// <summary>
        /// Initializes a new instance of the <see cref="PipelineOrchestrator"/> class.
        /// </summary>
        public PipelineOrchestrator(
            IEventValidator validator,
            IMetadataExtractor metadataExtractor,
            IInferenceExecutor inferenceExecutor,
            IOutputRouter outputRouter)
        {
            _validator = validator;
            _metadataExtractor = metadataExtractor;
            _inferenceExecutor = inferenceExecutor;
            _outputRouter = outputRouter;
        }

        /// <inheritdoc />
        public async Task<InferenceResult> ProcessAsync(InferenceEvent evt, CancellationToken cancellationToken = default)
        {
            var validation = await _validator.ValidateAsync(evt, cancellationToken).ConfigureAwait(false);
            if (!validation.IsValid)
            {
                var failed = new InferenceResult(false, output: string.Empty, errors: validation.Errors);
                await _outputRouter.RouteAsync(evt, failed, cancellationToken).ConfigureAwait(false);
                return failed;
            }

            var metadata = await _metadataExtractor.ExtractAsync(evt, cancellationToken).ConfigureAwait(false);
            var result = await _inferenceExecutor.ExecuteAsync(evt, metadata, cancellationToken).ConfigureAwait(false);
            await _outputRouter.RouteAsync(evt, result, cancellationToken).ConfigureAwait(false);
            return result;
        }
    }
}
