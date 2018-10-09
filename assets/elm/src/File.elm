module File exposing (Data, File, decoder, getContents, init, input, receive, request)

import File.Types exposing (Data)
import Html exposing (Attribute, Html, button, img, label, text)
import Html.Attributes as Attributes exposing (class, id, src, type_)
import Html.Events exposing (on)
import Json.Decode as Decode exposing (Decoder, field, int, maybe, string)
import Ports



-- TYPES


type File
    = File Data


type alias Data =
    File.Types.Data



-- API


init : Data -> File
init data =
    File data


getContents : File -> Maybe String
getContents (File { contents }) =
    contents



-- DECODING


decoder : Decoder File
decoder =
    Decode.map File
        (Decode.map5 Data
            (field "clientId" string)
            (field "name" string)
            (field "type" string)
            (field "size" int)
            (field "contents" (maybe string))
        )



-- PORTS


request : String -> Cmd msg
request nodeId =
    Ports.requestFile nodeId


receive : (Data -> msg) -> Sub msg
receive toMsg =
    Ports.receiveFile toMsg



-- HTML


input : String -> msg -> List (Attribute msg) -> Html msg
input name onChange attrs =
    let
        defaultAttrs =
            [ id name
            , type_ "file"
            , Attributes.name name
            , on "change" (Decode.succeed onChange)
            ]
    in
    Html.input (defaultAttrs ++ attrs) []
