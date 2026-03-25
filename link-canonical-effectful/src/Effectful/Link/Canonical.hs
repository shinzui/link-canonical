module Effectful.Link.Canonical
  ( -- * Effect
    LinkCanonical (..),

    -- * Operations
    normalizeLink,
    normalizeWithDefaults,

    -- * Handlers
    runLinkCanonical,

    -- * HTTP effect
    HttpHead (..),
    headRequest,
    runHttpHead,

    -- * Pure normalization (re-export)
    Core.normalizeUri,

    -- * Configuration (re-exports)
    Core.NormConfig (..),
    Core.RedirectConfig (..),
    Core.TrackingConfig (..),
    Core.TrailingSlash (..),
    Core.defaultConfig,
    Core.defaultRedirectConfig,
    Core.defaultTrackingConfig,
    Core.defaultTrackingParams,

    -- * Result types (re-exports)
    Core.NormResult (..),
    Core.NormTrace (..),

    -- * Error types (re-exports)
    Core.NormError (..),
    Core.RedirectError (..),
    Core.HttpClientError (..),

    -- * Domain rules (re-exports)
    Core.DomainRule (..),
    Core.defaultDomainRules,

    -- * Observability (re-exports)
    Core.NormHooks (..),

    -- * URI (re-exports)
    URI,
    mkURI,
  )
where

import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.Link.Canonical.Http (HttpHead (..), headRequest, runHttpHead)
import Link.Canonical qualified as Core
import Text.URI (URI, mkURI)

-- | Effect for URL canonicalization.
--
-- Provides the same two IO-dependent operations as the core library's
-- public API: full normalization with redirect resolution, and a
-- convenience wrapper with default configuration.
data LinkCanonical :: Effect where
  NormalizeLink :: Core.NormConfig -> URI -> LinkCanonical m (Either Core.NormError Core.NormResult)
  NormalizeWithDefaults :: URI -> LinkCanonical m (Either Core.NormError URI)

type instance DispatchOf LinkCanonical = Dynamic

-- | Normalize a URL with full redirect resolution and domain-specific rules.
normalizeLink :: (LinkCanonical :> es) => Core.NormConfig -> URI -> Eff es (Either Core.NormError Core.NormResult)
normalizeLink config uri = send $ NormalizeLink config uri

-- | Normalize a URL using default configuration, returning only the canonical URI.
normalizeWithDefaults :: (LinkCanonical :> es) => URI -> Eff es (Either Core.NormError URI)
normalizeWithDefaults = send . NormalizeWithDefaults

-- | Run the 'LinkCanonical' effect by delegating to the core library.
--
-- Requires 'HttpHead' in the effect stack for redirect resolution.
runLinkCanonical :: (HttpHead :> es) => Eff (LinkCanonical : es) a -> Eff es a
runLinkCanonical = interpret $ \_ -> \case
  NormalizeLink config uri -> Core.normalizeLink config uri
  NormalizeWithDefaults uri -> Core.normalizeWithDefaults uri
