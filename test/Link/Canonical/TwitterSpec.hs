module Link.Canonical.TwitterSpec (tests) where

import Data.Maybe (fromJust)
import Data.Text qualified as T
import Link.Canonical (applyDomainRules, defaultDomainRules)
import Test.Tasty
import Test.Tasty.HUnit
import Text.URI (URI, mkURI, render)

tests :: TestTree
tests =
  testGroup
    "Twitter/X"
    [ testGroup
        "Host normalization"
        [ testCase "normalizes twitter.com to x.com" $
            normalizeTwitter "https://twitter.com/elikiw/status/1234567890"
              @?= "https://x.com/elikiw/status/1234567890",
          testCase "normalizes www.twitter.com to x.com" $
            normalizeTwitter "https://www.twitter.com/elikiw/status/1234567890"
              @?= "https://x.com/elikiw/status/1234567890",
          testCase "normalizes mobile.twitter.com to x.com" $
            normalizeTwitter "https://mobile.twitter.com/elikiw/status/1234567890"
              @?= "https://x.com/elikiw/status/1234567890",
          testCase "keeps x.com as x.com" $
            normalizeTwitter "https://x.com/elikiw/status/1234567890"
              @?= "https://x.com/elikiw/status/1234567890"
        ],
      testGroup
        "Media suffix stripping"
        [ testCase "strips /photo/1 from status URL" $
            normalizeTwitter "https://twitter.com/elikiw/status/1234567890/photo/1"
              @?= "https://x.com/elikiw/status/1234567890",
          testCase "strips /photo/2 from status URL" $
            normalizeTwitter "https://x.com/elikiw/status/1234567890/photo/2"
              @?= "https://x.com/elikiw/status/1234567890",
          testCase "strips /video/1 from status URL" $
            normalizeTwitter "https://twitter.com/elikiw/status/1234567890/video/1"
              @?= "https://x.com/elikiw/status/1234567890"
        ],
      testGroup
        "Parameter stripping"
        [ testCase "strips s parameter" $
            normalizeTwitter "https://twitter.com/elikiw/status/1234567890?s=20"
              @?= "https://x.com/elikiw/status/1234567890",
          testCase "strips t parameter" $
            normalizeTwitter "https://x.com/elikiw/status/1234567890?t=abc123"
              @?= "https://x.com/elikiw/status/1234567890",
          testCase "strips ref_src parameter" $
            normalizeTwitter "https://twitter.com/elikiw/status/1234567890?ref_src=twsrc"
              @?= "https://x.com/elikiw/status/1234567890",
          testCase "strips multiple parameters" $
            normalizeTwitter "https://twitter.com/elikiw/status/1234567890?s=20&t=abc"
              @?= "https://x.com/elikiw/status/1234567890"
        ],
      testGroup
        "Profile URLs"
        [ testCase "normalizes profile URL" $
            normalizeTwitter "https://twitter.com/elikiw"
              @?= "https://x.com/elikiw",
          testCase "normalizes profile URL with trailing slash" $
            normalizeTwitter "https://twitter.com/elikiw/"
              @?= "https://x.com/elikiw/"
        ],
      testGroup
        "Non-Twitter URLs"
        [ testCase "leaves non-Twitter URLs unchanged" $
            let uri = parseURI "https://example.com/elikiw/status/123"
             in applyDomainRules defaultDomainRules uri @?= uri
        ]
    ]

-- | Helper to normalize a Twitter URL string and return the result as Text
normalizeTwitter :: Text -> Text
normalizeTwitter urlStr =
  let uri = parseURI urlStr
      normalized = applyDomainRules defaultDomainRules uri
   in render normalized

-- | Helper to parse a URI, failing the test if invalid
parseURI :: Text -> URI
parseURI s = fromJust $ mkURI s

type Text = T.Text
