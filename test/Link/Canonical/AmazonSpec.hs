module Link.Canonical.AmazonSpec (tests) where

import Data.Maybe (fromJust)
import Data.Text qualified as T
import Link.Canonical (applyDomainRules, defaultDomainRules)
import Test.Tasty
import Test.Tasty.HUnit
import Text.URI (URI, mkURI, render)

tests :: TestTree
tests =
  testGroup
    "Amazon"
    [ testGroup
        "ASIN extraction"
        [ testCase "extracts from /dp/{ASIN}" $
            normalizeAmazon "https://www.amazon.com/dp/B08N5WRWNW"
              @?= "https://www.amazon.com/dp/B08N5WRWNW",
          testCase "extracts from /gp/product/{ASIN}" $
            normalizeAmazon "https://www.amazon.com/gp/product/B08N5WRWNW"
              @?= "https://www.amazon.com/dp/B08N5WRWNW",
          testCase "extracts from /{product-name}/dp/{ASIN}" $
            normalizeAmazon "https://www.amazon.com/Apple-AirPods-Charging-Latest-Model/dp/B07PXGQC1Q"
              @?= "https://www.amazon.com/dp/B07PXGQC1Q",
          testCase "handles complex product paths" $
            normalizeAmazon "https://www.amazon.com/Some-Product-Name-Here/dp/B08N5WRWNW/ref=sr_1_1"
              @?= "https://www.amazon.com/dp/B08N5WRWNW"
        ],
      testGroup
        "Host normalization"
        [ testCase "normalizes amazon.com (no www)" $
            normalizeAmazon "https://amazon.com/dp/B08N5WRWNW"
              @?= "https://www.amazon.com/dp/B08N5WRWNW",
          testCase "normalizes smile.amazon.com" $
            normalizeAmazon "https://smile.amazon.com/dp/B08N5WRWNW"
              @?= "https://www.amazon.com/dp/B08N5WRWNW"
        ],
      testGroup
        "Regional TLD preservation"
        [ testCase "preserves amazon.co.uk" $
            normalizeAmazon "https://www.amazon.co.uk/dp/B08N5WRWNW"
              @?= "https://www.amazon.co.uk/dp/B08N5WRWNW",
          testCase "preserves amazon.de" $
            normalizeAmazon "https://www.amazon.de/dp/B08N5WRWNW"
              @?= "https://www.amazon.de/dp/B08N5WRWNW",
          testCase "preserves amazon.co.jp" $
            normalizeAmazon "https://www.amazon.co.jp/dp/B08N5WRWNW"
              @?= "https://www.amazon.co.jp/dp/B08N5WRWNW",
          testCase "preserves amazon.ca" $
            normalizeAmazon "https://amazon.ca/gp/product/B08N5WRWNW"
              @?= "https://www.amazon.ca/dp/B08N5WRWNW"
        ],
      testGroup
        "Parameter stripping"
        [ testCase "strips tag parameter" $
            normalizeAmazon "https://www.amazon.com/dp/B08N5WRWNW?tag=affiliate-20"
              @?= "https://www.amazon.com/dp/B08N5WRWNW",
          testCase "strips ref parameter" $
            normalizeAmazon "https://www.amazon.com/dp/B08N5WRWNW?ref=sr_1_1"
              @?= "https://www.amazon.com/dp/B08N5WRWNW",
          testCase "strips multiple parameters" $
            normalizeAmazon "https://www.amazon.com/dp/B08N5WRWNW?tag=foo&ref=bar&qid=123"
              @?= "https://www.amazon.com/dp/B08N5WRWNW"
        ],
      testGroup
        "Non-Amazon URLs"
        [ testCase "leaves non-Amazon URLs unchanged" $
            let uri = parseURI "https://example.com/dp/B08N5WRWNW"
             in applyDomainRules defaultDomainRules uri @?= uri
        ]
    ]

-- | Helper to normalize an Amazon URL string and return the result as Text
normalizeAmazon :: Text -> Text
normalizeAmazon urlStr =
  let uri = parseURI urlStr
      normalized = applyDomainRules defaultDomainRules uri
   in render normalized

-- | Helper to parse a URI, failing the test if invalid
parseURI :: Text -> URI
parseURI s = fromJust $ mkURI s

type Text = T.Text
