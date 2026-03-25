module Link.Canonical.Normalize
  ( -- * Pure normalization
    normalizeUri,
    normalizeUriWithTrace,

    -- * Individual normalization steps
    normalizeScheme,
    normalizeHost,
    normalizePort,
    normalizePath,
    normalizeQuery,
    stripFragment,
  )
where

import Data.List qualified as L
import Data.List.NonEmpty (NonEmpty (..))
import Data.Text qualified as T
import Link.Canonical.Prelude
import Link.Canonical.Rules.Types (DomainRule, applyDomainRulesWithTrace)
import Link.Canonical.Tracking (stripTrackingParamsWithTrace)
import Link.Canonical.Types
import Text.URI qualified as URI

-- | Normalize a URI using the given configuration
--
-- This performs generic normalization (scheme, host, port, path, query, fragment)
-- followed by domain-specific rules, then a final pass to strip any tracking
-- parameters that domain rules may have introduced.
normalizeUri :: NormConfig -> [DomainRule] -> URI -> URI
normalizeUri config rules uri = fst3 $ normalizeUriWithTrace config rules uri
  where
    fst3 (a, _, _) = a

-- | Normalize a URI and return trace information
normalizeUriWithTrace :: NormConfig -> [DomainRule] -> URI -> (URI, Maybe Text, [Text])
normalizeUriWithTrace config rules uri =
  let -- Step 1: Generic normalization
      genericNormalized = applyGenericNormalization config uri

      -- Step 2: Domain-specific rules
      (afterDomain, ruleApplied) = applyDomainRulesWithTrace rules genericNormalized

      -- Step 3: Final pass - strip tracking params (domain rules might introduce them)
      (final, strippedParams) = stripTrackingParamsWithTrace (config ^. #tracking) afterDomain
   in (final, ruleApplied, strippedParams)

-- | Apply all generic normalization steps
applyGenericNormalization :: NormConfig -> URI -> URI
applyGenericNormalization config =
  normalizeScheme
    . normalizeHost
    . normalizePort
    . normalizePath (config ^. #trailingSlash)
    . normalizeQuery config
    . applyFragmentPolicy config

-- | Normalize the URI scheme to lowercase
normalizeScheme :: URI -> URI
normalizeScheme uri =
  case URI.uriScheme uri of
    Nothing -> uri
    Just scheme ->
      let schemeText = URI.unRText scheme
          lowerScheme = T.toLower schemeText
       in if schemeText == lowerScheme
            then uri
            else case URI.mkScheme lowerScheme of
              Nothing -> uri
              Just newScheme -> uri {URI.uriScheme = Just newScheme}

-- | Normalize the host to lowercase
normalizeHost :: URI -> URI
normalizeHost uri =
  case URI.uriAuthority uri of
    Left _ -> uri -- No authority present
    Right auth ->
      let host = URI.authHost auth
          hostText = URI.unRText host
          lowerHost = T.toLower hostText
       in if hostText == lowerHost
            then uri
            else case URI.mkHost lowerHost of
              Nothing -> uri
              Just newHost ->
                let newAuth = auth {URI.authHost = newHost}
                 in uri {URI.uriAuthority = Right newAuth}

-- | Remove default ports (80 for http, 443 for https)
normalizePort :: URI -> URI
normalizePort uri =
  case (URI.uriScheme uri, URI.uriAuthority uri) of
    (Just scheme, Right auth) ->
      let schemeText = T.toLower $ URI.unRText scheme
          port = URI.authPort auth
       in case port of
            Nothing -> uri
            Just p ->
              let isDefault =
                    (schemeText == "http" && p == 80)
                      || (schemeText == "https" && p == 443)
               in if isDefault
                    then uri {URI.uriAuthority = Right (auth {URI.authPort = Nothing})}
                    else uri
    _ -> uri

-- | Normalize the path
normalizePath :: TrailingSlash -> URI -> URI
normalizePath policy uri =
  let path = URI.uriPath uri
      -- Normalize path segments (remove dot segments would go here)
      normalized = normalizeDotSegments path
      -- Apply trailing slash policy
      withPolicy = applyTrailingSlashPolicy policy normalized
   in uri {URI.uriPath = withPolicy}

-- | Remove dot segments from path (. and ..)
--
-- Implements RFC 3986 Section 5.2.4
--
-- Examples:
-- @
-- /a/b/c/./../../g  →  /a/g
-- /mid/content=5/../6  →  /mid/6
-- /../foo  →  /foo
-- @
normalizeDotSegments :: Maybe (Bool, NonEmpty (URI.RText 'URI.PathPiece)) -> Maybe (Bool, NonEmpty (URI.RText 'URI.PathPiece))
normalizeDotSegments Nothing = Nothing
normalizeDotSegments (Just (trailing, segments)) =
  let segList = toList segments
      segTexts = map URI.unRText segList
      -- Process dot segments
      processed = removeDotSegments [] segTexts
      -- Determine if result should have trailing slash
      -- If the last segment was "." or "..", result needs trailing slash
      lastWasDot = case segTexts of
        [] -> False
        xs -> L.last xs `elem` [".", ".."]
      newTrailing = trailing || lastWasDot
   in case processed of
        [] -> Nothing
        (x : xs) -> case traverse URI.mkPathPiece (x :| xs) of
          Nothing -> Just (trailing, segments) -- fallback to original if creation fails
          Just newSegs -> Just (newTrailing, newSegs)

-- | Remove dot segments following RFC 3986 algorithm
--
-- Processes segments left-to-right:
-- - "." segments are skipped (removed)
-- - ".." segments pop the last segment from the output
-- - Other segments are added to the output
removeDotSegments :: [Text] -> [Text] -> [Text]
removeDotSegments output [] = reverse output
removeDotSegments output (seg : rest)
  | seg == "." = removeDotSegments output rest
  | seg == ".." = case output of
      [] -> removeDotSegments [] rest -- can't go above root
      (_ : xs) -> removeDotSegments xs rest
  | otherwise = removeDotSegments (seg : output) rest

-- | Apply trailing slash policy to path
applyTrailingSlashPolicy :: TrailingSlash -> Maybe (Bool, NonEmpty (URI.RText 'URI.PathPiece)) -> Maybe (Bool, NonEmpty (URI.RText 'URI.PathPiece))
applyTrailingSlashPolicy Keep path = path
applyTrailingSlashPolicy Strip path =
  case path of
    Just (_, segments) ->
      -- Check if last segment is empty (trailing slash)
      let segList = toList segments
       in case segList of
            [] -> path
            _ ->
              let lastSeg = URI.unRText $ L.last segList
               in if T.null lastSeg
                    then case L.init segList of
                      [] -> Nothing
                      (x : xs) -> Just (True, x :| xs)
                    else path
    Nothing -> Nothing
applyTrailingSlashPolicy Add path =
  case path of
    Just (trailing, segments) ->
      if trailing
        then path -- already has trailing
        else case URI.mkPathPiece "" of
          Nothing -> path
          Just emptyPiece -> Just (True, segments <> (emptyPiece :| []))
    Nothing -> Nothing

-- | Normalize query parameters
normalizeQuery :: NormConfig -> URI -> URI
normalizeQuery config uri =
  let params = URI.uriQuery uri
      -- Sort parameters if configured
      sorted =
        if config ^. #sortParams
          then sortOn getParamKey params
          else params
      -- Strip tracking parameters
      (stripped, _) = stripTrackingParamsWithTrace (config ^. #tracking) (uri {URI.uriQuery = sorted})
   in stripped

-- | Get the key of a query parameter for sorting
getParamKey :: URI.QueryParam -> Text
getParamKey (URI.QueryFlag t) = URI.unRText t
getParamKey (URI.QueryParam k _) = URI.unRText k

-- | Apply fragment stripping policy
applyFragmentPolicy :: NormConfig -> URI -> URI
applyFragmentPolicy config uri =
  if config ^. #stripFragment
    then uri {URI.uriFragment = Nothing}
    else uri

-- | Remove the fragment from a URI
stripFragment :: URI -> URI
stripFragment uri = uri {URI.uriFragment = Nothing}
