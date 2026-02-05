using System.Threading.Tasks;
using FnCast.Application;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;
using FnCast.Infrastructure.Inference;
using FnCast.Infrastructure.Metadata;
using FnCast.Infrastructure.Options;
using FnCast.Infrastructure.Routing;
using FnCast.Infrastructure.Validation;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Xunit;

namespace FnCast.Tests
{
    public class PipelineOrchestratorTests
    {
        [Fact]
        public async Task ProcessAsync_UppercaseMode_ProducesUppercaseOutput()
        {
            var services = new ServiceCollection();
            services.Configure<InferenceOptions>(opts => opts.Mode = InferenceMode.Uppercase);
            services.AddLogging();
            services.AddSingleton<Microsoft.Extensions.Logging.ILogger<FnCast.Infrastructure.Routing.LoggingOutputRouter>>(sp => Microsoft.Extensions.Logging.Abstractions.NullLogger<FnCast.Infrastructure.Routing.LoggingOutputRouter>.Instance);
            services.AddSingleton<IEventValidator, JsonEventValidator>();
            services.AddSingleton<IMetadataExtractor, BasicMetadataExtractor>();
            services.AddSingleton<IInferenceExecutor, PlaceholderInferenceExecutor>();
            services.AddSingleton<IOutputRouter, LoggingOutputRouter>();
            services.AddSingleton<IPipelineOrchestrator, PipelineOrchestrator>();

            var provider = services.BuildServiceProvider();
            var orchestrator = provider.GetRequiredService<IPipelineOrchestrator>();

            var evt = new InferenceEvent(null, null, rawPayload: "hello", contentType: "text/plain");
            var result = await orchestrator.ProcessAsync(evt);

            Assert.True(result.Success);
            Assert.Equal("HELLO", result.Output);
        }

        [Fact]
        public async Task ProcessAsync_InvalidJson_FailsValidation()
        {
            var services = new ServiceCollection();
            services.Configure<InferenceOptions>(opts => opts.Mode = InferenceMode.Echo);
            services.AddLogging();
            services.AddSingleton<Microsoft.Extensions.Logging.ILogger<FnCast.Infrastructure.Routing.LoggingOutputRouter>>(sp => Microsoft.Extensions.Logging.Abstractions.NullLogger<FnCast.Infrastructure.Routing.LoggingOutputRouter>.Instance);
            services.AddSingleton<IEventValidator, JsonEventValidator>();
            services.AddSingleton<IMetadataExtractor, BasicMetadataExtractor>();
            services.AddSingleton<IInferenceExecutor, PlaceholderInferenceExecutor>();
            services.AddSingleton<IOutputRouter, LoggingOutputRouter>();
            services.AddSingleton<IPipelineOrchestrator, PipelineOrchestrator>();

            var provider = services.BuildServiceProvider();
            var orchestrator = provider.GetRequiredService<IPipelineOrchestrator>();

            var evt = new InferenceEvent(null, null, rawPayload: "{ invalid json ", contentType: "application/json");
            var result = await orchestrator.ProcessAsync(evt);

            Assert.False(result.Success);
            Assert.NotEmpty(result.Errors);
        }
    }
}
