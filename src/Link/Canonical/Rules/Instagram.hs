-- | Instagram URL normalization rule
--
-- == Canonical Forms
--
-- @
-- https://www.instagram.com/p/{POST_ID}/
-- https://www.instagram.com/reel/{REEL_ID}/
-- https://www.instagram.com/{username}/
-- @
--
-- == Handled Variants
--
-- * @instagram.com@ → @www.instagram.com@
--
-- == Stripped Parameters
--
-- @igshid@ (Instagram share ID)
--
-- Note: @utm_*@ parameters are handled by the global tracking parameter stripping.
module Link.Canonical.Rules.Instagram
  ( instagramRule,
    isInstagramUrl,
    instagramStrippedParams,
  )
where

import Data.Text qualified as T
import Link.Canonical.Prelude
import Link.Canonical.Rules.Types (DomainRule, domainRule, getHost)
import Text.URI qualified as URI

-- | Instagram domain rule
instagramRule :: DomainRule
instagramRule = domainRule "instagram" isInstagramUrl normalizeInstagram

-- | Parameters to strip from Instagram URLs
instagramStrippedParams :: [Text]
instagramStrippedParams =
  [ "igshid" -- Instagram share ID
  ]

-- | Instagram hostnames we recognize
instagramHosts :: [Text]
instagramHosts =
  [ "instagram.com",
    "www.instagram.com"
  ]

-- | Check if a URI is an Instagram URL
isInstagramUrl :: URI -> Bool
isInstagramUrl uri =
  case getHost uri of
    Nothing -> False
    Just host -> T.toLower host `elem` instagramHosts

-- | Normalize an Instagram URL to canonical form
normalizeInstagram :: URI -> URI
normalizeInstagram uri =
  let -- Step 1: Normalize host to www.instagram.com
      withHost = normalizeHost uri
      -- Step 2: Strip Instagram-specific tracking parameters
      withQuery = stripInstagramParams withHost
   in withQuery

-- | Normalize host to www.instagram.com
normalizeHost :: URI -> URI
normalizeHost uri =
  case URI.uriAuthority uri of
    Left _ -> uri
    Right auth ->
      let hostText = URI.unRText (URI.authHost auth)
       in if T.toLower hostText == "instagram.com"
            then case URI.mkHost "www.instagram.com" of
              Nothing -> uri
              Just newHost ->
                let newAuth = auth {URI.authHost = newHost}
                 in uri {URI.uriAuthority = Right newAuth}
            else uri

-- | Strip Instagram-specific tracking parameters
stripInstagramParams :: URI -> URI
stripInstagramParams uri =
  let params = URI.uriQuery uri
      filtered = filter (not . isInstagramTrackingParam) params
   in uri {URI.uriQuery = filtered}

-- | Check if a query parameter is an Instagram tracking parameter
isInstagramTrackingParam :: URI.QueryParam -> Bool
isInstagramTrackingParam (URI.QueryFlag k) =
  URI.unRText k `elem` instagramStrippedParams
isInstagramTrackingParam (URI.QueryParam k _) =
  URI.unRText k `elem` instagramStrippedParams
