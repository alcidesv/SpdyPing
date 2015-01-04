{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}

module SpdyPing.TLSConnect (
    makeTLSParamsForSpdy
    ) where


import qualified Data.ByteString.Char8      as BC
import           Data.ByteString(ByteString)
import           Data.Default
import           Data.X509.CertificateStore (CertificateStore)
import           Control.Monad (forM_)

import qualified Network.TLS                as TLS
import qualified Network.TLS.Extra          as TLS




-- | Create a final TLS 'ClientParams' according to the destination and the
-- TLSSettings.
makeTLSParamsForSpdy :: (String,Int) -> CertificateStore ->  TLS.ClientParams
makeTLSParamsForSpdy cid scs  =
    (TLS.defaultParamsClient (fst cid) portString)
        { TLS.clientSupported = def { TLS.supportedCiphers = TLS.ciphersuite_all }
        , TLS.clientShared    = def
            { TLS.sharedCAStore         = scs
            , TLS.sharedValidationCache = def
            }
        , TLS.clientHooks = def 
            { TLS.onNPNServerSuggest    = Just selectSPDY
            }
        }
  where  portString = BC.pack $ show $ snd cid

whichSPDY :: ByteString
whichSPDY = "spdy/3.1"

whichHTTP :: ByteString 
whichHTTP = "http/1.1"

selectSPDY :: [ByteString] -> IO ByteString
selectSPDY protocols = do
    forM_ protocols $ \x -> do
        putStrLn $ "Protocol offered: " ++ show x
    if whichSPDY `elem` protocols
        then 
            return whichSPDY
        else
            return whichHTTP