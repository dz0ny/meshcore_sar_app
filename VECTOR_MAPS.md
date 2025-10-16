# Vector Map Tiles with MBTiles - User Guide

This guide explains how to use offline vector map tiles in MeshCore SAR app.

## Overview

The app now supports **offline vector map tiles** using the MBTiles format. Vector tiles provide:

- ✅ **True Offline Maps**: Work without any internet connection after initial import
- ✅ **Smaller File Sizes**: ~70% smaller than raster tiles (e.g., 150MB vs 500MB)
- ✅ **Better Performance**: Smooth zooming with over-zooming support
- ✅ **Customizable Styles**: Change map appearance without re-downloading tiles
- ✅ **SAR-Optimized**: Topographic styles ideal for search & rescue operations

## Quick Start

### 1. Download MBTiles File

Download a vector tile MBTiles file for your region. Recommended sources:

**Option A: Geofabrik (via MapTiler)** - Recommended for Slovenia
```
URL: https://geodata.maptiler.download/extracts/osm/v3.11/2020-02-10/europe/osm-2020-02-10-v3.11_europe_slovenia.mbtiles
Schema: Shortbread
Size: ~150MB (Slovenia)
```

**Option B: Protomaps** - Global coverage
```
URL: https://maps.protomaps.com/builds/
Format: PMTiles (can be converted to MBTiles)
```

**Option C: OpenMapTiles** - Self-hosted
```
URL: https://openmaptiles.org/downloads/
Schema: OpenMapTiles
Requires: Account (free tier available)
```

### 2. Import MBTiles File

1. Open **Settings** → **Map Management**
2. Scroll to **"Offline Vector Maps"** section
3. Tap **"Import MBTiles File"**
4. Select your downloaded `.mbtiles` file
5. Wait for import to complete

### 3. Select Vector Layer

1. Go to the **Map** tab
2. Tap the **Layers** button (bottom-right)
3. Select your imported vector map from the list
4. The app will automatically download the appropriate style

### 4. Enjoy Offline Maps!

Your vector maps now work completely offline. No internet required!

## Detailed Features

### File Management

The **Map Management** screen shows:

- **File Name**: Name from MBTiles metadata
- **File Size**: Human-readable (KB/MB/GB)
- **Format**: PBF (vector) or PNG/JPG (raster)
- **Zoom Levels**: Min and max zoom supported
- **Geographic Bounds**: Coverage area coordinates
- **Vector Schema**: Shortbread, OpenMapTiles, or Unknown

**Actions:**
- **Expand Card**: Tap to see full metadata
- **Delete**: Tap delete button (confirmation required)
- **Refresh**: Tap refresh icon to reload list

### Supported Vector Schemas

#### Shortbread (Geofabrik)
- **Best for**: European regions, SAR operations
- **Style Source**: versatiles.org
- **Compatible MBTiles**: Geofabrik extracts
- **Compression**: Gzipped PBF data

#### OpenMapTiles
- **Best for**: Global coverage, detailed mapping
- **Style Source**: openmaptiles.org or custom
- **Compatible MBTiles**: OpenMapTiles downloads
- **Compression**: Standard PBF data

### Map Styles

Vector tile styles are automatically downloaded from:

**Versatiles (Shortbread):**
```
https://tiles.versatiles.org/assets/styles/colorful.json
```

**Features:**
- Topographic contours
- Road classification
- Building outlines
- Natural features (forests, water)
- POI markers

### Technical Details

#### Storage Location
```
iOS: /Documents/offline_maps/
Android: /data/data/com.meshcore.sar/files/offline_maps/
```

#### Supported Formats
- **Vector**: PBF (Protocol Buffer Format), MVT (Mapbox Vector Tile)
- **Compression**: Auto-detected gzip compression
- **Schema**: Shortbread, OpenMapTiles, or custom

#### Performance

**Slovenia Example (Geofabrik):**
- File Size: ~150MB
- Zoom Levels: 0-14
- Tile Count: ~500,000 tiles
- Load Time: <2 seconds

