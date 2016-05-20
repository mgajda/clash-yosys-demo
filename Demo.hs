{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE BinaryLiterals             #-}
-- | This module implements a simple digital stopwatch.
module Main where

import           Prelude                 () -- no implicit Prelude!
import           Control.Applicative
import           Control.Arrow
import qualified Data.List as List
import           Data.Traversable

import           CLaSH.Prelude
import           CLaSH.Sized.Vector
import           CLaSH.Signal
import           CLaSH.Signal.Explicit
import           CLaSH.Signal.Bundle

type Word5 = Unsigned 5

-- | Gives a signal once every second, for the duration of a single System Clock cycle.
everySecond :: Signal Bool -- ^ trigger every one second
everySecond  = counter' fpgaFrequency
-- $ (2 :: Word17) ^ (15 :: Word17) * (1000 :: Word17) -- or Signed 16?

-- Here, I am using 32 bit arithmetic to count second,
-- instead of splitting it into smaller counters and connecting them.
fpgaFrequency :: Unsigned 27
fpgaFrequency  = 32768000 -- real 32MHz

-- | Counter that cycles every time it gets a given @True@ signal at the input,
-- and itself gives the current count, and also the @True@ signal only
-- when the limit is reached.
counter      :: (Num s, Eq s) =>
                 s            -> -- ^ number of clock cycles before overflow and reset
                 Signal Bool  -> -- ^ input trigger for the clock cycle (not the clock domain!)
                 Unbundled (s, Bool)
counter limit = fsm <^> 0
  where
    fsm st False                = (st,   (st,   False))
    fsm st True | limit == st+1 = (0,    (0,    True ))
    fsm st True                 = (st+1, (st+1, False))

-- | Simple counter without any inputs.
-- Gives true signal only when the given limit is reached.
counter'      :: (Num s, Eq s) =>
                  s            -> -- ^ number of clock cycles before overflow and reset
                  Signal Bool
counter' limit = (fsm <^> 0) $ signal ()
  where
    fsm st () | limit == st = (0,    True)
              | otherwise   = (st+1, False)

{-# ANN topEntity
  (defTop
    { t_name     = "blinker"
    , t_inputs   = []
    , t_outputs  = ["LED"]
    , t_extraIn  = [ ("CLK", 1)
                   ]
    , t_clocks   = [
                   ]
    }) #-}
-- | Top entity to implement
topEntity :: Signal Word5
topEntity  = secondsCounter
  where
    secondPulse         = counter'   fpgaFrequency
    (secondsCounter, _) = counter (2^5) secondPulse

-- * Here are helpers for simulation.
-- | Takes every nth step of simulated signal.
takeEvery :: Int -> [a] -> [a]
takeEvery n = go
  where
    go []     = []
    go (b:bs) = b:go (List.drop (fromIntegral n) bs)

main :: IO ()
main = print
     $ takeEvery ((fromIntegral fpgaFrequency `div` 10))
     $ sampleN (10*fromIntegral fpgaFrequency) topEntity

