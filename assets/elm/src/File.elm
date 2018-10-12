module File exposing (File, State(..), decoder, fragment, getClientId, getContents, getName, getState, getUploadId, icon, input, isImage, receive, request, setState, setUploadPercentage)

import Color exposing (Color)
import GraphQL exposing (Fragment)
import Html exposing (Attribute, Html, button, img, label, text)
import Html.Attributes as Attributes exposing (class, id, src, type_)
import Html.Events exposing (on)
import Icons
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, fail, field, int, maybe, string, succeed)
import Ports



-- TYPES


type File
    = File Internal


type alias Internal =
    { state : State
    , filename : String
    , contentType : String
    , size : Int
    , clientId : Maybe Id
    , contents : Maybe String
    }


type State
    = Staged
    | Uploading Int
    | Uploaded Id String
    | UploadError



-- API


getClientId : File -> Maybe Id
getClientId (File internal) =
    internal.clientId


getName : File -> String
getName (File internal) =
    internal.filename


getContents : File -> Maybe String
getContents (File { contents }) =
    contents


getUploadId : File -> Maybe Id
getUploadId (File internal) =
    case internal.state of
        Uploaded id url ->
            Just id

        _ ->
            Nothing


getState : File -> State
getState (File internal) =
    internal.state


isImage : File -> Bool
isImage (File internal) =
    String.startsWith "image" internal.contentType


setUploadPercentage : Int -> File -> File
setUploadPercentage percentage (File internal) =
    File { internal | state = Uploading percentage }


setState : State -> File -> File
setState newState (File internal) =
    File { internal | state = newState }



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment FileFields on File {
              id
              contentType
              filename
              size
              url
              fetchedAt
            }
            """
    in
    GraphQL.toFragment queryBody []



-- DECODING


decoder : Decoder File
decoder =
    Decode.oneOf [ stagedDecoder, uploadedDecoder ]


stagedDecoder : Decoder File
stagedDecoder =
    Decode.map File
        (Decode.map6 Internal
            (Decode.succeed Staged)
            (field "filename" string)
            (field "contentType" string)
            (field "size" int)
            (field "clientId" (maybe Id.decoder))
            (field "contents" (maybe string))
        )


uploadedDecoder : Decoder File
uploadedDecoder =
    Decode.map File
        (Decode.map6 Internal
            (Decode.map2 Uploaded
                (field "id" Id.decoder)
                (field "url" string)
            )
            (field "filename" string)
            (field "contentType" string)
            (field "size" int)
            (Decode.succeed Nothing)
            (Decode.succeed Nothing)
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


icon : Color -> File -> Html msg
icon color file =
    if isImage file then
        Icons.image color

    else
        Icons.file color
