FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
WORKDIR /App

# Copy everything
COPY . .
# Restore as distinct layers
RUN dotnet restore
# Build and publish a release
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /App
COPY --from=build-env /App/out .
COPY --from=build-env /App/installer.sh .
COPY --from=build-env /App/runner.sh .

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update; apt-get -y install curl
RUN chmod +x installer.sh
RUN ./installer.sh
RUN tofu init

ENTRYPOINT ["dotnet", "OpenTofu.dll"]