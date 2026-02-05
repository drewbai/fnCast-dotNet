using FnCast.Application;
using FnCast.Application.Abstractions;
using FnCast.Infrastructure.Inference;
using FnCast.Infrastructure.Metadata;
using FnCast.Infrastructure.Options;
using FnCast.Infrastructure.Routing;
using FnCast.Infrastructure.Validation;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureAppConfiguration((context, config) =>
    {
        config.AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);
        config.AddEnvironmentVariables();
    })
    .ConfigureServices((context, services) =>
    {
        services.Configure<InferenceOptions>(context.Configuration.GetSection("Inference"));

        services.AddSingleton<IEventValidator, JsonEventValidator>();
        services.AddSingleton<IMetadataExtractor, BasicMetadataExtractor>();
        services.AddSingleton<IInferenceExecutor, PlaceholderInferenceExecutor>();
        services.AddSingleton<IOutputRouter, LoggingOutputRouter>();
        services.AddSingleton<IPipelineOrchestrator, PipelineOrchestrator>();
    })
    .Build();

await host.RunAsync();
