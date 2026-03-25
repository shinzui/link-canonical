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
import "base" Control.Applicative as X (Alternative (..), optional)
import "base" Control.Monad as X (forM, forM_, guard, unless, when, (<=<), (>=>))
import "base" Control.Monad.IO.Class as X (MonadIO, liftIO)
import "base" Data.Bifunctor as X (first, second)
import "base" Data.Either as X (either, fromLeft, fromRight, isLeft, isRight)
import "base" Data.Foldable as X (fold, foldl', for_, toList, traverse_)
import "base" Data.Function as X (on)
import "base" Data.Functor as X (void, ($>), (<$>), (<&>))
import "base" Data.List as X (find, sortBy, sortOn)
import "base" Data.Maybe as X (catMaybes, fromMaybe, isJust, isNothing, listToMaybe, mapMaybe, maybe)
import "base" Data.Ord as X (comparing)
import "base" Data.Traversable as X (for)
import "base" GHC.Generics as X (Generic)
import "containers" Data.Set as X (Set)
import "exceptions" Control.Monad.Catch as X (MonadCatch, MonadThrow, catch, throwM, try)
import "generic-lens" Data.Generics.Labels ()
import "lens" Control.Lens (at, ix, mapped, over, set, to, view, (%~), (&), (.~), (?~), (^.), (^?), _Just, _Left, _Right)
import "modern-uri" Text.URI as X (URI, mkURI)
import "text" Data.Text as X (Text)
import "time" Data.Time as X (NominalDiffTime, UTCTime)
