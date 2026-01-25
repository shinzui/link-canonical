module Main (main) where

import Link.Canonical.NormalizeSpec qualified as NormalizeSpec
import Link.Canonical.TrackingSpec qualified as TrackingSpec
import Test.Tasty

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "link-canonical"
    [ NormalizeSpec.tests,
      TrackingSpec.tests
    ]
