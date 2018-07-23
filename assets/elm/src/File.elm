module File exposing (File, Data, init, request, receive, input)

import File.Types exposing (Data)
import Html exposing (Html, Attribute)
import Html.Attributes exposing (type_, id)
import Html.Events exposing (on)
import Json.Decode as Decode
import Ports


-- TYPES


type File
    = File Data


type alias Data =
    File.Types.Data


init : Data -> File
init data =
    File data



-- PORTS


request : String -> Cmd msg
request nodeId =
    Ports.requestFile nodeId


receive : (Data -> msg) -> Sub msg
receive toMsg =
    Ports.receiveFile toMsg



-- HTML


input : String -> msg -> List (Attribute msg) -> Html msg
input nodeId changeMsg attrs =
    Html.input
        ([ id nodeId, type_ "file", on "change" (Decode.succeed changeMsg) ] ++ attrs)
        []
