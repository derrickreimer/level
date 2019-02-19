module Lazy exposing (Lazy(..), map)

{-| Lazy represents data that can be in a state of "not loaded" or loaded.
-}


type Lazy a
    = NotLoaded
    | Loaded a


map : (a -> b) -> Lazy a -> Lazy b
map fn lazy =
    case lazy of
        Loaded a ->
            Loaded (fn a)

        NotLoaded ->
            NotLoaded
