-- Copyright 2016 Google Inc. All Rights Reserved.
--
-- Use of this source code is governed by a BSD-style
-- license that can be found in the LICENSE file or at
-- https://developers.google.com/open-source/licenses/bsd

-- | A benchmark to measure the performance difference between packed and
-- unpacked integer data.
module Main (main) where

import Data.ProtoLens.BenchmarkUtil (protoBenchmark, benchmarkMain)
import Criterion.Main (Benchmark)
import Lens.Family ((&), (.~))
import Data.Int (Int32)
import Data.ProtoLens (defMessage)
import Proto.IntPacking
import Proto.IntPacking_Fields

defaultNumInt32s :: Int
defaultNumInt32s = 10000

populateUnpacked :: Int -> Int32 -> FooUnpacked
populateUnpacked n k = defMessage & num .~ replicate n k

populatePacked :: Int -> Int32 -> FooPacked
populatePacked n k = defMessage & num .~ replicate n k

benchmaker :: Int -> [Benchmark]
benchmaker size =
    [ protoBenchmark "int32-unpacked" (populateUnpacked size 5 :: FooUnpacked)
    , protoBenchmark "int32-packed" (populatePacked size 5 :: FooPacked)
    ]

main :: IO ()
main = benchmarkMain defaultNumInt32s benchmaker
