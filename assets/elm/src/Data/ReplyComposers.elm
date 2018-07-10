module Data.ReplyComposers exposing (ReplyComposers, ReplyComposer)

import Dict exposing (Dict)


type alias ReplyComposer =
    { body : String
    , isExpanded : Bool
    , isSubmitting : Bool
    }


type alias ReplyComposers =
    Dict String ReplyComposer
