{-# LANGUAGE BangPatterns      #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}
module Test.Cardano.Binary.Drop
  (tests)
  where

import Data.ByteString  (ByteString)
import Data.Int (Int32)
import Data.Word (Word8, Word64)

import Cardano.Binary

import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range


tests :: IO Bool
tests = checkParallel $$(discover)

------------------------------------------------------------------------------
-- Properties testing whether dropping elements actully removes it or not

genInt32 :: Gen Int32
genInt32 = Gen.int32 Range.exponentialBounded

genBytes :: Gen ByteString
genBytes = Gen.bytes (Range.linear 0 1000)

genWord8 :: Gen Word8
genWord8 = Gen.word8 Range.exponentialBounded

genWord64 :: Gen Word64
genWord64 = Gen.word64 Range.exponentialBounded

prop_dropMap :: Property
prop_dropMap = property $ do
  mp <- forAll $ Gen.map (Range.constant 0 10)
      ((,) <$> genInt32
           <*> Gen.list (Range.constant 0 10) genWord8
      )
  let encodedBs = serialize mp
  decodeFull encodedBs === Right mp
  decodeFullDecoder "Drop Test Failed" (dropMap dropInt32 (dropList dropWord8)) encodedBs === Right ()

prop_dropTuple :: Property
prop_dropTuple = property $ do
  (set, bs) <- forAll $ (,) <$> Gen.set (Range.constant 0 10) genInt32
                            <*> genBytes
  let encodedBs = serialize (set, bs)
  decodeFull encodedBs === Right (set, bs)
  decodeFullDecoder "Drop Test Failed" (dropTuple (dropSet dropInt32) dropBytes) encodedBs === Right ()

prop_dropTriple ::Property
prop_dropTriple = property $ do
  tri <- forAll $ (,,) <$> genInt32 <*> genWord8 <*> genWord64
  let encodedBs = serialize tri
  decodeFull encodedBs === Right tri
  decodeFullDecoder "Drop Test Failed" (dropTriple dropInt32 dropWord8 dropWord64) encodedBs === Right ()
