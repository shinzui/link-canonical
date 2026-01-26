{-# LANGUAGE OverloadedStrings #-}

module Link.Canonical.NormalizeSpec (tests) where

import Data.Either (fromRight)
import Data.List.NonEmpty (NonEmpty (..))
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
        keys @?= ["a", "m", "z"],
      testGroup
        "Dot segment normalization"
        [ testCase "removes single dot segment" $ do
            let uri = unsafeParseURI "https://example.com/a/./b"
                result = normalizeUri defaultConfig [] uri
            getPath result @?= "/a/b",
          testCase "removes double dot segment" $ do
            let uri = unsafeParseURI "https://example.com/a/b/../c"
                result = normalizeUri defaultConfig [] uri
            getPath result @?= "/a/c",
          testCase "removes multiple dot segments" $ do
            let uri = unsafeParseURI "https://example.com/a/b/c/./../../g"
                result = normalizeUri defaultConfig [] uri
            getPath result @?= "/a/g",
          testCase "handles double dot at root" $ do
            let uri = unsafeParseURI "https://example.com/../foo"
                result = normalizeUri defaultConfig [] uri
            getPath result @?= "/foo",
          testCase "preserves normal path" $ do
            let uri = unsafeParseURI "https://example.com/a/b/c"
                result = normalizeUri defaultConfig [] uri
            getPath result @?= "/a/b/c"
        ]
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

getPath :: URI -> Text
getPath uri = case URI.uriPath uri of
  Nothing -> ""
  Just (trailing, segments) ->
    let segs = map URI.unRText (toList segments)
        path = "/" <> mconcat (intersperse "/" segs)
     in if trailing && not (null segs) && last segs /= ""
          then path <> "/"
          else path
  where
    intersperse _ [] = []
    intersperse _ [x] = [x]
    intersperse sep (x : xs) = x : sep : intersperse sep xs
    toList (x :| xs) = x : xs

getParamKey :: URI.QueryParam -> Text
getParamKey (URI.QueryFlag t) = URI.unRText t
getParamKey (URI.QueryParam k _) = URI.unRText k
