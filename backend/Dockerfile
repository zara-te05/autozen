# ====================================================================
# AUTOZEN API - Imagen de producción
#   docker build -t autozen-api ./backend
# ====================================================================

# --- Compilación ---
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restaurar primero (capa cacheada mientras no cambie el .csproj)
COPY Autozen.Api.csproj ./
RUN dotnet restore Autozen.Api.csproj

COPY . ./
RUN dotnet publish Autozen.Api.csproj -c Release -o /app/publish --no-restore /p:UseAppHost=false

# --- Ejecución ---
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_HTTP_PORTS=8080 \
    # Detrás de un proxy (Nginx, Railway, Render...) toma la IP real del cliente y el esquema https
    # de X-Forwarded-For / X-Forwarded-Proto. Necesario para el rate limiting y la redirección HTTPS.
    ASPNETCORE_FORWARDEDHEADERS_ENABLED=true \
    DOTNET_gcServer=false

COPY --from=build /app/publish ./

# Carpeta de fotos de proyectos, escribible por el usuario sin privilegios (el volumen hereda el dueño)
RUN mkdir -p /app/fotos && chown $APP_UID /app/fotos

# Usuario sin privilegios incluido en la imagen oficial
USER $APP_UID

EXPOSE 8080
ENTRYPOINT ["dotnet", "Autozen.Api.dll"]
