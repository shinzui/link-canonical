# Changelog

## 0.1.0.0

Initial release.

### New Features

- URL canonicalization with redirect resolution
- Tracking parameter removal for common analytics parameters
- Percent-encoding normalization
- Dot segment normalization (RFC 3986 Section 5.2.4)
- Domain-specific normalization rules:
  - YouTube (video/playlist URL cleanup)
  - Amazon (product URL cleanup)
  - Twitter/X (status URL normalization)
  - GitHub (repository URL normalization)
  - Instagram (post URL cleanup)
  - Reddit (thread URL cleanup)
