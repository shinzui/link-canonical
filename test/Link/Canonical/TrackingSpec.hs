{-# LANGUAGE OverloadedStrings #-}

module Link.Canonical.TrackingSpec (tests) where

import Data.Either (fromRight)
import Data.Set qualified as Set
import Data.Text (Text)
import Link.Canonical
import Test.Tasty
import Test.Tasty.HUnit
import Text.URI qualified as URI

tests :: TestTree
tests =
  testGroup
    "Tracking"
    [ testCase "strips utm_source parameter" $ do
        let uri = unsafeParseURI "https://example.com/?utm_source=twitter&id=123"
            result = normalizeUri defaultConfig [] uri
            keys = getParamKeys result
        keys @?= ["id"],
      testCase "strips utm_* parameters" $ do
        let uri = unsafeParseURI "https://example.com/?utm_source=x&utm_medium=y&utm_campaign=z&id=1"
            result = normalizeUri defaultConfig [] uri
            keys = getParamKeys result
        keys @?= ["id"],
      testCase "strips fbclid parameter" $ do
        let uri = unsafeParseURI "https://example.com/?fbclid=abc123&page=1"
            result = normalizeUri defaultConfig [] uri
            keys = getParamKeys result
        keys @?= ["page"],
      testCase "strips gclid parameter" $ do
        let uri = unsafeParseURI "https://example.com/?gclid=xyz&page=1"
            result = normalizeUri defaultConfig [] uri
            keys = getParamKeys result
        keys @?= ["page"],
      testCase "respects allowlist" $ do
        let config =
              defaultConfig
                { tracking =
                    TrackingConfig
                      { denyPatterns = ["ref"],
                        allowlist = Set.fromList ["ref"]
                      }
                }
            uri = unsafeParseURI "https://example.com/?ref=affiliate&id=1"
            result = normalizeUri config [] uri
            keys = getParamKeys result
        -- ref should be kept because it's in the allowlist
        keys @?= ["id", "ref"],
      testCase "pattern matching with wildcard" $ do
        let uri = unsafeParseURI "https://example.com/?mc_cid=abc&mc_eid=def&id=1"
            result = normalizeUri defaultConfig [] uri
            keys = getParamKeys result
        -- mc_* should match both mc_cid and mc_eid
        keys @?= ["id"],
      testCase "preserves non-tracking parameters" $ do
        let uri = unsafeParseURI "https://example.com/?page=1&sort=desc&filter=active"
            result = normalizeUri defaultConfig [] uri
            keys = getParamKeys result
        keys @?= ["filter", "page", "sort"],
      testGroup
        "Additional tracking patterns"
        [ testCase "strips _ga and _gl (Google Analytics)" $ do
            let uri = unsafeParseURI "https://example.com/?_ga=1.2.3&_gl=abc&id=1"
                result = normalizeUri defaultConfig [] uri
                keys = getParamKeys result
            keys @?= ["id"],
          testCase "strips msclkid (Microsoft Ads)" $ do
            let uri = unsafeParseURI "https://example.com/?msclkid=abc123&page=1"
                result = normalizeUri defaultConfig [] uri
                keys = getParamKeys result
            keys @?= ["page"],
          testCase "strips dclid (DoubleClick)" $ do
            let uri = unsafeParseURI "https://example.com/?dclid=xyz789&id=1"
                result = normalizeUri defaultConfig [] uri
                keys = getParamKeys result
            keys @?= ["id"],
          testCase "strips oly_* (Omeda)" $ do
            let uri = unsafeParseURI "https://example.com/?oly_anon_id=abc&oly_enc_id=def&id=1"
                result = normalizeUri defaultConfig [] uri
                keys = getParamKeys result
            keys @?= ["id"],
          testCase "strips zanpid (Zanox)" $ do
            let uri = unsafeParseURI "https://example.com/?zanpid=123456&page=1"
                result = normalizeUri defaultConfig [] uri
                keys = getParamKeys result
            keys @?= ["page"],
          testCase "strips igshid (Instagram)" $ do
            let uri = unsafeParseURI "https://example.com/?igshid=abc123&post=1"
                result = normalizeUri defaultConfig [] uri
                keys = getParamKeys result
            keys @?= ["post"],
          testCase "strips si (Spotify)" $ do
            let uri = unsafeParseURI "https://example.com/?si=abc123def&track=1"
                result = normalizeUri defaultConfig [] uri
                keys = getParamKeys result
            keys @?= ["track"],
          testCase "strips twclid (Twitter)" $ do
            let uri = unsafeParseURI "https://example.com/?twclid=abc&id=1"
                result = normalizeUri defaultConfig [] uri
                keys = getParamKeys result
            keys @?= ["id"],
          testCase "strips hsa_* (HubSpot)" $ do
            let uri = unsafeParseURI "https://example.com/?hsa_cam=123&hsa_grp=456&id=1"
                result = normalizeUri defaultConfig [] uri
                keys = getParamKeys result
            keys @?= ["id"],
          testCase "strips mkt_tok (Marketo)" $ do
            let uri = unsafeParseURI "https://example.com/?mkt_tok=abc123&page=1"
                result = normalizeUri defaultConfig [] uri
                keys = getParamKeys result
            keys @?= ["page"]
        ]
    ]

-- Helper functions

unsafeParseURI :: Text -> URI
unsafeParseURI t = fromRight (error $ "Failed to parse: " <> show t) $ URI.mkURI t

getParamKeys :: URI -> [Text]
getParamKeys uri = map getParamKey $ URI.uriQuery uri

getParamKey :: URI.QueryParam -> Text
getParamKey (URI.QueryFlag t) = URI.unRText t
getParamKey (URI.QueryParam k _) = URI.unRText k
