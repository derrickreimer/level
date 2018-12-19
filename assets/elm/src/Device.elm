module Device exposing (Device(..), parse)


type Device
    = Desktop
    | Mobile


parse : String -> Device
parse name =
    case name of
        "MOBILE" ->
            Mobile

        _ ->
            Desktop
