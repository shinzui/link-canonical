module Link.Canonical.Http
  ( -- * HTTP Client typeclass
    HttpClient (..),

    -- * Response types
    HttpResponse (..),

    -- * Default implementation
    HttpClientIO (..),
    newHttpClientIO,
    runHttpClientIO,
  )
where

import Data.ByteString qualified as BS
import Data.CaseInsensitive qualified as CI
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Link.Canonical.Error (HttpClientError (..))
import Link.Canonical.Prelude
import Network.HTTP.Client qualified as HC
import Network.HTTP.Client.TLS qualified as TLS
import Network.HTTP.Types (Status)
import Text.URI qualified as URI

-- | HTTP response with only the data needed for redirect resolution
data HttpResponse = HttpResponse
  { -- | HTTP status code
    status :: Status,
    -- | Parsed Location header (for redirects)
    location :: Maybe URI,
    -- | Response headers as text pairs
    headers :: [(Text, Text)]
  }
  deriving stock (Generic, Eq, Show)

-- | Typeclass for HTTP clients
--
-- This abstraction allows for:
-- - Testing with mock clients
-- - Alternative HTTP backends
-- - Custom logging/metrics
class (Monad m) => HttpClient m where
  -- | Perform a HEAD request (efficient for redirect resolution)
  headRequest :: URI -> m (Either HttpClientError HttpResponse)

-- | Default HTTP client implementation using http-client-tls
newtype HttpClientIO = HttpClientIO
  { manager :: HC.Manager
  }
  deriving stock (Generic)

-- | Create a new HTTP client with TLS support
newHttpClientIO :: (MonadIO m) => m HttpClientIO
newHttpClientIO = liftIO $ HttpClientIO <$> TLS.newTlsManager

-- | Run an HTTP request with the given client
runHttpClientIO :: HttpClientIO -> URI -> IO (Either HttpClientError HttpResponse)
runHttpClientIO client uri = do
  let uriText = URI.render uri
      uriString = T.unpack uriText
  catchHttpException $ do
    request <- HC.parseRequest uriString
    let headRequest' = request {HC.method = "HEAD"}
    response <- HC.httpNoBody headRequest' (client ^. #manager)
    let respStatus = HC.responseStatus response
        respHeaders = HC.responseHeaders response
        locationHeader = lookup (CI.mk "Location") respHeaders
        parsedLocation = locationHeader >>= parseLocationHeader
        textHeaders = [(decodeHeader $ CI.original k, decodeHeader v) | (k, v) <- respHeaders]
    pure $
      Right $
        HttpResponse
          { status = respStatus,
            location = parsedLocation,
            headers = textHeaders
          }
  where
    parseLocationHeader bs =
      either (const Nothing) Just $ URI.mkURI $ decodeHeader bs

    decodeHeader :: BS.ByteString -> Text
    decodeHeader = TE.decodeUtf8Lenient

    catchHttpException :: IO (Either HttpClientError HttpResponse) -> IO (Either HttpClientError HttpResponse)
    catchHttpException action =
      action `catch` \case
        HC.HttpExceptionRequest _ (HC.ConnectionFailure _) ->
          pure $ Left $ ConnectionError "Connection failed"
        HC.HttpExceptionRequest _ HC.ConnectionTimeout ->
          pure $ Left TimeoutError
        HC.InvalidUrlException url reason ->
          pure $ Left $ InvalidUri $ "Invalid URL: " <> T.pack url <> " - " <> T.pack reason
        e ->
          pure $ Left $ ConnectionError $ "HTTP error: " <> T.pack (show e)

instance HttpClient IO where
  headRequest uri = do
    client <- newHttpClientIO
    runHttpClientIO client uri
