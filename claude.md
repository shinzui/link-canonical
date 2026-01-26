# Claude Code Context

## Project Overview

link-canonical is a Haskell library for URL canonicalization. It converts arbitrary URLs into stable, deduplicated identifiers by:

- Resolving redirects
- Removing tracking parameters
- Applying domain-specific normalization rules (YouTube, Amazon, Twitter/X, GitHub, Instagram, Reddit)

## Tech Stack

- **Language:** Haskell (GHC2024, GHC 9.12+)
- **Build:** Cabal 3.0+
- **Dev Environment:** Nix flakes
- **URI Parsing:** modern-uri
- **HTTP:** http-client / http-client-tls
- **Lenses:** generic-lens + lens (uses OverloadedLabels)

## Development Commands

```bash
nix develop        # Enter dev shell
cabal build        # Build the project
cabal test         # Run tests
```

## Before Committing

Always run formatting before committing:

```bash
nix fmt
```

This runs treefmt which applies:
- fourmolu (Haskell)
- nixpkgs-fmt (Nix)
- cabal-gild (Cabal)

## Project Structure

- `src/Link/Canonical/` - Main library code
  - `Canonical.hs` - Entry point, exports public API
  - `Types.hs` - Core types (NormConfig, NormResult, etc.)
  - `Normalize.hs` - Generic URL normalization
  - `Redirect.hs` - Redirect chain resolution
  - `Tracking.hs` - Tracking parameter removal
  - `Rules/` - Domain-specific rules (YouTube.hs, Amazon.hs, etc.)
- `test/` - Test suite using Tasty
- `docs/architecture/v1.md` - Detailed technical specification

## Code Style

- Uses custom prelude (`Link.Canonical.Prelude`)
- Lens access via OverloadedLabels: `config ^. #redirects . #maxRedirects`
- Strict data by default (StrictData extension)
- No field selectors (NoFieldSelectors + OverloadedLabels pattern)
