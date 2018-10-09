module File exposing (File, decoder, getContents, input, receive, request)

import Html exposing (Attribute, Html, button, img, label, text)
import Html.Attributes as Attributes exposing (class, id, src, type_)
import Html.Events exposing (on)
import Json.Decode as Decode exposing (Decoder, field, int, maybe, string)
import Ports



-- TYPES


type File
    = File Internal


type alias Internal =
    { clientId : String
    , name : String
    , type_ : String
    , size : Int
    , contents : Maybe String
    }



-- API


getContents : File -> Maybe String
getContents (File { contents }) =
    contents



-- DECODING


decoder : Decoder File
decoder =
    Decode.map File
        (Decode.map5 Internal
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


receive : (Decode.Value -> msg) -> Sub msg
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
