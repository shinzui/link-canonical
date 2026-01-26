-- | Reddit URL normalization rule
--
-- == Canonical Form
--
-- @
-- https://www.reddit.com/r/{subreddit}/comments/{id}/{slug}/
-- https://www.reddit.com/user/{username}/
-- @
--
-- == Handled Variants
--
-- * @old.reddit.com@ → @www.reddit.com@
-- * @np.reddit.com@ → @www.reddit.com@
-- * @reddit.com@ → @www.reddit.com@
--
-- == Stripped Parameters
--
-- @ref@, @ref_source@
--
-- Note: @utm_*@ parameters are handled by the global tracking parameter stripping.
module Link.Canonical.Rules.Reddit
  ( redditRule,
    isRedditUrl,
    redditStrippedParams,
  )
where

import Data.Text qualified as T
import Link.Canonical.Prelude
import Link.Canonical.Rules.Types (DomainRule, domainRule, getHost)
import Text.URI qualified as URI

-- | Reddit domain rule
redditRule :: DomainRule
redditRule = domainRule "reddit" isRedditUrl normalizeReddit

-- | Parameters to strip from Reddit URLs
redditStrippedParams :: [Text]
redditStrippedParams =
  [ "ref", -- Reddit referral tracking
    "ref_source" -- Reddit referral source
  ]

-- | Reddit hostnames we recognize
redditHosts :: [Text]
redditHosts =
  [ "reddit.com",
    "www.reddit.com",
    "old.reddit.com",
    "np.reddit.com"
  ]

-- | Check if a URI is a Reddit URL
isRedditUrl :: URI -> Bool
isRedditUrl uri =
  case getHost uri of
    Nothing -> False
    Just host -> T.toLower host `elem` redditHosts

-- | Normalize a Reddit URL to canonical form
normalizeReddit :: URI -> URI
normalizeReddit uri =
  let -- Step 1: Normalize host to www.reddit.com
      withHost = normalizeHost uri
      -- Step 2: Strip Reddit-specific tracking parameters
      withQuery = stripRedditParams withHost
   in withQuery

-- | Normalize host to www.reddit.com
normalizeHost :: URI -> URI
normalizeHost uri =
  case URI.uriAuthority uri of
    Left _ -> uri
    Right auth ->
      let hostText = T.toLower (URI.unRText (URI.authHost auth))
       in if hostText `elem` ["reddit.com", "old.reddit.com", "np.reddit.com"]
            then case URI.mkHost "www.reddit.com" of
              Nothing -> uri
              Just newHost ->
                let newAuth = auth {URI.authHost = newHost}
                 in uri {URI.uriAuthority = Right newAuth}
            else uri

-- | Strip Reddit-specific tracking parameters
stripRedditParams :: URI -> URI
stripRedditParams uri =
  let params = URI.uriQuery uri
      filtered = filter (not . isRedditTrackingParam) params
   in uri {URI.uriQuery = filtered}

-- | Check if a query parameter is a Reddit tracking parameter
isRedditTrackingParam :: URI.QueryParam -> Bool
isRedditTrackingParam (URI.QueryFlag k) =
  URI.unRText k `elem` redditStrippedParams
isRedditTrackingParam (URI.QueryParam k _) =
  URI.unRText k `elem` redditStrippedParams
