module Link.Canonical.InstagramSpec (tests) where

import Data.Maybe (fromJust)
import Data.Text qualified as T
import Link.Canonical (applyDomainRules, defaultDomainRules)
import Test.Tasty
import Test.Tasty.HUnit
import Text.URI (URI, mkURI, render)

tests :: TestTree
tests =
  testGroup
    "Instagram"
    [ testGroup
        "Host normalization"
        [ testCase "normalizes instagram.com to www.instagram.com" $
            normalizeInstagram "https://instagram.com/p/ABC123/"
              @?= "https://www.instagram.com/p/ABC123/",
          testCase "keeps www.instagram.com as www.instagram.com" $
            normalizeInstagram "https://www.instagram.com/p/ABC123/"
              @?= "https://www.instagram.com/p/ABC123/"
        ],
      testGroup
        "Post URLs"
        [ testCase "normalizes post URL" $
            normalizeInstagram "https://instagram.com/p/CxYz123AbC/"
              @?= "https://www.instagram.com/p/CxYz123AbC/",
          testCase "preserves post URL path" $
            normalizeInstagram "https://www.instagram.com/p/ABC123/"
              @?= "https://www.instagram.com/p/ABC123/"
        ],
      testGroup
        "Reel URLs"
        [ testCase "normalizes reel URL" $
            normalizeInstagram "https://instagram.com/reel/CxYz123AbC/"
              @?= "https://www.instagram.com/reel/CxYz123AbC/",
          testCase "preserves reel URL path" $
            normalizeInstagram "https://www.instagram.com/reel/ABC123/"
              @?= "https://www.instagram.com/reel/ABC123/"
        ],
      testGroup
        "Profile URLs"
        [ testCase "normalizes profile URL" $
            normalizeInstagram "https://instagram.com/username/"
              @?= "https://www.instagram.com/username/",
          testCase "preserves profile URL path" $
            normalizeInstagram "https://www.instagram.com/username/"
              @?= "https://www.instagram.com/username/"
        ],
      testGroup
        "Parameter stripping"
        [ testCase "strips igshid parameter" $
            normalizeInstagram "https://instagram.com/p/ABC123/?igshid=YmMyMTA2M2Y"
              @?= "https://www.instagram.com/p/ABC123/",
          testCase "strips igshid from reel" $
            normalizeInstagram "https://www.instagram.com/reel/ABC123/?igshid=xyz"
              @?= "https://www.instagram.com/reel/ABC123/",
          testCase "strips igshid from profile" $
            normalizeInstagram "https://instagram.com/username?igshid=abc123"
              @?= "https://www.instagram.com/username"
        ],
      testGroup
        "Non-Instagram URLs"
        [ testCase "leaves non-Instagram URLs unchanged" $
            let uri = parseURI "https://example.com/p/ABC123/"
             in applyDomainRules defaultDomainRules uri @?= uri
        ]
    ]

-- | Helper to normalize an Instagram URL string and return the result as Text
normalizeInstagram :: Text -> Text
normalizeInstagram urlStr =
  let uri = parseURI urlStr
      normalized = applyDomainRules defaultDomainRules uri
   in render normalized

-- | Helper to parse a URI, failing the test if invalid
parseURI :: Text -> URI
parseURI s = fromJust $ mkURI s

type Text = T.Text
