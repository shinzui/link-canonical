module Main (main) where

import Data.Map.Strict qualified as Map
import Data.String (fromString)
import Effectful
import Effectful.Dispatch.Dynamic (interpret)
import Effectful.Link.Canonical
import GHC.Records (HasField (..))
import Link.Canonical.Http (HttpResponse (..))
import Network.HTTP.Types (mkStatus)
import Test.Tasty
import Test.Tasty.HUnit

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "link-canonical-effectful"
    [ testGroup "normalizeLink" normalizeLinkTests,
      testGroup "normalizeWithDefaults" normalizeWithDefaultsTests,
      testGroup "error handling" errorTests
    ]

-- | Mock HTTP handler backed by a URI -> HttpResponse map.
-- URIs not in the map return a ConnectionError.
runMockHttpHead :: Map.Map URI HttpResponse -> Eff (HttpHead : es) a -> Eff es a
runMockHttpHead responses = interpret $ \_ -> \case
  HeadRequest uri -> pure $ case Map.lookup uri responses of
    Just resp -> Right resp
    Nothing -> Left (ConnectionError "Mock: unknown URI")

-- | Helper to parse a URI, crashing on failure (test-only).
unsafeMkURI :: String -> URI
unsafeMkURI s = case mkURI (fromString s) of
  Right u -> u
  Left e -> error $ "unsafeMkURI: " <> show e

-- | A 200 OK response with no location header.
ok200 :: HttpResponse
ok200 =
  HttpResponse
    { status = mkStatus 200 "OK",
      location = Nothing,
      headers = []
    }

-- | A 301 redirect response pointing to the given URI.
redirect301 :: URI -> HttpResponse
redirect301 target =
  HttpResponse
    { status = mkStatus 301 "Moved Permanently",
      location = Just target,
      headers = []
    }

normalizeLinkTests :: [TestTree]
normalizeLinkTests =
  [ testCase "YouTube short URL is canonicalized" $ do
      let youtubeShort = unsafeMkURI "https://youtu.be/dQw4w9WgXcQ"
          youtubeCanonical = unsafeMkURI "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
          mockResponses = Map.singleton youtubeShort ok200
      result <-
        runEff
          . runMockHttpHead mockResponses
          . runLinkCanonical
          $ normalizeLink defaultConfig youtubeShort
      case result of
        Left err -> assertFailure $ "Expected Right, got Left: " <> show err
        Right normResult -> getField @"canonical" normResult @?= youtubeCanonical,
    testCase "tracking parameters are stripped" $ do
      let input = unsafeMkURI "https://example.com/page?utm_source=share&utm_medium=social&keep=yes"
          expected = unsafeMkURI "https://example.com/page?keep=yes"
          mockResponses = Map.singleton input ok200
      result <-
        runEff
          . runMockHttpHead mockResponses
          . runLinkCanonical
          $ normalizeLink defaultConfig input
      case result of
        Left err -> assertFailure $ "Expected Right, got Left: " <> show err
        Right normResult -> getField @"canonical" normResult @?= expected,
    testCase "redirect chain is followed" $ do
      let uriA = unsafeMkURI "https://short.link/abc"
          uriB = unsafeMkURI "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
          youtubeCanonical = unsafeMkURI "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
          mockResponses =
            Map.fromList
              [ (uriA, redirect301 uriB),
                (uriB, ok200)
              ]
      result <-
        runEff
          . runMockHttpHead mockResponses
          . runLinkCanonical
          $ normalizeLink defaultConfig uriA
      case result of
        Left err -> assertFailure $ "Expected Right, got Left: " <> show err
        Right normResult -> do
          getField @"canonical" normResult @?= youtubeCanonical
          getField @"redirectsCount" normResult @?= 1
  ]

normalizeWithDefaultsTests :: [TestTree]
normalizeWithDefaultsTests =
  [ testCase "returns canonical URI directly" $ do
      let input = unsafeMkURI "https://youtu.be/dQw4w9WgXcQ"
          expected = unsafeMkURI "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
          mockResponses = Map.singleton input ok200
      result <-
        runEff
          . runMockHttpHead mockResponses
          . runLinkCanonical
          $ normalizeWithDefaults input
      case result of
        Left err -> assertFailure $ "Expected Right, got Left: " <> show err
        Right uri -> uri @?= expected
  ]

errorTests :: [TestTree]
errorTests =
  [ testCase "connection error is propagated" $ do
      let input = unsafeMkURI "https://unknown.example.com/page"
          mockResponses = Map.empty :: Map.Map URI HttpResponse
      result <-
        runEff
          . runMockHttpHead mockResponses
          . runLinkCanonical
          $ normalizeLink defaultConfig input
      case result of
        Left _ -> pure ()
        Right _ -> assertFailure "Expected Left (error), got Right"
  ]
