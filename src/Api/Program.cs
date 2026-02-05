using FnCast.Api.Contracts;
using FnCast.Application;
using FnCast.Application.Abstractions;
using FnCast.Domain.Models;
using FnCast.Infrastructure.Inference;
using FnCast.Infrastructure.Metadata;
using FnCast.Infrastructure.Options;
using FnCast.Infrastructure.Routing;
using FnCast.Infrastructure.Validation;

var builder = WebApplication.CreateBuilder(args);

// Configuration
builder.Services.Configure<InferenceOptions>(builder.Configuration.GetSection("Inference"));

// DI registrations (Infrastructure implementations)
builder.Services.AddSingleton<IEventValidator, JsonEventValidator>();
builder.Services.AddSingleton<IMetadataExtractor, BasicMetadataExtractor>();
builder.Services.AddSingleton<IInferenceExecutor, PlaceholderInferenceExecutor>();
builder.Services.AddSingleton<IOutputRouter, LoggingOutputRouter>();

// Orchestrator
builder.Services.AddSingleton<IPipelineOrchestrator, PipelineOrchestrator>();

var app = builder.Build();

// Health endpoint
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

// Ingestion endpoint
app.MapPost("/ingest", async (IngestRequest req, IPipelineOrchestrator orchestrator) =>
{
	var evt = new InferenceEvent(
		id: null,
		timestamp: null,
		rawPayload: req.Payload,
		contentType: req.ContentType);

	var result = await orchestrator.ProcessAsync(evt);
	var response = new IngestResponse
	{
		Success = result.Success,
		Output = result.Output,
		Metadata = result.Metadata,
		Errors = result.Errors
	};
	return Results.Ok(response);
});

app.Run();
