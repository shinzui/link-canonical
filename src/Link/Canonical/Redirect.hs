module Link.Canonical.Redirect
  ( -- * Redirect resolution
    resolveFinalUri,
    resolveFinalUriWithChain,

    -- * Private IP detection
    isPrivateIP,

    -- * Helpers
    isRedirectStatus,
    isSuccessStatus,
    isSchemeDowngrade,
  )
where

import Data.Set qualified as Set
import Data.Text qualified as T
import Link.Canonical.Error (HttpClientError, RedirectError (..))
import Link.Canonical.Http (HttpClient (..), HttpResponse (..))
import Link.Canonical.Prelude
import Link.Canonical.Types (RedirectConfig (..))
import Network.HTTP.Types (Status, statusCode)
import Text.URI qualified as URI

-- | Resolve the final URI after following redirects
resolveFinalUri ::
  (HttpClient m, Monad m) =>
  RedirectConfig ->
  URI ->
  m (Either RedirectError URI)
resolveFinalUri config uri = do
  result <- resolveFinalUriWithChain config uri
  pure $ fmap fst result

-- | Resolve the final URI and return the redirect chain
resolveFinalUriWithChain ::
  (HttpClient m, Monad m) =>
  RedirectConfig ->
  URI ->
  m (Either RedirectError (URI, [URI]))
resolveFinalUriWithChain config uri = go Set.empty [] 0 uri
  where
    go visited chain depth current
      | depth > config ^. #maxRedirects =
          pure $ Left $ TooManyRedirects depth
      | current `Set.member` visited =
          pure $ Left $ RedirectLoop (reverse $ current : chain)
      | checkPrivateIP config current =
          pure $ Left $ PrivateIPBlocked (URI.render current)
      | otherwise = do
          response <- headRequest current
          case response of
            Left err -> pure $ Left $ ConnectionFailed $ showHttpError err
            Right hr ->
              let status = hr ^. #status
               in if isRedirectStatus status
                    then case hr ^. #location of
                      Nothing ->
                        pure $ Left $ InvalidLocation "Missing Location header"
                      Just loc -> do
                        -- Resolve relative redirects
                        let next = resolveRelative current loc
                        if checkDowngrade config current next
                          then pure $ Left $ SchemeDowngrade (URI.render current) (URI.render next)
                          else go (Set.insert current visited) (current : chain) (depth + 1) next
                    else
                      if isSuccessStatus status
                        then pure $ Right (current, reverse chain)
                        else pure $ Left $ HttpError status

    checkPrivateIP cfg u =
      (cfg ^. #blockPrivateIPs) && isPrivateIP u

    checkDowngrade cfg from to =
      not (cfg ^. #allowDowngrade) && isSchemeDowngrade from to

-- | Check if a status code is a redirect (3xx)
isRedirectStatus :: Status -> Bool
isRedirectStatus s =
  let code = statusCode s
   in code >= 300 && code < 400

-- | Check if a status code is a success (2xx)
isSuccessStatus :: Status -> Bool
isSuccessStatus s =
  let code = statusCode s
   in code >= 200 && code < 300

-- | Check if going from one URI to another is a scheme downgrade
isSchemeDowngrade :: URI -> URI -> Bool
isSchemeDowngrade from to =
  let fromScheme = fmap (T.toLower . URI.unRText) $ URI.uriScheme from
      toScheme = fmap (T.toLower . URI.unRText) $ URI.uriScheme to
   in fromScheme == Just "https" && toScheme == Just "http"

-- | Check if a URI points to a private IP address
--
-- Blocks common private IP patterns:
-- - 127.x.x.x (loopback)
-- - 10.x.x.x (private)
-- - 172.16-31.x.x (private)
-- - 192.168.x.x (private)
-- - 169.254.x.x (link-local)
-- - localhost
isPrivateIP :: URI -> Bool
isPrivateIP uri =
  case getHostText uri of
    Nothing -> False
    Just hostText ->
      let host = T.toLower hostText
       in host == "localhost"
            || "127." `T.isPrefixOf` host
            || "10." `T.isPrefixOf` host
            || "192.168." `T.isPrefixOf` host
            || "169.254." `T.isPrefixOf` host
            || isPrivate172 host
            || host == "::1"
            || "fc" `T.isPrefixOf` host
            || "fd" `T.isPrefixOf` host
            || "fe80:" `T.isPrefixOf` host

-- | Check for 172.16.0.0/12 range
isPrivate172 :: Text -> Bool
isPrivate172 host
  | "172." `T.isPrefixOf` host =
      case T.splitOn "." host of
        (_ : second : _) ->
          case reads (T.unpack second) :: [(Int, String)] of
            [(n, "")] -> n >= 16 && n <= 31
            _ -> False
        _ -> False
  | otherwise = False

-- | Get host text from URI
getHostText :: URI -> Maybe Text
getHostText uri =
  case URI.uriAuthority uri of
    Left _ -> Nothing -- No authority
    Right auth -> Just $ URI.unRText $ URI.authHost auth

-- | Resolve a relative URI against a base URI
resolveRelative :: URI -> URI -> URI
resolveRelative base relative =
  -- If relative has a scheme, it's absolute
  case URI.uriScheme relative of
    Just _ -> relative
    Nothing ->
      -- Copy scheme from base
      let withScheme = relative {URI.uriScheme = URI.uriScheme base}
       in case URI.uriAuthority relative of
            Right _ -> withScheme -- Has authority, use as-is
            _ ->
              -- Copy authority from base
              withScheme {URI.uriAuthority = URI.uriAuthority base}

-- | Show HTTP error as text
showHttpError :: HttpClientError -> Text
showHttpError err = T.pack $ show err
