module Link.Canonical.Config
  ( -- * Default configurations
    defaultConfig,
    defaultRedirectConfig,
    defaultTrackingConfig,

    -- * Tracking parameters
    defaultTrackingParams,
  )
where

import Data.Set qualified as Set
import Link.Canonical.Prelude
import Link.Canonical.Types

-- | Default normalization configuration
defaultConfig :: NormConfig
defaultConfig =
  NormConfig
    { redirects = defaultRedirectConfig,
      tracking = defaultTrackingConfig,
      stripFragment = True,
      sortParams = True,
      trailingSlash = Strip
    }

-- | Default redirect configuration
defaultRedirectConfig :: RedirectConfig
defaultRedirectConfig =
  RedirectConfig
    { maxRedirects = 10,
      timeout = 10, -- seconds
      allowDowngrade = False,
      blockPrivateIPs = True,
      userAgent = "link-canonical/0.1"
    }

-- | Default tracking parameter configuration
defaultTrackingConfig :: TrackingConfig
defaultTrackingConfig =
  TrackingConfig
    { denyPatterns = defaultTrackingParams,
      allowlist = Set.empty
    }

-- | Default list of tracking parameter patterns
--
-- Supports suffix wildcards with @*@, e.g., @"utm_*"@ matches @"utm_source"@, @"utm_medium"@, etc.
defaultTrackingParams :: [Text]
defaultTrackingParams =
  [ -- Google Analytics
    "utm_*",
    "_ga",
    "_gl",
    "_gid",
    -- Google Ads
    "gclid",
    "gclsrc",
    "dclid",
    -- Facebook
    "fbclid",
    "fb_action_ids",
    "fb_action_types",
    "fb_source",
    "fb_ref",
    -- Microsoft
    "msclkid",
    -- Mailchimp
    "mc_*",
    -- HubSpot
    "hsa_*",
    "_hsenc",
    "_hsmi",
    -- Omeda
    "oly_*",
    -- Marketo
    "mkt_tok",
    -- Instagram
    "igshid",
    "ig_*",
    -- Twitter/X
    "twclid",
    -- Spotify
    "si",
    -- Generic tracking
    "ref",
    "ref_src",
    "ref_source",
    "source",
    "campaign",
    -- Zanox
    "zanpid",
    -- Adobe
    "sc_*",
    "icid",
    -- Misc
    "trk",
    "trk_*",
    "tracking",
    "affiliate",
    "affiliate_id"
  ]
