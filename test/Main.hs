module Main (main) where

import Link.Canonical.AmazonSpec qualified as AmazonSpec
import Link.Canonical.EdgeCaseSpec qualified as EdgeCaseSpec
import Link.Canonical.GitHubSpec qualified as GitHubSpec
import Link.Canonical.InstagramSpec qualified as InstagramSpec
import Link.Canonical.NormalizeSpec qualified as NormalizeSpec
import Link.Canonical.RedditSpec qualified as RedditSpec
import Link.Canonical.RedirectSpec qualified as RedirectSpec
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
      RedirectSpec.tests,
      EdgeCaseSpec.tests,
      YouTubeSpec.tests,
      AmazonSpec.tests,
      TwitterSpec.tests,
      GitHubSpec.tests,
      InstagramSpec.tests,
      RedditSpec.tests
    ]
