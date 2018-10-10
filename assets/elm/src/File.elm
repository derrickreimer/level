module File exposing (File, State(..), decoder, getClientId, getContents, getName, input, isImage, receive, request, setState, setUploadPercentage)

import Html exposing (Attribute, Html, button, img, label, text)
import Html.Attributes as Attributes exposing (class, id, src, type_)
import Html.Events exposing (on)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, fail, field, int, maybe, string, succeed)
import Ports



-- TYPES


type File
    = File Internal


type alias Internal =
    { clientId : Id
    , state : State
    , name : String
    , type_ : String
    , size : Int
    , contents : Maybe String
    , uploadPercentage : Int
    }


type State
    = Staged
    | Uploading
    | Uploaded Id String
    | UploadFailed
    | Unknown



-- API


getClientId : File -> Id
getClientId (File internal) =
    internal.clientId


getName : File -> String
getName (File internal) =
    internal.name


getContents : File -> Maybe String
getContents (File { contents }) =
    contents


isImage : File -> Bool
isImage (File internal) =
    String.startsWith "image" internal.type_


setUploadPercentage : Int -> File -> File
setUploadPercentage percentage (File internal) =
    File { internal | uploadPercentage = percentage }


setState : State -> File -> File
setState newState (File internal) =
    File { internal | state = newState }



-- DECODING


decoder : Decoder File
decoder =
    Decode.map File
        (Decode.map7 Internal
            (field "clientId" Id.decoder)
            (Decode.succeed Staged)
            (field "name" string)
            (field "type" string)
            (field "size" int)
            (field "contents" (maybe string))
            (Decode.succeed 0)
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
