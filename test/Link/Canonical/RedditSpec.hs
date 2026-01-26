module Link.Canonical.RedditSpec (tests) where

import Data.Maybe (fromJust)
import Data.Text qualified as T
import Link.Canonical (applyDomainRules, defaultDomainRules)
import Test.Tasty
import Test.Tasty.HUnit
import Text.URI (URI, mkURI, render)

tests :: TestTree
tests =
  testGroup
    "Reddit"
    [ testGroup
        "Host normalization"
        [ testCase "normalizes reddit.com to www.reddit.com" $
            normalizeReddit "https://reddit.com/r/haskell/comments/abc123/title/"
              @?= "https://www.reddit.com/r/haskell/comments/abc123/title/",
          testCase "normalizes old.reddit.com to www.reddit.com" $
            normalizeReddit "https://old.reddit.com/r/haskell/comments/abc123/title/"
              @?= "https://www.reddit.com/r/haskell/comments/abc123/title/",
          testCase "normalizes np.reddit.com to www.reddit.com" $
            normalizeReddit "https://np.reddit.com/r/haskell/comments/abc123/title/"
              @?= "https://www.reddit.com/r/haskell/comments/abc123/title/",
          testCase "keeps www.reddit.com as www.reddit.com" $
            normalizeReddit "https://www.reddit.com/r/haskell/comments/abc123/title/"
              @?= "https://www.reddit.com/r/haskell/comments/abc123/title/"
        ],
      testGroup
        "Post URLs"
        [ testCase "normalizes subreddit post URL" $
            normalizeReddit "https://old.reddit.com/r/programming/comments/xyz789/interesting_post/"
              @?= "https://www.reddit.com/r/programming/comments/xyz789/interesting_post/",
          testCase "preserves post URL path" $
            normalizeReddit "https://www.reddit.com/r/haskell/comments/abc123/my_title/"
              @?= "https://www.reddit.com/r/haskell/comments/abc123/my_title/"
        ],
      testGroup
        "User URLs"
        [ testCase "normalizes user profile URL" $
            normalizeReddit "https://old.reddit.com/user/someuser"
              @?= "https://www.reddit.com/user/someuser",
          testCase "preserves user URL path" $
            normalizeReddit "https://www.reddit.com/user/username/"
              @?= "https://www.reddit.com/user/username/"
        ],
      testGroup
        "Subreddit URLs"
        [ testCase "normalizes subreddit URL" $
            normalizeReddit "https://np.reddit.com/r/haskell"
              @?= "https://www.reddit.com/r/haskell",
          testCase "preserves subreddit URL path" $
            normalizeReddit "https://www.reddit.com/r/programming/"
              @?= "https://www.reddit.com/r/programming/"
        ],
      testGroup
        "Parameter stripping"
        [ testCase "strips ref parameter" $
            normalizeReddit "https://reddit.com/r/haskell/comments/abc/title/?ref=share"
              @?= "https://www.reddit.com/r/haskell/comments/abc/title/",
          testCase "strips ref_source parameter" $
            normalizeReddit "https://www.reddit.com/r/haskell/comments/abc/title/?ref_source=embed"
              @?= "https://www.reddit.com/r/haskell/comments/abc/title/",
          testCase "strips multiple tracking parameters" $
            normalizeReddit "https://old.reddit.com/r/haskell/?ref=share&ref_source=link"
              @?= "https://www.reddit.com/r/haskell/"
        ],
      testGroup
        "Non-Reddit URLs"
        [ testCase "leaves non-Reddit URLs unchanged" $
            let uri = parseURI "https://example.com/r/haskell/comments/abc/"
             in applyDomainRules defaultDomainRules uri @?= uri
        ]
    ]

-- | Helper to normalize a Reddit URL string and return the result as Text
normalizeReddit :: Text -> Text
normalizeReddit urlStr =
  let uri = parseURI urlStr
      normalized = applyDomainRules defaultDomainRules uri
   in render normalized

-- | Helper to parse a URI, failing the test if invalid
parseURI :: Text -> URI
parseURI s = fromJust $ mkURI s

type Text = T.Text
