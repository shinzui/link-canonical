module Link.Canonical.Tracking
  ( -- * Tracking parameter removal
    stripTrackingParams,
    stripTrackingParamsWithTrace,

    -- * Pattern matching
    matchesTrackingPattern,
    isTrackingParam,
  )
where

import Data.Set qualified as Set
import Data.Text qualified as T
import Link.Canonical.Prelude
import Link.Canonical.Types (TrackingConfig (..))
import Text.URI qualified as URI

-- | Strip tracking parameters from a URI
stripTrackingParams :: TrackingConfig -> URI -> URI
stripTrackingParams config uri = fst $ stripTrackingParamsWithTrace config uri

-- | Strip tracking parameters and return which ones were removed
stripTrackingParamsWithTrace :: TrackingConfig -> URI -> (URI, [Text])
stripTrackingParamsWithTrace config uri =
  case URI.uriQuery uri of
    [] -> (uri, [])
    params ->
      let (kept, stripped) = partitionParams config params
          newUri = uri {URI.uriQuery = kept}
       in (newUri, stripped)

-- | Partition query parameters into kept and stripped
partitionParams :: TrackingConfig -> [URI.QueryParam] -> ([URI.QueryParam], [Text])
partitionParams config params =
  let (kept, stripped) = foldr go ([], []) params
   in (kept, stripped)
  where
    go param (k, s) =
      let paramName = getParamName param
       in if isTrackingParam config paramName
            then (k, paramName : s)
            else (param : k, s)

-- | Get the name of a query parameter
getParamName :: URI.QueryParam -> Text
getParamName (URI.QueryFlag t) = URI.unRText t
getParamName (URI.QueryParam k _) = URI.unRText k

-- | Check if a parameter name matches any tracking pattern
isTrackingParam :: TrackingConfig -> Text -> Bool
isTrackingParam config paramName =
  let lowerParam = T.toLower paramName
   in -- Check allowlist first
      if Set.member lowerParam (Set.map T.toLower $ config ^. #allowlist)
        then False
        else -- Then check deny patterns
          any (`matchesTrackingPattern` lowerParam) (config ^. #denyPatterns)

-- | Check if a parameter name matches a tracking pattern
--
-- Patterns support suffix wildcards:
-- - @"utm_*"@ matches @"utm_source"@, @"utm_medium"@, etc.
-- - @"gclid"@ matches only @"gclid"@ exactly
matchesTrackingPattern :: Text -> Text -> Bool
matchesTrackingPattern pat param
  | "*" `T.isSuffixOf` pat =
      let prefix = T.toLower $ T.init pat
       in prefix `T.isPrefixOf` T.toLower param
  | otherwise = T.toLower pat == T.toLower param
