module Link.Canonical.Rules.Types
  ( -- * Domain rule types
    DomainRule (..),

    -- * Constructors
    domainRule,

    -- * Application
    applyDomainRules,
    applyDomainRulesWithTrace,

    -- * Helpers
    matchesHost,
    matchesAnyHost,
    getHost,
  )
where

import Data.Text qualified as T
import Link.Canonical.Prelude
import Text.URI qualified as URI

-- | A domain-specific normalization rule
--
-- Rules are applied in order; the first matching rule wins.
data DomainRule = DomainRule
  { -- | Unique identifier for this rule (for debugging/tracing)
    name :: Text,
    -- | Predicate to test if this rule applies to a URI
    match :: URI -> Bool,
    -- | Transform the URI to its canonical form
    apply :: URI -> URI
  }
  deriving stock (Generic)

-- | Convenience constructor for domain rules
domainRule ::
  -- | Rule name
  Text ->
  -- | Match predicate
  (URI -> Bool) ->
  -- | Transformation function
  (URI -> URI) ->
  DomainRule
domainRule n m a =
  DomainRule
    { name = n,
      match = m,
      apply = a
    }

-- | Apply domain rules to a URI
--
-- Returns the URI transformed by the first matching rule,
-- or the original URI if no rules match.
applyDomainRules :: [DomainRule] -> URI -> URI
applyDomainRules rules uri =
  case find (\r -> (r ^. #match) uri) rules of
    Nothing -> uri
    Just r -> (r ^. #apply) uri

-- | Apply domain rules and return which rule was applied
applyDomainRulesWithTrace :: [DomainRule] -> URI -> (URI, Maybe Text)
applyDomainRulesWithTrace rules uri =
  case find (\r -> (r ^. #match) uri) rules of
    Nothing -> (uri, Nothing)
    Just r -> ((r ^. #apply) uri, Just (r ^. #name))

-- | Check if a URI's host matches the given hostname
matchesHost :: Text -> URI -> Bool
matchesHost hostname uri =
  case getHost uri of
    Nothing -> False
    Just h -> T.toLower h == T.toLower hostname

-- | Check if a URI's host matches any of the given hostnames
matchesAnyHost :: [Text] -> URI -> Bool
matchesAnyHost hostnames uri = any (`matchesHost` uri) hostnames

-- | Extract the host from a URI as Text
getHost :: URI -> Maybe Text
getHost uri =
  case URI.uriAuthority uri of
    Left _ -> Nothing -- URI has no authority
    Right auth -> Just $ URI.unRText $ URI.authHost auth