**Comparison with Raster:**
- Raster (same area, zoom 0-16): ~500MB
- Vector advantage: **70% smaller**

## Troubleshooting

### Import Fails

**Error**: "Failed to import MBTiles file"

**Solutions:**
1. Verify file is valid MBTiles format (use `mbtiles` CLI to validate)
2. Check file permissions (ensure app can read the file)
3. Ensure sufficient storage space available
4. Try re-downloading the MBTiles file

### Style Not Loading

**Error**: "Failed to load map style"

**Solutions:**
1. Check internet connection (required for first-time style download)
2. Wait and retry (remote servers may be temporarily down)
3. Clear app cache and restart
4. Verify MBTiles schema matches style (Shortbread vs OpenMapTiles)

### Map Not Displaying

**Symptoms**: Blank map or only showing other layers

**Solutions:**
1. Verify layer is selected in layer picker
2. Check zoom level is within MBTiles zoom range
3. Pan to area covered by MBTiles bounds
4. Restart app to reload layers

### Black Screen on Map

**Cause**: Vector theme not loaded yet

**Solution:** Wait for style download to complete (loading indicator shows progress)

## Advanced Usage

### Using Custom Styles

To use custom vector tile styles:

1. Host your style JSON on a web server
2. Modify `MapLayer.fromMbtilesFile()` to use your style URL
3. Ensure style schema matches your MBTiles schema

Example style URL format:
```
https://your-server.com/styles/custom-sar-style.json
```

### Converting Other Formats

**PMTiles → MBTiles:**
```bash
# Using tippecanoe
pmtiles extract region.pmtiles region.mbtiles
```

**Shapefile → MBTiles:**
```bash
# Using tippecanoe
tippecanoe -o output.mbtiles input.shp
```

### Generating Custom MBTiles

Use **Tilemaker** to generate MBTiles from OSM data:

```bash
# Download OSM extract
wget https://download.geofabrik.de/europe/slovenia-latest.osm.pbf

# Generate MBTiles with Shortbread schema
tilemaker --input slovenia-latest.osm.pbf \
          --output slovenia-custom.mbtiles \
          --config shortbread.json \
          --process shortbread.lua
```

## References

### Documentation
- [Vector Map Tiles Package](https://pub.dev/packages/vector_map_tiles)
- [MBTiles Specification](https://github.com/mapbox/mbtiles-spec)
- [Shortbread Schema](https://shortbread-tiles.org/)
- [Versatiles Styles](https://versatiles.org/)

### Tools
- [Tilemaker](https://github.com/systemed/tilemaker) - Generate MBTiles from OSM
- [MBTiles CLI](https://github.com/mapbox/mbtiles-spec) - Validate and inspect
- [Tippecanoe](https://github.com/felt/tippecanoe) - Convert and optimize tiles

### Data Sources
- [Geofabrik](https://download.geofabrik.de/) - OSM extracts
- [Protomaps](https://protomaps.com/) - Pre-generated PMTiles
- [OpenMapTiles](https://openmaptiles.org/) - Commercial and free options

## FAQ

**Q: Can I use multiple MBTiles files at once?**
A: Yes! Import multiple files and switch between them using the layer picker.

**Q: Do I need internet after importing?**
A: Only for the first-time style download. After that, fully offline.

**Q: What's the maximum file size?**
A: No hard limit. Tested with files up to 2GB successfully.

**Q: Can I share MBTiles files between devices?**
A: Yes! Export the `.mbtiles` file and import on another device.

**Q: Do vector tiles work on iOS and Android?**
A: Yes! Fully supported on both platforms.

**Q: How do I update map data?**
A: Download a new MBTiles file with updated data and import it.

## Support

For issues or questions:
- GitHub Issues: [meshcore-sar/issues](https://github.com/meshcore-dev/meshcore-sar/issues)
- Documentation: See CLAUDE.md for technical details
- Community: Join the MeshCore Slack/Discord

## License

Vector map tiles implementation uses:
- `vector_map_tiles` - MIT License
- `vector_map_tiles_mbtiles` - MIT License
- Map data copyright OpenStreetMap contributors
