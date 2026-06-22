# DataService/getDimensionData — Complete Flow

## 1. Overall Flow Summary

`getDimensionData` is a **server-streaming gRPC method** on `DataService`. It accepts a `DimensionDataRequest` (date range, team IDs, dimension, metrics, filters, report type, user context) and streams back serialized protobuf data chunked as `ByteStreamResponse` messages.

The request flows: gRPC handler → a cached Databricks service layer → a JDBC DAO that executes dynamically-built SQL against Databricks views/UDFs. Results are serialized and streamed in configurable partition sizes. A Redis cache (10-minute TTL) short-circuits the Databricks query on repeated identical requests. For media partner users, an upstream gRPC call to `fantastic-signals-user-service` fetches allowed publisher IDs before the query runs.

## 2. Call Chain

```
gRPC client
  │
  ▼
DataService.getDimensionData(DimensionDataRequest, StreamObserver)
  [grpc/DataService.java]
  │
  ├──► StreamingService.stream(data, responseObserver)
  │      [fantastic-signals-library:1.0.133 — chunks ByteStreamResponse]
  │
  └──► DimensionDataServiceDBXImpl.getDimensionDataDBX(request)
         @Cacheable("dimensionData") — checks Redis first
         │
         ├── [isCustomDimension] → DimensionQueryBuilderDBX (bare table + joins)
         │                       → DimensionDBXJdbcDaoImpl.getCustomDimensionDataDBX
         │
         └── [standard dimension]
               ├── contentLevelReport → fromUDTF("UDTF_AGG_CONTENT_LEVEL_REPORT_VIEW2")
               ├── contentTransparencyReport → fromView("ctv_content_transparency_filter")
               └── default perf report → fromView("agg_agency_custom_daily_fs")
                     [mediaPartner role] → UserServiceClient.getPublishersForMediaPartner()
               └── DimensionDBXJdbcDaoImpl.get{Campaign|Publisher|Placement|AdSize|DspDeal}DataDBX
```

## 3. DB Tables Touched (all READ-ONLY, Databricks JDBC)

| Table / View / UDTF | Used When |
|---|---|
| `reportingplatform_env.external_aggs.agg_agency_custom_daily_fs` | Default performance reports |
| `reportingplatform_env.LOOKER_SCRATCH.UDTF_AGG_CONTENT_LEVEL_REPORT_VIEW2` | `reportType = contentLevelReport` |
| `reportingplatform_env.prog_reporting.ctv_content_transparency_filter` | `reportType = contentTransparencyReport` |
| `reportingplatform_env.external_aggs.agg_agency_custom_daily_fs` (bare + joins) | Custom dimensions |
| `reportingplatform_env.silver.publisher` | Custom dimension JOIN |
| `reportingplatform_env.silver.placement` | Custom dimension JOIN |

## 4. External Dependencies

- **fantastic-signals-user-service** (gRPC, blocking) — called only for media partner roles to get allowed publisher IDs.
- **Databricks** (JDBC, read-only) — primary data store, HikariCP max 50 connections
- **Redis** — cache name `dimensionData`, TTL 10 min; fallback to EhCache (360 min / 64 MB off-heap)
- **fantastic-signals-library v1.0.133** — streaming/chunking infrastructure and `ServerTraceInterceptor`

## 5. Auth / Middleware

- **`ServerTraceInterceptor`** (`@GrpcGlobalServerInterceptor`) — tracing/Micrometer, all environments
- **`LoggingInterceptor`** — response-size logging, `local`/`dev` profiles only
- **`GrpcExceptionAdvice`** — maps `IllegalArgumentException` → `INVALID_ARGUMENT`, `IasException` → embedded status
- **No auth at the gRPC layer** — auth is enforced upstream (API gateway / network)

## 6. Mermaid Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    participant Client as gRPC Client
    participant Interceptor as ServerTraceInterceptor
    participant Handler as DataService (gRPC Handler)
    participant Cache as Redis (dimensionData, 10 min)
    participant Svc as DimensionDataServiceDBXImpl
    participant UserSvc as fantastic-signals-user-service
    participant QueryBuilder as DimensionQueryBuilderDBX
    participant DAO as DimensionDBXJdbcDaoImpl
    participant DBX as Databricks (JDBC)
    participant Streaming as StreamingService

    Client->>Interceptor: getDimensionData(DimensionDataRequest)
    Note over Interceptor: Attach trace context
    Interceptor->>Handler: forward request
    Handler->>Svc: getDimensionDataDBX(request)
    Svc->>Cache: lookup(request key)

    alt Cache HIT
        Cache-->>Svc: DimensionDataResponse
    else Cache MISS
        Cache-->>Svc: miss
        alt mediaPartner role
            Svc->>UserSvc: getPublishersForMediaPartner(currentUserId)
            UserSvc-->>Svc: publisherIds[]
        end
        alt isCustomDimension
            Svc->>QueryBuilder: fromBare(table) + joins
        else contentLevelReport
            Svc->>QueryBuilder: fromUDTF("UDTF_AGG_CONTENT_LEVEL_REPORT_VIEW2")
        else contentTransparencyReport
            Svc->>QueryBuilder: fromView("ctv_content_transparency_filter")
        else default
            Svc->>QueryBuilder: fromView("agg_agency_custom_daily_fs")
        end
        QueryBuilder-->>Svc: SQL + params
        Svc->>DAO: get*DataDBX(sql, params)
        DAO->>DBX: execute SQL (read-only)
        DBX-->>DAO: ResultSet
        DAO-->>Svc: typed dimension data
        Svc->>Cache: store(request key, response)
    end

    Svc-->>Handler: DimensionDataResponse
    Handler->>Streaming: stream(response, responseObserver)
    loop per partition (default 500 rows)
        Streaming-->>Client: ByteStreamResponse chunk
    end
    Streaming-->>Client: onCompleted
```
