# MetaMesh App for Worph-Appstore

## Status: Ready for Testing

This app configuration has been created and is ready for testing. The following files have been generated:

### Completed Files ✅

- **docker-compose.yml** - CasaOS-compatible configuration with full metadata
- **rationale.md** - Documentation of configuration decisions
- **icon.png** - 512x512 PNG icon generated from MetaMesh SVG logo
- **thumbnail.png** - 800x400 thumbnail with logo on gradient background

### Placeholder Screenshots ⚠️

The following screenshot files are **placeholders** and should be replaced with actual screenshots from a running MetaMesh instance:

1. **screenshot-1.png** - Should show the **Monitoring Dashboard** (`/monitor`)
   - Show file processing statistics
   - Display duplicate detection
   - Show performance metrics

2. **screenshot-2.png** - Should show the **Virtual Filesystem Browser**
   - Directory tree view
   - Organized media structure (Anime/Movies/TV Shows)
   - File metadata display

3. **screenshot-3.png** - Should show **File Processing Details**
   - Metadata extraction results
   - FFmpeg analysis output
   - Hash calculation and duplicate status

### How to Capture Real Screenshots

1. Start MetaMesh using Docker:
   ```bash
   docker-compose -f /d/workspace/yundera/Worph-Appstore/Apps/MetaMesh/docker-compose.yml up -d
   ```

2. Access the monitoring dashboard at `http://localhost/monitor`

3. Browse the virtual filesystem at `/DATA/MetaMesh` on the host (organized media structure)

4. Capture screenshots at 1920x1080 resolution showing:
   - Main dashboard with statistics
   - Virtual filesystem interface
   - File processing details or etcd management UI

4. Replace the placeholder PNG files with actual screenshots

### Testing Checklist

Before publishing to the store:

- [ ] Test deployment on CasaOS/CasaIMG
- [ ] Verify FUSE capabilities work on host system
- [ ] Test WebDAV access with credentials (metamesh/metamesh)
- [ ] Verify etcd data persistence
- [ ] Replace placeholder screenshots with actual UI captures
- [ ] Test with actual media files in watch folders
- [ ] Verify asset URLs are accessible via CDN
- [ ] Test on both amd64 and arm64 architectures (if supported)

### Docker Image

The configuration uses the published image:
```
rg.fr-par.scw.cloud/aptero/meta-mesh:1.0.0
```

Ensure this image is available in the registry before publishing the app to the store.

### Next Steps

1. Deploy and test the application
2. Capture actual screenshots from running instance
3. Update placeholder screenshots
4. Test on actual CasaOS environment
5. Submit to Worph-Appstore repository

---

**Generated**: 2025-11-04
**Status**: Awaiting real screenshots and testing
