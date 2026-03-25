module Link.Canonical.Types
  ( -- * Result types
    NormResult (..),
    NormTrace (..),

    -- * Configuration types
    NormConfig (..),
    RedirectConfig (..),
    TrackingConfig (..),
    TrailingSlash (..),

    -- * Observability
    NormHooks (..),
  )
where

import Link.Canonical.Prelude

-- | Result of URL normalization
data NormResult = NormResult
  { -- | The canonical form of the URL
    canonical :: URI,
    -- | The original input URL
    original :: URI,
    -- | Number of redirects followed
    redirectsCount :: Int,
    -- | Full redirect chain for debugging
    redirectChain :: [URI],
    -- | Name of the domain rule applied, if any
    ruleApplied :: Maybe Text,
    -- | Tracking parameters that were removed
    paramsStripped :: [Text]
  }
  deriving stock (Generic, Eq, Show)

-- | Detailed trace of normalization for debugging
data NormTrace = NormTrace
  { -- | Original input
    input :: URI,
    -- | After redirect resolution
    afterRedirects :: URI,
    -- | After generic normalization
    afterGeneric :: URI,
    -- | After domain-specific rules
    afterDomain :: URI,
    -- | Final canonical URL
    final :: URI,
    -- | All URLs in redirect chain
    redirectChain :: [URI],
    -- | Domain rule that was applied
    ruleApplied :: Maybe Text,
    -- | Total processing time
    duration :: NominalDiffTime
  }
  deriving stock (Generic, Eq, Show)

-- | Main configuration for URL normalization
data NormConfig = NormConfig
  { -- | Redirect resolution settings
    redirects :: RedirectConfig,
    -- | Tracking parameter settings
    tracking :: TrackingConfig,
    -- | Whether to remove URL fragments (default: True)
    stripFragment :: Bool,
    -- | Whether to sort query parameters (default: True)
    sortParams :: Bool,
    -- | Trailing slash policy (default: Strip)
    trailingSlash :: TrailingSlash
  }
  deriving stock (Generic)

-- | Policy for handling trailing slashes in paths
data TrailingSlash
  = -- | Keep trailing slashes as-is
    Keep
  | -- | Remove trailing slashes
    Strip
  | -- | Add trailing slashes
    Add
  deriving stock (Generic, Eq, Show)

-- | Configuration for redirect resolution
data RedirectConfig = RedirectConfig
  { -- | Maximum number of redirects to follow (default: 10)
    maxRedirects :: Int,
    -- | Timeout per request in seconds (default: 10)
    timeout :: NominalDiffTime,
    -- | Allow HTTPS to HTTP downgrades (default: False)
    allowDowngrade :: Bool,
    -- | Block redirects to private IPs for SSRF protection (default: True)
    blockPrivateIPs :: Bool,
    -- | User-Agent header value
    userAgent :: Text
  }
  deriving stock (Generic)

-- | Configuration for tracking parameter removal
data TrackingConfig = TrackingConfig
  { -- | Patterns to match tracking parameters (supports * suffix wildcards)
    denyPatterns :: [Text],
    -- | Parameters to never strip, even if they match deny patterns
    allowlist :: Set Text
  }
  deriving stock (Generic)

-- | Hooks for observability during normalization
data NormHooks m = NormHooks
  { -- | Called for each redirect: (from, to)
    onRedirectStep :: URI -> URI -> m (),
    -- | Called when a domain rule is applied: (ruleName, before, after)
    onRuleApplied :: Text -> URI -> URI -> m (),
    -- | Called when normalization completes
    onNormComplete :: NormTrace -> m ()
  }
  deriving stock (Generic)
