module File exposing (Data, File, avatarInput, getContents, init, input, receive, request)

import File.Types exposing (Data)
import Html exposing (Attribute, Html, button, img, label, text)
import Html.Attributes as Attributes exposing (class, id, src, type_)
import Html.Events exposing (on)
import Json.Decode as Decode
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


getContents : File -> String
getContents (File { contents }) =
    contents



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


avatarInput : String -> Maybe String -> msg -> Html msg
avatarInput nodeId maybeSrc changeMsg =
    case maybeSrc of
        Just avatarUrl ->
            label [ class "flex w-32 h-32 rounded-full cursor-pointer bg-grey-light" ]
                [ img [ src avatarUrl, class "w-full h-full rounded-full" ] []
                , input nodeId changeMsg [ class "invisible-file" ]
                ]

        Nothing ->
            label [ class "flex w-32 h-32 items-center text-center text-lg leading-tight text-dusty-blue border-2 rounded-full border-dashed cursor-pointer no-select" ]
                [ text "Upload an avatar..."
                , input nodeId changeMsg [ class "invisible-file" ]
                ]
