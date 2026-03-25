# link-canonical

A Haskell library for converting arbitrary URLs into canonical, semantically stable identifiers. Enables URL deduplication and stable link identity in systems that ingest URLs from multiple sources.

## Features

- **Tracking parameter removal** - Strips UTM parameters, ad click IDs (gclid, fbclid, msclkid), and other marketing trackers
- **Redirect chain resolution** - Follows URL shorteners and redirects to find the final destination
- **Domain-specific normalization** - Intelligent rules for YouTube, Amazon, Twitter/X, GitHub, Instagram, and Reddit
- **RFC 3986 compliance** - Proper dot segment normalization, percent-encoding, and path handling
- **Security features** - Private IP blocking (SSRF prevention), HTTPS downgrade protection, redirect loop detection

## Installation

Add to your cabal file:

```cabal
build-depends:
    link-canonical
```

Or with Nix flakes:

```nix
{
  inputs.link-canonical.url = "github:shinzui/link-canonical";
}
```

## Usage

### Quick Start

```haskell
import Link.Canonical
import Text.URI (mkURI)

main :: IO ()
main = do
  let Right uri = mkURI "https://youtu.be/dQw4w9WgXcQ?utm_source=twitter"
  result <- normalizeWithDefaults uri
  case result of
    Left err -> print err
    Right canonical -> print canonical
    -- Output: https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

### API Layers

The library provides three layers of functionality:

```haskell
-- Pure normalization (no IO, no redirects)
normalizeUri :: NormConfig -> [DomainRule] -> URI -> Either NormError URI

-- With redirect resolution (IO)
normalizeLink :: NormConfig -> URI -> IO (Either NormError NormResult)

-- Convenient defaults
normalizeWithDefaults :: URI -> IO (Either NormError NormResult)
```

### Configuration

```haskell
import Link.Canonical
import Link.Canonical.Types
import Link.Canonical.Config

-- Customize configuration
customConfig :: NormConfig
customConfig = defaultConfig
  & #redirects . #maxRedirects .~ 5
  & #redirects . #timeout .~ 30
  & #tracking . #allowlist .~ Set.fromList ["ref"]
```

#### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `redirects.maxRedirects` | 10 | Maximum redirect hops |
| `redirects.timeout` | 10s | Request timeout |
| `redirects.allowDowngrade` | False | Allow HTTPS to HTTP redirects |
| `redirects.blockPrivateIPs` | True | Block private/local IPs (SSRF protection) |
| `tracking.denyPatterns` | See below | Patterns for tracking parameters |
| `stripFragment` | True | Remove URL fragments |
| `sortParams` | True | Sort query parameters alphabetically |

## Domain Rules

### YouTube

All YouTube URL formats normalize to a consistent watch URL:

| Input | Output |
|-------|--------|
| `youtu.be/dQw4w9WgXcQ` | `youtube.com/watch?v=dQw4w9WgXcQ` |
| `youtube.com/embed/dQw4w9WgXcQ` | `youtube.com/watch?v=dQw4w9WgXcQ` |
| `youtube.com/shorts/dQw4w9WgXcQ` | `youtube.com/watch?v=dQw4w9WgXcQ` |

### Amazon

Amazon product URLs preserve the regional TLD and normalize to the canonical `/dp/{ASIN}` format:

| Input | Output |
|-------|--------|
| `amazon.com/Some-Product/dp/B08N5WRWNW/ref=sr_1_1` | `amazon.com/dp/B08N5WRWNW` |
| `amazon.co.uk/dp/B08N5WRWNW` | `amazon.co.uk/dp/B08N5WRWNW` |

### Twitter/X

Twitter URLs normalize to X.com:

| Input | Output |
|-------|--------|
| `twitter.com/user/status/123` | `x.com/user/status/123` |
| `x.com/user/status/123?s=20` | `x.com/user/status/123` |

### GitHub

GitHub URLs preserve meaningful fragments (line numbers):

| Input | Output |
|-------|--------|
| `github.com/owner/repo/blob/main/file.hs#L10-L20` | `github.com/owner/repo/blob/main/file.hs#L10-L20` |
| `github.com/owner/repo?tab=readme` | `github.com/owner/repo` |

### Instagram

Instagram URLs normalize subdomains:

| Input | Output |
|-------|--------|
| `instagram.com/p/ABC123` | `www.instagram.com/p/ABC123` |

### Reddit

Reddit URLs normalize to the main domain:

| Input | Output |
|-------|--------|
| `old.reddit.com/r/haskell/comments/abc` | `www.reddit.com/r/haskell/comments/abc` |

## Tracking Parameters

The following tracking parameters are removed by default:

- **Google Analytics**: `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content`, `_ga`, `_gl`, `_gid`
- **Ad Platforms**: `gclid`, `fbclid`, `msclkid`, `dclid`
- **Marketing**: `mc_*`, `oly_*`, `_hsenc`, `_hsmi`, `mkt_tok`
- **Social**: `igshid`, `si`, `ref`, `source`
- **Other**: `zanpid`

## Development

### Prerequisites

- GHC 9.12+
- Cabal 3.0+
- Or Nix (recommended)

### Setup with Nix

```bash
# Enter development shell
nix develop

# Build
cabal build

# Run tests
cabal test

# Format code
treefmt
```

### Setup without Nix

```bash
# Build
cabal build

# Run tests
cabal test
```

### Project Structure

```
src/Link/Canonical/
├── Canonical.hs      # Main entry point
├── Types.hs          # Core types
├── Config.hs         # Default configuration
├── Normalize.hs      # Generic URL normalization
├── Redirect.hs       # Redirect resolution
├── Tracking.hs       # Tracking parameter stripping
└── Rules/            # Domain-specific rules
    ├── YouTube.hs
    ├── Amazon.hs
    ├── Twitter.hs
    ├── GitHub.hs
    ├── Instagram.hs
    └── Reddit.hs
```

## Testing

```bash
cabal test
```

The test suite includes:

- Generic normalization tests (scheme, host, port, path, query, fragment)
- Tracking parameter removal tests
- Redirect resolution tests (including loop detection, timeout handling)
- Edge case tests (empty URLs, special characters, encoding)
- Domain-specific rule tests for each supported platform

## License

MIT License - see [LICENSE](LICENSE) for details.

Copyright 2025 Nadeem Bitar
