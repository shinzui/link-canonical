-- | Twitter/X URL normalization rule
--
-- == Canonical Form
--
-- @
-- https://x.com/{user}/status/{id}
-- @
--
-- == Handled Variants
--
-- * @twitter.com@ → @x.com@
-- * @www.twitter.com@ → @x.com@
-- * @mobile.twitter.com@ → @x.com@
-- * @x.com/{user}/status/{id}/photo/1@ → @x.com/{user}/status/{id}@
-- * @x.com/{user}/status/{id}/video/1@ → @x.com/{user}/status/{id}@
--
-- == Stripped Parameters
--
-- @s@, @t@, @ref_src@
module Link.Canonical.Rules.Twitter
  ( twitterRule,
    isTwitterUrl,
    twitterStrippedParams,
  )
where

import Data.List.NonEmpty qualified as NE
import Data.Text qualified as T
import Link.Canonical.Prelude
import Link.Canonical.Rules.Types (DomainRule, domainRule, getHost)
import Text.URI qualified as URI

-- | Twitter/X domain rule
twitterRule :: DomainRule
twitterRule = domainRule "twitter" isTwitterUrl normalizeTwitter

-- | Parameters to strip from Twitter URLs
twitterStrippedParams :: [Text]
twitterStrippedParams =
  [ "s", -- share source
    "t", -- timestamp/token
    "ref_src" -- referral source
  ]

-- | Twitter/X hostnames we recognize
twitterHosts :: [Text]
twitterHosts =
  [ "twitter.com",
    "www.twitter.com",
    "mobile.twitter.com",
    "x.com",
    "www.x.com"
  ]

-- | Check if a URI is a Twitter/X URL
isTwitterUrl :: URI -> Bool
isTwitterUrl uri =
  case getHost uri of
    Nothing -> False
    Just host -> T.toLower host `elem` twitterHosts

-- | Normalize a Twitter/X URL to canonical form
normalizeTwitter :: URI -> URI
normalizeTwitter uri =
  let -- Step 1: Normalize host to x.com
      withHost = normalizeHost uri
      -- Step 2: Strip media suffixes from status URLs
      withPath = stripMediaSuffix withHost
      -- Step 3: Strip Twitter-specific tracking parameters
      withQuery = stripTwitterParams withPath
   in withQuery

-- | Strip Twitter-specific tracking parameters
stripTwitterParams :: URI -> URI
stripTwitterParams uri =
  let params = URI.uriQuery uri
      filtered = filter (not . isTwitterTrackingParam) params
   in uri {URI.uriQuery = filtered}

-- | Check if a query parameter is a Twitter tracking parameter
isTwitterTrackingParam :: URI.QueryParam -> Bool
isTwitterTrackingParam (URI.QueryFlag k) =
  URI.unRText k `elem` twitterStrippedParams
isTwitterTrackingParam (URI.QueryParam k _) =
  URI.unRText k `elem` twitterStrippedParams

-- | Normalize host to x.com
normalizeHost :: URI -> URI
normalizeHost uri =
  case URI.uriAuthority uri of
    Left _ -> uri
    Right auth ->
      case URI.mkHost "x.com" of
        Nothing -> uri
        Just newHost ->
          let newAuth = auth {URI.authHost = newHost}
           in uri {URI.uriAuthority = Right newAuth}

-- | Strip /photo/N or /video/N suffixes from status URLs
--
-- Converts:
--   /{user}/status/{id}/photo/1 → /{user}/status/{id}
--   /{user}/status/{id}/video/1 → /{user}/status/{id}
stripMediaSuffix :: URI -> URI
stripMediaSuffix uri =
  case URI.uriPath uri of
    Nothing -> uri
    Just (trailing, segments) ->
      let segList = NE.toList segments
          newSegList = stripMediaFromPath segList
       in case newSegList of
            [] -> uri {URI.uriPath = Nothing}
            (x : xs) -> uri {URI.uriPath = Just (trailing, x NE.:| xs)}

-- | Strip photo/video segments from path
--
-- If path ends with /photo/N or /video/N, remove those segments
stripMediaFromPath :: [URI.RText 'URI.PathPiece] -> [URI.RText 'URI.PathPiece]
stripMediaFromPath segments =
  let segTexts = map URI.unRText segments
   in if isStatusWithMedia segTexts
        then take (length segments - 2) segments
        else segments

-- | Check if path is a status URL with media suffix
--
-- Pattern: /{user}/status/{id}/photo|video/{N}
isStatusWithMedia :: [Text] -> Bool
isStatusWithMedia segs =
  case segs of
    (_ : status : _ : mediaType : _ : _)
      | T.toLower status == "status"
          && (T.toLower mediaType == "photo" || T.toLower mediaType == "video") ->
          True
    _ -> False
