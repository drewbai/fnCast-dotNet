# Architecture Diagrams

## Minimal API Ingestion Flow

```mermaid
flowchart TD
    A[HTTP POST /ingest] --> B[Create InferenceEvent]
    B --> C[IPipelineOrchestrator]
    C --> D[IEventValidator]
    D -->|Invalid| E[IOutputRouter -> Log warning]
    E --> F[HTTP 200 Response with errors]
    D -->|Valid| G[IMetadataExtractor]
    G --> H[IInferenceExecutor]
    H --> I[IOutputRouter -> Log info]
    I --> J[HTTP 200 Response with output]
```

## Azure Functions - HTTP Trigger Flow

```mermaid
flowchart TD
    A[HTTP Trigger: HttpIngest] --> B[Read body + headers]
    B --> C[Create InferenceEvent]
    C --> D[IPipelineOrchestrator]
    D --> E[IEventValidator]
    E -->|Invalid| F[IOutputRouter -> Log warning]
    F --> G[Function HTTP Response (errors)]
    E -->|Valid| H[IMetadataExtractor]
    H --> I[IInferenceExecutor]
    I --> J[IOutputRouter -> Log info]
    J --> K[Function HTTP Response (success)]
```

## Azure Functions - Queue & Event Grid Triggers

```mermaid
flowchart TD
    subgraph Triggers
      A1[Queue Trigger: fncast-events] --> B1[Create InferenceEvent]
      A2[Event Grid Trigger: EventGridIngest] --> B2[Create InferenceEvent]
    end
    B1 --> C[IPipelineOrchestrator]
    B2 --> C
    C --> D[IEventValidator]
    D -->|Invalid| E[IOutputRouter -> Log warning]
    D -->|Valid| F[IMetadataExtractor]
    F --> G[IInferenceExecutor]
    G --> H[IOutputRouter -> Log info]
```

## Application Layer Orchestrator (Interfaces)

```mermaid
flowchart LR
    Orchestrator[IPipelineOrchestrator] --> Validator[IEventValidator]
    Orchestrator --> Extractor[IMetadataExtractor]
    Orchestrator --> Executor[IInferenceExecutor]
    Orchestrator --> Router[IOutputRouter]

    style Orchestrator fill:#DDEEFF,stroke:#4477AA,stroke-width:2px
    classDef iface fill:#F9F9F9,stroke:#999,stroke-dasharray: 4 2
    class Validator,Extractor,Executor,Router iface
```
