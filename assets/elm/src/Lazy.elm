module Lazy exposing (Lazy(..))

{-| Lazy represents data that can be in a state of "not loaded" or loaded.
-}


type Lazy a
    = NotLoaded
    | Loaded a
