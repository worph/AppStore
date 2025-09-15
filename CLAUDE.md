# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the Worph-AppStore, a fork of the Yundera CasaOS 3rd-Party AppStore that provides a curated collection of Docker Compose applications compatible with CasaOS. The key difference from the main Yundera AppStore is that this fork uses the CDN URL `https://cdn.jsdelivr.net/gh/Worph/AppStore@main/` for assets instead of the standard Yundera URLs.

## Architecture & Structure

### Core Components

- **Apps Directory**: Each application lives in `Apps/{AppName}/` containing:
  - `docker-compose.yml` - Docker Compose configuration with CasaOS metadata
  - `icon.png` - Application icon (PNG format)
  - `screenshot-{1,2,3}.png` - Application screenshots
  - `thumbnail.png` - Optional thumbnail image
  - Optional: `rationale.md`, `pre-install/` directory with scripts

- **Configuration Files**:
  - `category-list.json` - Defines app categories with Material Design icons
  - `recommend-list.json` - List of recommended applications
  - `featured-apps.json` - Featured applications list

### Docker Compose Structure

All apps follow a consistent pattern:
- **Services**: Main application containers with dependencies (databases, etc.)
- **Environment Variables**: Uses CasaOS variables like `$PUID`, `$PGID`, `$TZ`, `$default_pwd`, `$domain`
- **Volumes**: Maps to `/DATA/AppData/{appname}/` for persistent storage
- **Networking**: Uses `expose` instead of `ports` for internal communication
- **x-casaos metadata**: Contains app metadata for the CasaOS interface

### Key Conventions

- **Asset URLs**: All use `https://cdn.jsdelivr.net/gh/Worph/AppStore@main/Apps/{AppName}/`
- **Storage**: Applications store data in `/DATA/AppData/{appname}/`
- **Media**: Common media paths: `/DATA/Media/Movies`, `/DATA/Media/TV Shows`, `/DATA/Downloads`
- **Networking**: Apps expose internal ports and rely on external proxy for HTTPS
- **Multi-language Support**: Descriptions and taglines support multiple locales (en_us, fr_fr, es_es, zh_cn, ko_kr, de_de)

## Development Workflow

### Adding New Applications

1. Create directory structure: `Apps/{AppName}/`
2. Add `docker-compose.yml` with proper CasaOS metadata
3. Include required assets (icon.png, screenshots)
4. Test on actual CasaOS environment before submission
5. Update category lists if introducing new categories

### Testing Applications

Applications must be tested on:
- CasaIMG (dockerized CasaOS)
- Yundera servers with nsl.sh routing
- Both amd64 and arm64 architectures when supported

### Asset Management

- Icons: PNG format, square aspect ratio
- Screenshots: PNG format, application interface captures
- Thumbnails: Optional, used for featured display
- All assets served via jsdelivr CDN

## Common Commands

Since this is a configuration repository without build processes:

```bash
# Validate docker-compose files
docker-compose -f Apps/{AppName}/docker-compose.yml config

# Test app locally (requires CasaOS environment variables)
docker-compose -f Apps/{AppName}/docker-compose.yml up -d

# Lint YAML files
yamllint Apps/*/docker-compose.yml

# Check JSON configuration files
jq . category-list.json
jq . recommend-list.json
jq . featured-apps.json
```

## Contributing Guidelines

Reference the main Yundera AppStore contributing guidelines at:
`https://raw.githubusercontent.com/Yundera/AppStore/refs/heads/main/CONTRIBUTING.md`

Key differences for this fork:
- Use `https://cdn.jsdelivr.net/gh/Worph/AppStore@main/` for asset URLs
- Maintain compatibility with CasaOS and mesh router architecture
- Ensure HTTPS accessibility through nsl.sh domain routing

## Related Projects

- **CasaIMG**: Docker-based CasaOS image manager
- **Mesh-Router**: Domain management for containerized applications
- **Yundera**: Cloud server platform for open source containers
- **NSL.SH**: Free domain provider for open source projects