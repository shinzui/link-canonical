module Link.Canonical.Error
  ( -- * Main error type
    NormError (..),

    -- * Redirect errors
    RedirectError (..),

    -- * HTTP client errors
    HttpClientError (..),
  )
where

import Link.Canonical.Prelude
import Network.HTTP.Types (Status)

-- | Errors that can occur during URL normalization
data NormError
  = -- | Failed to parse the input URL
    ParseError Text
  | -- | URL scheme is not http or https
    UnsupportedScheme Text
  | -- | Error during redirect resolution
    RedirectError RedirectError
  | -- | Error applying domain rule
    DomainRuleError Text
  deriving stock (Generic, Eq, Show)

-- | Errors that can occur during redirect resolution
data RedirectError
  = -- | Exceeded maximum redirect depth
    TooManyRedirects Int
  | -- | Detected a redirect loop
    RedirectLoop [URI]
  | -- | Request timed out
    RedirectTimeout
  | -- | Redirect target is a private IP address (SSRF protection)
    PrivateIPBlocked Text
  | -- | HTTPS to HTTP downgrade detected
    SchemeDowngrade Text Text
  | -- | Network connection failed
    ConnectionFailed Text
  | -- | Invalid or missing Location header
    InvalidLocation Text
  | -- | Non-redirect, non-success HTTP status
    HttpError Status
  deriving stock (Generic, Eq, Show)

-- | Errors from the HTTP client layer
data HttpClientError
  = -- | Network connection error
    ConnectionError Text
  | -- | Request timed out
    TimeoutError
  | -- | TLS/SSL error
    TlsError Text
  | -- | Invalid URI provided
    InvalidUri Text
  deriving stock (Generic, Eq, Show)
