# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# copy project files first for better layer caching
COPY src/Api/FnCast.Api.csproj src/Api/
COPY src/Application/FnCast.Application.csproj src/Application/
COPY src/Infrastructure/FnCast.Infrastructure.csproj src/Infrastructure/
COPY src/Domain/FnCast.Domain.csproj src/Domain/

RUN dotnet restore src/Api/FnCast.Api.csproj

# copy rest of the source
COPY . .

RUN dotnet publish src/Api/FnCast.Api.csproj -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "FnCast.Api.dll"]
