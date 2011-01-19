module Graphics.Vty.Widgets.Limits
    ( VLimit
    , HLimit
    , hLimit
    , vLimit
    , setVLimit
    , setHLimit
    , addToVLimit
    , addToHLimit
    , getVLimit
    , getHLimit
    )
where

import Control.Monad.Reader
    ( ask
    )
import Control.Monad
    ( when
    )
import Control.Monad.Trans
    ( MonadIO
    , liftIO
    )
import Graphics.Vty
    ( region_width
    , region_height
    )
import Graphics.Vty.Widgets.Core
    ( Widget
    , WidgetImpl(..)
    , (<~)
    , newWidget
    , render
    , withWidth
    , withHeight
    , updateWidget
    , updateWidgetState
    , setPhysicalPosition
    , getState
    , handleKeyEvent
    , growHorizontal
    , growVertical
    )

data HLimit a = HLimit Int (Widget a)

-- |Impose a maximum horizontal size, in columns, on a 'Widget'.
hLimit :: (MonadIO m) => Int -> Widget a -> m (Widget (HLimit a))
hLimit maxWidth child = do
  wRef <- newWidget
  updateWidget wRef $ \w ->
      w { state = HLimit maxWidth child
        , getGrowHorizontal = return False

        , getGrowVertical = do
            HLimit _ ch <- ask
            liftIO $ growVertical ch

        , keyEventHandler =
            \this key mods -> do
              HLimit _ ch <- getState this
              handleKeyEvent ch key mods

        , draw = \this s mAttr -> do
                   HLimit width ch <- getState this
                   let region = s `withWidth` fromIntegral (min (toEnum width) (region_width s))
                   render ch region mAttr

        , setPosition =
            \this pos -> do
              (setPosition w) this pos
              HLimit _ ch <- getState this
              setPhysicalPosition ch pos
        }
  return wRef

data VLimit a = VLimit Int (Widget a)

-- |Impose a maximum horizontal size, in columns, on a 'Widget'.
vLimit :: (MonadIO m) => Int -> Widget a -> m (Widget (VLimit a))
vLimit maxHeight child = do
  wRef <- newWidget
  updateWidget wRef $ \w ->
      w { state = VLimit maxHeight child
        , getGrowVertical = return False
        , getGrowHorizontal = do
            VLimit _ ch <- ask
            liftIO $ growHorizontal ch

        , keyEventHandler =
            \this key mods -> do
              VLimit _ ch <- getState this
              handleKeyEvent ch key mods

        , draw = \this s mAttr -> do
                   VLimit height ch <- getState this
                   let region = s `withHeight` fromIntegral (min (toEnum height) (region_height s))
                   render ch region mAttr

        , setPosition =
            \this pos -> do
              (setPosition w) this pos
              VLimit _ ch <- getState this
              setPhysicalPosition ch pos
        }
  return wRef

setVLimit :: (MonadIO m) => Widget (VLimit a) -> Int -> m ()
setVLimit wRef lim =
    when (lim >= 1) $
         updateWidgetState wRef $ \(VLimit _ ch) -> VLimit lim ch

setHLimit :: (MonadIO m) => Widget (HLimit a) -> Int -> m ()
setHLimit wRef lim =
    when (lim >= 1) $
         updateWidgetState wRef $ \(HLimit _  ch) -> HLimit lim ch

addToVLimit :: (MonadIO m) => Widget (VLimit a) -> Int -> m ()
addToVLimit wRef delta = do
  lim <- getVLimit wRef
  setVLimit wRef $ lim + delta

addToHLimit :: (MonadIO m) => Widget (HLimit a) -> Int -> m ()
addToHLimit wRef delta = do
  lim <- getHLimit wRef
  setHLimit wRef $ lim + delta

getVLimit :: (MonadIO m) => Widget (VLimit a) -> m Int
getVLimit wRef = do
  (VLimit lim _) <- state <~ wRef
  return lim

getHLimit :: (MonadIO m) => Widget (HLimit a) -> m Int
getHLimit wRef = do
  (HLimit lim _) <- state <~ wRef
  return lim