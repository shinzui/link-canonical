-- |
-- Module      : Link.Canonical
-- Description : URL canonicalization library for semantic link identity
-- Copyright   : (c) Nadeem Bitar, 2026
-- License     : MIT
-- Maintainer  : Nadeem Bitar
-- Stability   : experimental
--
-- This library converts arbitrary URLs into canonical, semantically stable
-- identifiers. It handles:
--
-- * Redirect resolution (following URL shorteners, etc.)
-- * Tracking parameter removal (utm_*, fbclid, etc.)
-- * Domain-specific normalization (YouTube, Amazon, Twitter, etc.)
-- * Generic URL normalization (scheme, host, port, path, query, fragment)
--
-- = Quick Start
--
-- @
-- import Link.Canonical
-- import Text.URI (mkURI)
--
-- main :: IO ()
-- main = do
--   let Right uri = mkURI "https://youtu.be/dQw4w9WgXcQ?utm_source=share"
--   result <- normalizeWithDefaults uri
--   case result of
--     Left err -> print err
--     Right canonical -> print canonical
-- @
--
-- = Layered API
--
-- The library provides three API layers:
--
-- 1. __Pure normalization__ ('normalizeUri'): No IO, just transforms URIs
-- 2. __With redirect resolution__ ('normalizeLink'): Follows redirects, then normalizes
-- 3. __Convenient defaults__ ('normalizeWithDefaults'): Uses default configuration
module Link.Canonical
  ( -- * Main API
    normalizeLink,
    normalizeWithDefaults,
    normalizeUri,

    -- * Configuration
    NormConfig (..),
    RedirectConfig (..),
    TrackingConfig (..),
    TrailingSlash (..),
    defaultConfig,
    defaultRedirectConfig,
    defaultTrackingConfig,
    defaultTrackingParams,

    -- * Result types
    NormResult (..),
    NormTrace (..),

    -- * Error types
    NormError (..),
    RedirectError (..),
    HttpClientError (..),

    -- * HTTP client
    HttpClient (..),
    HttpResponse (..),
    HttpClientIO (..),
    newHttpClientIO,

    -- * Domain rules
    DomainRule (..),
    domainRule,
    applyDomainRules,
    defaultDomainRules,

    -- * Observability
    NormHooks (..),

    -- * Re-exports
    URI,
    mkURI,
  )
where

import Link.Canonical.Config
import Link.Canonical.Error
import Link.Canonical.Http
import Link.Canonical.Normalize (normalizeUri, normalizeUriWithTrace)
import Link.Canonical.Prelude
import Link.Canonical.Redirect (resolveFinalUriWithChain)
import Link.Canonical.Rules
import Link.Canonical.Types

-- | Normalize a URL with full redirect resolution
--
-- This is the main entry point for URL normalization. It:
--
-- 1. Resolves redirects (following 3xx responses)
-- 2. Applies generic normalization (scheme, host, port, path, query, fragment)
-- 3. Applies domain-specific rules (YouTube, Amazon, etc.)
-- 4. Strips tracking parameters
--
-- @
-- config = defaultConfig
--   & #redirects . #maxRedirects .~ 5
--   & #tracking . #allowlist .~ Set.fromList ["ref"]
--
-- result <- normalizeLink config httpClient uri
-- @
normalizeLink ::
  (HttpClient m) =>
  NormConfig ->
  URI ->
  m (Either NormError NormResult)
normalizeLink config uri = do
  -- Step 1: Resolve redirects
  redirectResult <- resolveFinalUriWithChain (config ^. #redirects) uri

  case redirectResult of
    Left err -> pure $ Left $ RedirectError err
    Right (resolved, chain) -> do
      -- Step 2: Apply normalization (generic + domain rules)
      let (canonical, ruleApplied, strippedParams) =
            normalizeUriWithTrace config defaultDomainRules resolved

      pure $
        Right $
          NormResult
            { canonical = canonical,
              original = uri,
              redirectsCount = length chain,
              redirectChain = chain,
              ruleApplied = ruleApplied,
              paramsStripped = strippedParams
            }

-- | Normalize a URL using default configuration
--
-- Convenience function that uses 'defaultConfig' and the default HTTP client.
--
-- @
-- result <- normalizeWithDefaults uri
-- case result of
--   Left err -> handleError err
--   Right res -> useCanonical (res ^. #canonical)
-- @
normalizeWithDefaults ::
  (HttpClient m) =>
  URI ->
  m (Either NormError URI)
normalizeWithDefaults uri = do
  result <- normalizeLink defaultConfig uri
  pure $ fmap (^. #canonical) result
