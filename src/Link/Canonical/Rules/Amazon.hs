-- | Amazon URL normalization rule
--
-- == Canonical Form
--
-- @
-- https://www.amazon.{TLD}/dp/{ASIN}
-- @
--
-- Regional TLDs are preserved (e.g., amazon.co.uk, amazon.de).
--
-- == Handled Variants
--
-- * @amazon.com/dp/{ASIN}@
-- * @www.amazon.com/dp/{ASIN}@
-- * @amazon.com/gp/product/{ASIN}@
-- * @amazon.com/{product-name}/dp/{ASIN}@
-- * @smile.amazon.com/...@ (Amazon Smile)
--
-- Note: @amzn.to@ short URLs require redirect resolution and are
-- handled by the redirect phase, not this rule.
--
-- == Stripped Parameters
--
-- @tag@, @ref@, @psc@, @keywords@, @qid@, @sr@, @th@, @linkCode@, @camp@, @creative@
module Link.Canonical.Rules.Amazon
  ( amazonRule,
    isAmazonUrl,
    extractAsin,
    amazonStrippedParams,
  )
where

import Data.List (findIndex)
import Data.List.NonEmpty qualified as NE
import Data.Text qualified as T
import Link.Canonical.Prelude
import Link.Canonical.Rules.Types (DomainRule, domainRule, getHost)
import Text.URI qualified as URI

-- | Amazon domain rule
amazonRule :: DomainRule
amazonRule = domainRule "amazon" isAmazonUrl normalizeAmazon

-- | Parameters to strip from Amazon URLs
amazonStrippedParams :: [Text]
amazonStrippedParams =
  [ "tag", -- affiliate tag
    "ref", -- referral
    "psc", -- product selection
    "keywords", -- search keywords
    "qid", -- query ID
    "sr", -- search rank
    "th", -- variation selector
    "linkCode", -- affiliate link code
    "camp", -- campaign
    "creative" -- creative ID
  ]

-- | Amazon TLDs we recognize
amazonTlds :: [Text]
amazonTlds =
  [ "amazon.com",
    "amazon.co.uk",
    "amazon.de",
    "amazon.fr",
    "amazon.it",
    "amazon.es",
    "amazon.ca",
    "amazon.co.jp",
    "amazon.com.au",
    "amazon.com.br",
    "amazon.com.mx",
    "amazon.nl",
    "amazon.sg",
    "amazon.ae",
    "amazon.sa",
    "amazon.in",
    "amazon.se",
    "amazon.pl",
    "amazon.com.tr",
    "amazon.eg"
  ]

-- | Check if a URI is an Amazon URL
isAmazonUrl :: URI -> Bool
isAmazonUrl uri =
  case getHost uri of
    Nothing -> False
    Just host ->
      let lowerHost = T.toLower host
          -- Strip www. or smile. prefix if present
          baseHost = stripSubdomain lowerHost
       in baseHost `elem` amazonTlds

-- | Strip common subdomains (www., smile.)
stripSubdomain :: Text -> Text
stripSubdomain host
  | "www." `T.isPrefixOf` host = T.drop 4 host
  | "smile." `T.isPrefixOf` host = T.drop 6 host
  | otherwise = host

-- | Normalize an Amazon URL to canonical form
normalizeAmazon :: URI -> URI
normalizeAmazon uri =
  case extractAsin uri of
    Nothing -> uri -- Can't extract ASIN, return as-is
    Just asinId -> buildCanonicalAmazon uri asinId

-- | Extract the ASIN from various Amazon URL formats
--
-- ASINs are 10-character alphanumeric identifiers.
extractAsin :: URI -> Maybe Text
extractAsin uri = do
  (_, pathSegments) <- URI.uriPath uri
  let segments = NE.toList pathSegments
      segTexts = map URI.unRText segments
  extractAsinFromPath segTexts

-- | Extract ASIN from path segments
--
-- Handles:
-- * /dp/{ASIN}
-- * /gp/product/{ASIN}
-- * /{product-name}/dp/{ASIN}
extractAsinFromPath :: [Text] -> Maybe Text
extractAsinFromPath segments =
  extractFromDp segments
    <|> extractFromGpProduct segments

-- | Extract from /dp/{ASIN} or /{name}/dp/{ASIN}
extractFromDp :: [Text] -> Maybe Text
extractFromDp segments =
  case findDpIndex segments of
    Nothing -> Nothing
    Just idx ->
      let afterDp = drop (idx + 1) segments
       in case afterDp of
            (asinId : _) -> validateAsin asinId
            [] -> Nothing

-- | Find the index of "dp" in the path
findDpIndex :: [Text] -> Maybe Int
findDpIndex segments =
  findIndex (\s -> T.toLower s == "dp") segments

-- | Extract from /gp/product/{ASIN}
extractFromGpProduct :: [Text] -> Maybe Text
extractFromGpProduct segments =
  case segments of
    (gp : prod : asinId : _)
      | T.toLower gp == "gp" && T.toLower prod == "product" ->
          validateAsin asinId
    _ -> Nothing

-- | Validate that a string looks like an ASIN
--
-- ASINs are 10 characters, alphanumeric (usually start with B0 for products)
validateAsin :: Text -> Maybe Text
validateAsin candidate =
  let cleaned = T.takeWhile isAsinChar candidate
   in if T.length cleaned == 10 && T.all isAsinChar cleaned
        then Just cleaned
        else Nothing

-- | Check if a character is valid in an ASIN
isAsinChar :: Char -> Bool
isAsinChar c = (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')

-- | Build the canonical Amazon URL
--
-- Preserves the regional TLD from the original URL.
buildCanonicalAmazon :: URI -> Text -> URI
buildCanonicalAmazon originalUri asinId =
  let tld = getAmazonTld originalUri
      canonicalUrl = "https://www.amazon." <> tld <> "/dp/" <> asinId
   in case URI.mkURI canonicalUrl of
        Just uri -> uri
        Nothing -> originalUri -- Fallback to original if construction fails

-- | Get the TLD portion of an Amazon URL
--
-- e.g., "amazon.co.uk" -> "co.uk", "amazon.com" -> "com"
getAmazonTld :: URI -> Text
getAmazonTld uri =
  case getHost uri of
    Nothing -> "com" -- Default fallback
    Just host ->
      let baseHost = stripSubdomain (T.toLower host)
       in case T.stripPrefix "amazon." baseHost of
            Just tld -> tld
            Nothing -> "com" -- Default fallback
