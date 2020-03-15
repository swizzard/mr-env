{-|
Module      : System.Environment.MrEnv
Description : Read environment variables, with default fallbacks
Copyright   : (c) 2020 Christian Rocha
License     : MIT
Maintainer  : christian@rocha.is
Stability   : experimental
Portability : POSIX

A simple way to read environment variables.
-}

{-# LANGUAGE LambdaCase #-}

module System.Environment.MrEnv (
{-|
Read environment variables, with default fallback values.

A simple example with @do@ notation:

@
import System.Environment.MrEnv ( envAsBool, envAsInt, envAsInteger, envAsString )

main :: IO ()
main = do

    -- Get a string, with a fallback value if nothing is set.
    host <- envAsString \"HOST\" "localhost"

    -- Get an int. If you need an integer instead you could also use envAsInteger.
    port <- envAsInt \"PORT\" 8000

    -- Get a boolean. Here we're expecting the environment variable to reading
    -- something along the lines of "true", \"TRUE\", \"True\", "truE" and so on.
    debug <- envAsBool \"DEBUG\" False

    putStrLn $
        "Let's connect to "
        ++ host
        ++ " on port "
        ++ show port
        ++ ". Debug mode is "
        ++ if debug then "on" else "off"
        ++ "."
@

Read environment variables into a record:

@
import System.Environment.MrEnv ( envAsBool, envAsInt, envAsInteger, envAsString )

data Config =
    Config { host  :: String
           , port  :: Int
           , debug :: Bool
           }

getConfig :: IO Config
getConfig = Config
    <$> envAsString \"HOST\" "localhost"
    <*> envAsInt \"PORT\" 8000
    <*> envAsBool \"DEBUG\" False

main :: IO ()
main =
    getConfig >>= \conf ->
        putStrLn $
            "Let's connect to "
            ++ host c
            ++ " on port "
            ++ show $ port c
            ++ ". Debug mode is "
            ++ if debug c then "on" else "off"
            ++ "."
@
-}

        envAsBool
      , envAsInt
      , envAsInteger
      , envAsString ) where

import Control.Exception ( try )
import System.Environment ( getEnv )
import Text.Read ( readMaybe )
import Data.Maybe ( fromMaybe )
import Data.Function ( (&) )
import qualified Data.Char as Char


{-| Get an environment variable as a string, with a default fallback value -}
envAsString :: String
            -- ^Name of environment varaiable
            -> String
            -- ^Fallback value
            -> IO String
            -- ^Result
envAsString name defaultValue =
    (try $ getEnv name :: IO (Either IOError String)) >>= \case
        Left _ ->
            return defaultValue
        Right val ->
            return val


{-| Get an environment variable as an int, with a default fallback value -}
envAsInt :: String
         -- ^Name of environment variable
         -> Int
         -- ^Fallback value
         -> IO Int
         -- ^Result
envAsInt name defaultValue =
    envAsString name "" >>= \val ->
        if val == ""
            then return defaultValue
            else return $
                (readMaybe val :: Maybe Int) & fromMaybe defaultValue


{-| Get an environment variable as an integer, with a default fallback value -}
envAsInteger :: String
             -- ^Name of environment variable
             -> Integer
             -- ^Fallback value
             -> IO Integer
             -- ^Result
envAsInteger name defaultValue =
    envAsString name "" >>= \val ->
        if val == ""
           then return defaultValue
           else return $
               (readMaybe val :: Maybe Integer) & fromMaybe defaultValue


{-| Get an environment variable as a boolean, with a default fallback value -}
envAsBool :: String
          -- ^Name of environment variable
          -> Bool
          -- ^Fallback value
          -> IO Bool
          -- ^Result
envAsBool name defaultValue =
    envAsString name "" >>= \val ->
        if val == ""
           then return defaultValue
            else return $
                let
                    -- Normalize the string so values like  TRUE, true, True,
                    -- and truE all become "True," which can then be coerced to
                    -- a boolean.
                    s = capitalize val
                in
                (readMaybe s :: Maybe Bool) & fromMaybe defaultValue


{-| Capitalize the first character in a string and make all other characters
    lowercase. -}
capitalize :: String -> String
capitalize [] = []
capitalize (head':tail') =
    Char.toUpper head' : map Char.toLower tail'
