-- | GitHub URL normalization rule
--
-- == Canonical Form
--
-- @
-- https://github.com/{owner}/{repo}[/path]
-- @
--
-- == Handled Variants
--
-- * @www.github.com@ → @github.com@
--
-- == Fragment Handling
--
-- Line number fragments are preserved (exception to default fragment stripping):
--
-- * @#L123@ - single line reference
-- * @#L10-L20@ - line range reference
--
-- == Stripped Parameters
--
-- @tab@, @ref_src@, @ref_source@
module Link.Canonical.Rules.GitHub
  ( githubRule,
    isGitHubUrl,
    githubStrippedParams,
    isLineFragment,
  )
where

import Data.Text qualified as T
import Link.Canonical.Prelude
import Link.Canonical.Rules.Types (DomainRule, domainRule, getHost)
import Text.URI qualified as URI

-- | GitHub domain rule
githubRule :: DomainRule
githubRule = domainRule "github" isGitHubUrl normalizeGitHub

-- | Parameters to strip from GitHub URLs
githubStrippedParams :: [Text]
githubStrippedParams =
  [ "tab", -- tab selection
    "ref_src", -- referral source
    "ref_source" -- referral source variant
  ]

-- | GitHub hostnames we recognize
githubHosts :: [Text]
githubHosts =
  [ "github.com",
    "www.github.com"
  ]

-- | Check if a URI is a GitHub URL
isGitHubUrl :: URI -> Bool
isGitHubUrl uri =
  case getHost uri of
    Nothing -> False
    Just host -> T.toLower host `elem` githubHosts

-- | Normalize a GitHub URL to canonical form
normalizeGitHub :: URI -> URI
normalizeGitHub uri =
  let -- Step 1: Normalize host to github.com (strip www)
      withHost = normalizeHost uri
      -- Step 2: Strip GitHub-specific tracking parameters
      withQuery = stripGitHubParams withHost
      -- Step 3: Handle fragment (preserve line numbers, strip others)
      withFragment = handleFragment withQuery
   in withFragment

-- | Normalize host to github.com (strip www.)
normalizeHost :: URI -> URI
normalizeHost uri =
  case URI.uriAuthority uri of
    Left _ -> uri
    Right auth ->
      let hostText = URI.unRText (URI.authHost auth)
       in if T.toLower hostText == "www.github.com"
            then case URI.mkHost "github.com" of
              Nothing -> uri
              Just newHost ->
                let newAuth = auth {URI.authHost = newHost}
                 in uri {URI.uriAuthority = Right newAuth}
            else uri

-- | Strip GitHub-specific tracking parameters
stripGitHubParams :: URI -> URI
stripGitHubParams uri =
  let params = URI.uriQuery uri
      filtered = filter (not . isGitHubTrackingParam) params
   in uri {URI.uriQuery = filtered}

-- | Check if a query parameter is a GitHub tracking parameter
isGitHubTrackingParam :: URI.QueryParam -> Bool
isGitHubTrackingParam (URI.QueryFlag k) =
  URI.unRText k `elem` githubStrippedParams
isGitHubTrackingParam (URI.QueryParam k _) =
  URI.unRText k `elem` githubStrippedParams

-- | Handle fragment: preserve line number references, strip others
--
-- Line number patterns:
-- * #L123 - single line
-- * #L10-L20 - line range
handleFragment :: URI -> URI
handleFragment uri =
  case URI.uriFragment uri of
    Nothing -> uri
    Just frag ->
      let fragText = URI.unRText frag
       in if isLineFragment fragText
            then uri -- Preserve line number fragment
            else uri {URI.uriFragment = Nothing} -- Strip other fragments

-- | Check if a fragment is a line number reference
--
-- Matches patterns like:
-- * L123
-- * L10-L20
-- * L1-20 (some tools use this format)
isLineFragment :: Text -> Bool
isLineFragment frag =
  let t = T.toUpper frag
   in -- Single line: L followed by digits
      (T.isPrefixOf "L" t && T.all isDigitOrDash (T.drop 1 t) && hasDigit (T.drop 1 t))
        -- Or starts with L and contains line range pattern
        || isLineRange t

-- | Check if text contains only digits and dashes
isDigitOrDash :: Char -> Bool
isDigitOrDash c = c >= '0' && c <= '9' || c == '-' || c == 'L'

-- | Check if text has at least one digit
hasDigit :: Text -> Bool
hasDigit = T.any (\c -> c >= '0' && c <= '9')

-- | Check if text is a line range pattern (L10-L20 or L10-20)
isLineRange :: Text -> Bool
isLineRange t =
  case T.breakOn "-" t of
    (before, after)
      | not (T.null after) ->
          T.isPrefixOf "L" before
            && hasDigit before
            && hasDigit (T.drop 1 after) -- drop the "-"
    _ -> False
