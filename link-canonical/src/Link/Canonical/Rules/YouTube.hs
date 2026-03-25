-- | YouTube URL normalization rule
--
-- == Canonical Form
--
-- @
-- https://www.youtube.com/watch?v={VIDEO_ID}
-- @
--
-- == Handled Variants
--
-- * @youtu.be/{VIDEO_ID}@
-- * @youtube.com/watch?v={VIDEO_ID}@
-- * @www.youtube.com/watch?v={VIDEO_ID}@
-- * @m.youtube.com/watch?v={VIDEO_ID}@
-- * @youtube.com/embed/{VIDEO_ID}@
-- * @youtube.com/v/{VIDEO_ID}@
-- * @youtube.com/shorts/{VIDEO_ID}@
--
-- == Stripped Parameters
--
-- @t@, @start@, @end@, @feature@, @list@, @index@, @si@
--
-- Note: Timestamps are stripped per the resource-identity semantic model.
module Link.Canonical.Rules.YouTube
  ( youtubeRule,
    isYouTubeUrl,
    extractVideoId,
    youtubeStrippedParams,
  )
where

import Data.List.NonEmpty qualified as NE
import Data.Text qualified as T
import Link.Canonical.Prelude
import Link.Canonical.Rules.Types (DomainRule, domainRule, getHost)
import Text.URI qualified as URI

-- | YouTube domain rule
youtubeRule :: DomainRule
youtubeRule = domainRule "youtube" isYouTubeUrl normalizeYouTube

-- | Parameters to strip from YouTube URLs
youtubeStrippedParams :: [Text]
youtubeStrippedParams =
  [ "t", -- timestamp
    "start", -- start time
    "end", -- end time
    "feature", -- feature flag
    "list", -- playlist
    "index", -- playlist index
    "si" -- share identifier
  ]

-- | YouTube hostnames we recognize
youtubeHosts :: [Text]
youtubeHosts =
  [ "youtube.com",
    "www.youtube.com",
    "m.youtube.com",
    "youtu.be"
  ]

-- | Check if a URI is a YouTube URL
isYouTubeUrl :: URI -> Bool
isYouTubeUrl uri =
  case getHost uri of
    Nothing -> False
    Just host -> T.toLower host `elem` youtubeHosts

-- | Normalize a YouTube URL to canonical form
normalizeYouTube :: URI -> URI
normalizeYouTube uri =
  case extractVideoId uri of
    Nothing -> uri -- Can't extract video ID, return as-is
    Just videoId -> buildCanonicalYouTube videoId

-- | Extract the video ID from various YouTube URL formats
extractVideoId :: URI -> Maybe Text
extractVideoId uri = do
  host <- getHost uri
  let lowerHost = T.toLower host
  if lowerHost == "youtu.be"
    then extractFromShortUrl uri
    else extractFromLongUrl uri

-- | Extract video ID from youtu.be/{VIDEO_ID}
extractFromShortUrl :: URI -> Maybe Text
extractFromShortUrl uri = do
  (_, pathSegments) <- URI.uriPath uri
  -- First path segment is the video ID
  let segments = NE.toList pathSegments
  case segments of
    (firstSeg : _) ->
      let videoId = URI.unRText firstSeg
       in if T.null videoId then Nothing else Just videoId
    [] -> Nothing

-- | Extract video ID from youtube.com URLs
extractFromLongUrl :: URI -> Maybe Text
extractFromLongUrl uri =
  -- Try each extraction method in order
  extractFromWatchParam uri
    <|> extractFromEmbed uri
    <|> extractFromV uri
    <|> extractFromShorts uri

-- | Extract from ?v={VIDEO_ID}
extractFromWatchParam :: URI -> Maybe Text
extractFromWatchParam uri =
  let params = URI.uriQuery uri
   in findParamValue "v" params

-- | Extract from /embed/{VIDEO_ID}
extractFromEmbed :: URI -> Maybe Text
extractFromEmbed = extractFromPathPrefix "embed"

-- | Extract from /v/{VIDEO_ID}
extractFromV :: URI -> Maybe Text
extractFromV = extractFromPathPrefix "v"

-- | Extract from /shorts/{VIDEO_ID}
extractFromShorts :: URI -> Maybe Text
extractFromShorts = extractFromPathPrefix "shorts"

-- | Extract video ID from path like /{prefix}/{VIDEO_ID}
extractFromPathPrefix :: Text -> URI -> Maybe Text
extractFromPathPrefix prefix uri = do
  (_, pathSegments) <- URI.uriPath uri
  let segments = NE.toList pathSegments
  case segments of
    (firstSeg : secondSeg : _)
      | T.toLower (URI.unRText firstSeg) == prefix ->
          let videoId = URI.unRText secondSeg
           in if T.null videoId then Nothing else Just videoId
    _ -> Nothing

-- | Find a parameter value in query params
findParamValue :: Text -> [URI.QueryParam] -> Maybe Text
findParamValue key params =
  listToMaybe $ mapMaybe extractValue params
  where
    extractValue (URI.QueryParam k v)
      | URI.unRText k == key = Just (URI.unRText v)
    extractValue _ = Nothing

-- | Build the canonical YouTube URL
buildCanonicalYouTube :: Text -> URI
buildCanonicalYouTube videoId =
  -- We construct the URI manually since we know the exact format
  case URI.mkURI ("https://www.youtube.com/watch?v=" <> videoId) of
    Just uri -> uri
    Nothing ->
      -- Fallback: this shouldn't happen with valid video IDs
      -- but we need a safe fallback
      URI.emptyURI
