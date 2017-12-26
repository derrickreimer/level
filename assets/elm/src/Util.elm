module Util exposing (..)

-- UTILITY FUNCTIONS


last : List a -> Maybe a
last =
    List.foldl (Just >> always) Nothing
