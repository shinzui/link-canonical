module Main (main) where

import Link.Canonical.AmazonSpec qualified as AmazonSpec
import Link.Canonical.GitHubSpec qualified as GitHubSpec
import Link.Canonical.InstagramSpec qualified as InstagramSpec
import Link.Canonical.NormalizeSpec qualified as NormalizeSpec
import Link.Canonical.TrackingSpec qualified as TrackingSpec
import Link.Canonical.TwitterSpec qualified as TwitterSpec
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
      YouTubeSpec.tests,
      AmazonSpec.tests,
      TwitterSpec.tests,
      GitHubSpec.tests,
      InstagramSpec.tests
    ]
