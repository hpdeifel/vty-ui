{-# LANGUAGE ExistentialQuantification #-}
module Graphics.Vty.Widgets.Collections
    ( Collection
    , newCollection
    , addToCollection
    , setCurrent
    )
where

import Control.Monad.Trans
    ( MonadIO
    )
import Control.Monad.State
    ( get
    )
import Graphics.Vty
    ( DisplayRegion
    , Attr
    , Image
    )
import Graphics.Vty.Widgets.Rendering
    ( Widget
    , WidgetImpl(..)
    , (<~)
    , updateWidgetState_
    , newWidget
    , updateWidget
    , render
    )

-- Ultimately we'd want support for "stacks" to provide things like
-- overlaid dialogs, but for now we'll just implement a "collection"
-- type which allows is to have a collection of widgets and switch
-- between them.

data Entry = forall a. Entry (Widget a)

data Collection =
    Collection { entries :: [Entry]
               , currentEntryNum :: Int
               }

renderEntry :: (MonadIO m) => Entry -> DisplayRegion -> Maybe Attr -> m Image
renderEntry (Entry w) = render w

newCollection :: (MonadIO m) => m (Widget Collection)
newCollection = do
  wRef <- newWidget
  updateWidget wRef $ \w ->
      w { state = Collection { entries = []
                             , currentEntryNum = -1
                             }
        , getGrowHorizontal = return True
        , getGrowVertical = return True
        , draw = \size mAttr -> do
                   st <- get
                   case currentEntryNum st of
                     (-1) -> error "Tried to draw empty collection!"
                     i -> do
                       let e = entries st !! i
                       renderEntry e size mAttr
        }

addToCollection :: (MonadIO m) => Widget Collection -> Widget a -> m ()
addToCollection cRef wRef =
    updateWidgetState_ cRef $ \st -> st { entries = (entries st) ++ [Entry wRef]
                                        , currentEntryNum = if currentEntryNum st == -1
                                                            then 0
                                                            else currentEntryNum st
                                        }

setCurrent :: (MonadIO m) => Widget Collection -> Int -> m ()
setCurrent cRef i = do
  st <- state <~ cRef
  if i < length (entries st) && i >= 0 then
      updateWidgetState_ cRef $ \s -> s { currentEntryNum = i } else
      error $ "collection index " ++ (show i) ++
                " bad; size is " ++ (show $ length $ entries st)