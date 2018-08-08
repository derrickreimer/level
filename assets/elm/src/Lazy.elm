module Lazy exposing (Lazy(..))


type Lazy a
    = NotLoaded
    | Loaded a
