module Main (main) where

import Link.Canonical.NormalizeSpec qualified as NormalizeSpec
import Link.Canonical.TrackingSpec qualified as TrackingSpec
import Link.Canonical.YouTubeSpec qualified as YouTubeSpec
import Test.Tasty

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "link-canonical"
    [ NormalizeSpec.tests,
      TrackingSpec.tests,
      YouTubeSpec.tests
    ]
