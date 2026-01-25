module Link.Canonical.Rules
  ( -- * Domain rule types
    DomainRule (..),
    domainRule,

    -- * Application
    applyDomainRules,
    applyDomainRulesWithTrace,

    -- * Helpers
    matchesHost,
    matchesAnyHost,
    getHost,

    -- * Default rules
    defaultDomainRules,

    -- * Individual rules
    youtubeRule,
  )
where

import Link.Canonical.Rules.Types
import Link.Canonical.Rules.YouTube (youtubeRule)

-- | Default set of domain rules
--
-- Rules are applied in order; first match wins.
--
-- Included rules:
-- - YouTube (youtu.be, youtube.com variants)
--
-- Planned rules:
-- - Amazon (amzn.to, amazon.* variants)
-- - Twitter/X (twitter.com → x.com)
-- - Instagram
-- - Reddit
-- - LinkedIn
-- - GitHub
defaultDomainRules :: [DomainRule]
defaultDomainRules =
  [ youtubeRule
  ]
