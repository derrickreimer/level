module Autosize exposing (..)


type alias Args =
    { method : String
    , id : String
    }


type Method
    = Init
    | Update
    | Destroy


buildArgs : Method -> String -> Args
buildArgs method id =
    let
        args =
            case method of
                Init ->
                    Args "init"

                Update ->
                    Args "update"

                Destroy ->
                    Args "destroy"
    in
        args id
