{-# OPTIONS_GHC -Wno-orphans #-}

module Effectful.Link.Canonical.Http
  ( -- * Effect
    HttpHead (..),

    -- * Operations
    headRequest,

    -- * Handlers
    runHttpHead,
  )
where

import Effectful
import Effectful.Dispatch.Dynamic
import Link.Canonical.Error (HttpClientError (..))
import Link.Canonical.Http qualified as Core
import Text.URI (URI)

-- | Effect for performing HTTP HEAD requests.
--
-- This mirrors the core library's 'Core.HttpClient' typeclass as an
-- effectful effect, enabling mock handlers for testing.
data HttpHead :: Effect where
  HeadRequest :: URI -> HttpHead m (Either HttpClientError Core.HttpResponse)

type instance DispatchOf HttpHead = Dynamic

-- | Perform an HTTP HEAD request.
headRequest :: (HttpHead :> es) => URI -> Eff es (Either HttpClientError Core.HttpResponse)
headRequest = send . HeadRequest

-- | Run the 'HttpHead' effect using a real TLS-enabled HTTP client.
runHttpHead :: (IOE :> es) => Eff (HttpHead : es) a -> Eff es a
runHttpHead action = do
  client <- Core.newHttpClientIO
  interpret
    ( \_ -> \case
        HeadRequest uri -> liftIO $ Core.runHttpClientIO client uri
    )
    action

-- | Bridge instance: satisfy the core library's 'Core.HttpClient' constraint
-- for 'Eff es' when 'HttpHead' is in the effect stack.
instance (HttpHead :> es) => Core.HttpClient (Eff es) where
  headRequest = headRequest
