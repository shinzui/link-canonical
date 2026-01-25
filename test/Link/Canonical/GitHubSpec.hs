module Link.Canonical.GitHubSpec (tests) where

import Data.Maybe (fromJust)
import Data.Text qualified as T
import Link.Canonical (applyDomainRules, defaultDomainRules)
import Test.Tasty
import Test.Tasty.HUnit
import Text.URI (URI, mkURI, render)

tests :: TestTree
tests =
  testGroup
    "GitHub"
    [ testGroup
        "Host normalization"
        [ testCase "normalizes www.github.com to github.com" $
            normalizeGitHub "https://www.github.com/anthropics/claude-code"
              @?= "https://github.com/anthropics/claude-code",
          testCase "keeps github.com as github.com" $
            normalizeGitHub "https://github.com/anthropics/claude-code"
              @?= "https://github.com/anthropics/claude-code"
        ],
      testGroup
        "Fragment handling"
        [ testCase "preserves single line fragment #L123" $
            normalizeGitHub "https://github.com/owner/repo/blob/main/file.hs#L123"
              @?= "https://github.com/owner/repo/blob/main/file.hs#L123",
          testCase "preserves line range fragment #L10-L20" $
            normalizeGitHub "https://github.com/owner/repo/blob/main/file.hs#L10-L20"
              @?= "https://github.com/owner/repo/blob/main/file.hs#L10-L20",
          testCase "preserves line range fragment #L10-20" $
            normalizeGitHub "https://github.com/owner/repo/blob/main/file.hs#L10-20"
              @?= "https://github.com/owner/repo/blob/main/file.hs#L10-20",
          testCase "strips non-line fragments" $
            normalizeGitHub "https://github.com/owner/repo#readme"
              @?= "https://github.com/owner/repo",
          testCase "strips anchor fragments" $
            normalizeGitHub "https://github.com/owner/repo/blob/main/README.md#installation"
              @?= "https://github.com/owner/repo/blob/main/README.md"
        ],
      testGroup
        "Parameter stripping"
        [ testCase "strips tab parameter" $
            normalizeGitHub "https://github.com/owner/repo?tab=readme"
              @?= "https://github.com/owner/repo",
          testCase "strips ref_src parameter" $
            normalizeGitHub "https://github.com/owner/repo?ref_src=twitter"
              @?= "https://github.com/owner/repo",
          testCase "strips ref_source parameter" $
            normalizeGitHub "https://github.com/owner/repo?ref_source=email"
              @?= "https://github.com/owner/repo",
          testCase "strips multiple parameters" $
            normalizeGitHub "https://github.com/owner/repo?tab=code&ref_src=twitter"
              @?= "https://github.com/owner/repo"
        ],
      testGroup
        "Path preservation"
        [ testCase "preserves repo path" $
            normalizeGitHub "https://github.com/anthropics/claude-code"
              @?= "https://github.com/anthropics/claude-code",
          testCase "preserves file path" $
            normalizeGitHub "https://github.com/owner/repo/blob/main/src/Main.hs"
              @?= "https://github.com/owner/repo/blob/main/src/Main.hs",
          testCase "preserves issues path" $
            normalizeGitHub "https://github.com/owner/repo/issues/123"
              @?= "https://github.com/owner/repo/issues/123",
          testCase "preserves pull request path" $
            normalizeGitHub "https://github.com/owner/repo/pull/456"
              @?= "https://github.com/owner/repo/pull/456"
        ],
      testGroup
        "Non-GitHub URLs"
        [ testCase "leaves non-GitHub URLs unchanged" $
            let uri = parseURI "https://gitlab.com/owner/repo"
             in applyDomainRules defaultDomainRules uri @?= uri
        ]
    ]

-- | Helper to normalize a GitHub URL string and return the result as Text
normalizeGitHub :: Text -> Text
normalizeGitHub urlStr =
  let uri = parseURI urlStr
      normalized = applyDomainRules defaultDomainRules uri
   in render normalized

-- | Helper to parse a URI, failing the test if invalid
parseURI :: Text -> URI
parseURI s = fromJust $ mkURI s

type Text = T.Text
