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
    amazonRule,
    twitterRule,
    githubRule,
    instagramRule,
    redditRule,
  )
where

import Link.Canonical.Rules.Amazon (amazonRule)
import Link.Canonical.Rules.GitHub (githubRule)
import Link.Canonical.Rules.Instagram (instagramRule)
import Link.Canonical.Rules.Reddit (redditRule)
import Link.Canonical.Rules.Twitter (twitterRule)
import Link.Canonical.Rules.Types
import Link.Canonical.Rules.YouTube (youtubeRule)

-- | Default set of domain rules
--
-- Rules are applied in order; first match wins.
--
-- Included rules:
-- - YouTube (youtu.be, youtube.com variants)
-- - Amazon (amazon.* regional variants)
-- - Twitter/X (twitter.com → x.com)
-- - GitHub (www.github.com → github.com, preserves line fragments)
-- - Instagram (instagram.com → www.instagram.com)
-- - Reddit (old.reddit.com, np.reddit.com → www.reddit.com)
--
-- Planned rules:
-- - LinkedIn
defaultDomainRules :: [DomainRule]
defaultDomainRules =
  [ youtubeRule,
    amazonRule,
    twitterRule,
    githubRule,
    instagramRule,
    redditRule
  ]
