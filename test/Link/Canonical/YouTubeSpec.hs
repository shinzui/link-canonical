module Link.Canonical.YouTubeSpec (tests) where

import Data.Maybe (fromJust)
import Data.Text qualified as T
import Link.Canonical (applyDomainRules, defaultDomainRules)
import Test.Tasty
import Test.Tasty.HUnit
import Text.URI (URI, mkURI, render)

tests :: TestTree
tests =
  testGroup
    "YouTube"
    [ testGroup
        "Video ID extraction"
        [ testCase "extracts from youtu.be short URL" $
            normalizeYT "https://youtu.be/dQw4w9WgXcQ"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          testCase "extracts from watch URL" $
            normalizeYT "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          testCase "extracts from embed URL" $
            normalizeYT "https://www.youtube.com/embed/dQw4w9WgXcQ"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          testCase "extracts from /v/ URL" $
            normalizeYT "https://www.youtube.com/v/dQw4w9WgXcQ"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          testCase "extracts from shorts URL" $
            normalizeYT "https://www.youtube.com/shorts/dQw4w9WgXcQ"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        ],
      testGroup
        "Host normalization"
        [ testCase "normalizes youtube.com (no www)" $
            normalizeYT "https://youtube.com/watch?v=dQw4w9WgXcQ"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          testCase "normalizes m.youtube.com" $
            normalizeYT "https://m.youtube.com/watch?v=dQw4w9WgXcQ"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        ],
      testGroup
        "Parameter stripping"
        [ testCase "strips timestamp parameter t" $
            normalizeYT "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          testCase "strips start parameter" $
            normalizeYT "https://youtu.be/dQw4w9WgXcQ?start=60"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          testCase "strips feature parameter" $
            normalizeYT "https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=youtu.be"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          testCase "strips list parameter" $
            normalizeYT "https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          testCase "strips si parameter" $
            normalizeYT "https://youtu.be/dQw4w9WgXcQ?si=abc123"
              @?= "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        ],
      testGroup
        "Non-YouTube URLs"
        [ testCase "leaves non-YouTube URLs unchanged" $
            let uri = parseURI "https://example.com/watch?v=abc123"
             in applyDomainRules defaultDomainRules uri @?= uri
        ]
    ]

-- | Helper to normalize a YouTube URL string and return the result as Text
normalizeYT :: Text -> Text
normalizeYT urlStr =
  let uri = parseURI urlStr
      normalized = applyDomainRules defaultDomainRules uri
   in render normalized

-- | Helper to parse a URI, failing the test if invalid
parseURI :: Text -> URI
parseURI s = fromJust $ mkURI s

type Text = T.Text
