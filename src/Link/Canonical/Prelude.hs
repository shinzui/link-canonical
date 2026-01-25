{-# LANGUAGE PackageImports #-}

module Link.Canonical.Prelude
  ( -- * Re-exports
    module X,

    -- * Lens operators
    (&),
    (.~),
    (^.),
    (^?),
    (%~),
    (?~),
    view,
    set,
    over,
    _Just,
    _Left,
    _Right,
    at,
    ix,
    to,
    mapped,
  )
where

-- Enable #label syntax for Generic records

-- Lens operators

-- Common re-exports
import Control.Applicative as X (Alternative (..), optional)
import Control.Lens (at, ix, mapped, over, set, to, view, (%~), (&), (.~), (?~), (^.), (^?), _Just, _Left, _Right)
import Control.Monad as X (forM, forM_, guard, unless, when, (<=<), (>=>))
import Control.Monad.Catch as X (MonadCatch, MonadThrow, catch, throwM, try)
import Control.Monad.IO.Class as X (MonadIO, liftIO)
import Data.Bifunctor as X (first, second)
import Data.Either as X (either, fromLeft, fromRight, isLeft, isRight)
import Data.Foldable as X (fold, foldl', for_, toList, traverse_)
import Data.Function as X (on)
import Data.Functor as X (void, ($>), (<$>), (<&>))
import Data.List as X (find, sortBy, sortOn)
import Data.Maybe as X (catMaybes, fromMaybe, isJust, isNothing, listToMaybe, mapMaybe, maybe)
import Data.Ord as X (comparing)
import Data.Set as X (Set)
import Data.Text as X (Text)
import Data.Time as X (NominalDiffTime, UTCTime)
import Data.Traversable as X (for)
import GHC.Generics as X (Generic)
import Text.URI as X (URI)
import Text.URI qualified as X (mkURI)
import "generic-lens" Data.Generics.Labels ()
