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
  )
where

import Link.Canonical.Prelude
import Link.Canonical.Rules.Types

-- | Default set of domain rules
--
-- Currently empty; domain-specific rules will be added in future versions.
-- Rules are applied in order; first match wins.
--
-- Planned rules:
-- - YouTube (youtu.be, youtube.com variants)
-- - Amazon (amzn.to, amazon.* variants)
-- - Twitter/X (twitter.com → x.com)
-- - Instagram
-- - Reddit
-- - LinkedIn
-- - GitHub
defaultDomainRules :: [DomainRule]
defaultDomainRules = []
