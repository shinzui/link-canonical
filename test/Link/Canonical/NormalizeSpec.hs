{-# LANGUAGE OverloadedStrings #-}

module Link.Canonical.NormalizeSpec (tests) where

import Data.Either (fromRight)
import Data.Text (Text)
import Link.Canonical
import Test.Tasty
import Test.Tasty.HUnit
import Text.URI qualified as URI

tests :: TestTree
tests =
  testGroup
    "Normalize"
    [ testCase "normalizes scheme to lowercase" $ do
        let uri = unsafeParseURI "HTTP://example.com/path"
            result = normalizeUri defaultConfig [] uri
            scheme = URI.unRText <$> URI.uriScheme result
        scheme @?= Just "http",
      testCase "normalizes host to lowercase" $ do
        let uri = unsafeParseURI "https://EXAMPLE.COM/path"
            result = normalizeUri defaultConfig [] uri
        getHost result @?= Just "example.com",
      testCase "removes default port 80 for http" $ do
        let uri = unsafeParseURI "http://example.com:80/path"
            result = normalizeUri defaultConfig [] uri
        getPort result @?= Nothing,
      testCase "removes default port 443 for https" $ do
        let uri = unsafeParseURI "https://example.com:443/path"
            result = normalizeUri defaultConfig [] uri
        getPort result @?= Nothing,
      testCase "keeps non-default port" $ do
        let uri = unsafeParseURI "https://example.com:8080/path"
            result = normalizeUri defaultConfig [] uri
        getPort result @?= Just 8080,
      testCase "removes fragment by default" $ do
        let uri = unsafeParseURI "https://example.com/path#section"
            result = normalizeUri defaultConfig [] uri
        URI.uriFragment result @?= Nothing,
      testCase "sorts query parameters" $ do
        let uri = unsafeParseURI "https://example.com/?z=1&a=2&m=3"
            result = normalizeUri defaultConfig [] uri
            params = URI.uriQuery result
            keys = map getParamKey params
        keys @?= ["a", "m", "z"]
    ]

-- Helper functions

unsafeParseURI :: Text -> URI
unsafeParseURI t = fromRight (error $ "Failed to parse: " <> show t) $ URI.mkURI t

getHost :: URI -> Maybe Text
getHost uri = case URI.uriAuthority uri of
  Right auth -> Just $ URI.unRText $ URI.authHost auth
  _ -> Nothing

getPort :: URI -> Maybe Word
getPort uri = case URI.uriAuthority uri of
  Right auth -> URI.authPort auth
  _ -> Nothing

getParamKey :: URI.QueryParam -> Text
getParamKey (URI.QueryFlag t) = URI.unRText t
getParamKey (URI.QueryParam k _) = URI.unRText k
