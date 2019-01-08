module PostEditor exposing
    ( PostEditor, init
    , getId, getTextareaId, getBody, getErrors, setBody, setErrors, clearErrors, reset
    , isExpanded, isSubmitting, isSubmittable, isUnsubmittable, expand, collapse, setToSubmitting, setNotSubmitting
    , getFiles, getUploadIds, getFileById, addFile, setFiles, setFileUploadPercentage, setFileState
    , Event(..), receive, decoder, decodeEvent
    , insertAtCursor, insertFileLink, fetchLocal, saveLocal, clearLocal, triggerBodyChanged
    , ViewConfig, wrapper, filesView
    )

{-| Represents an editor instance for creating/editing posts and replies.


# Types

@docs PostEditor, init


# General

@docs getId, getTextareaId, getBody, getErrors, setBody, setErrors, clearErrors, reset


# Visual Settings

@docs isExpanded, isSubmitting, isSubmittable, isUnsubmittable, expand, collapse, setToSubmitting, setNotSubmitting


# Files

@docs getFiles, getUploadIds, getFileById, addFile, setFiles, setFileUploadPercentage, setFileState


# Inbound Events

@docs Event, receive, decoder, decodeEvent


# Outbound Commands

@docs insertAtCursor, insertFileLink, fetchLocal, saveLocal, clearLocal, triggerBodyChanged


# Views

@docs ViewConfig, wrapper, filesView

-}

import Color exposing (Color)
import File exposing (File)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on)
import Icons
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import ListHelpers
import Ports
import SpaceUser exposing (SpaceUser)
import ValidationError exposing (ValidationError)
import View.Helpers exposing (viewUnless)


type PostEditor
    = PostEditor Internal


type alias Internal =
    { id : Id
    , body : String
    , files : List File
    , isExpanded : Bool
    , isSubmitting : Bool
    , errors : List ValidationError
    }


init : Id -> PostEditor
init id =
    PostEditor (Internal id "" [] False False [])



-- GENERAL


getId : PostEditor -> Id
getId (PostEditor internal) =
    internal.id


getTextareaId : PostEditor -> Id
getTextareaId (PostEditor internal) =
    internal.id ++ "__textarea"


getBody : PostEditor -> String
getBody (PostEditor internal) =
    internal.body


getErrors : PostEditor -> List ValidationError
getErrors (PostEditor internal) =
    internal.errors


setBody : String -> PostEditor -> PostEditor
setBody newBody (PostEditor internal) =
    PostEditor { internal | body = newBody }


setErrors : List ValidationError -> PostEditor -> PostEditor
setErrors errors (PostEditor internal) =
    PostEditor { internal | errors = errors }


clearErrors : PostEditor -> PostEditor
clearErrors (PostEditor internal) =
    PostEditor { internal | errors = [] }


reset : PostEditor -> ( PostEditor, Cmd msg )
reset editor =
    let
        newEditor =
            editor
                |> setBody ""
                |> setNotSubmitting
                |> setFiles []
                |> clearErrors
    in
    ( newEditor
    , Cmd.batch
        [ saveLocal newEditor
        , triggerBodyChanged newEditor
        ]
    )



-- VISUAL SETTINGS


isExpanded : PostEditor -> Bool
isExpanded (PostEditor internal) =
    internal.isExpanded


isSubmitting : PostEditor -> Bool
isSubmitting (PostEditor internal) =
    internal.isSubmitting


isSubmittable : PostEditor -> Bool
isSubmittable editor =
    not (isUnsubmittable editor)


isUnsubmittable : PostEditor -> Bool
isUnsubmittable (PostEditor internal) =
    (internal.body == "") || internal.isSubmitting


expand : PostEditor -> PostEditor
expand (PostEditor internal) =
    PostEditor { internal | isExpanded = True }


collapse : PostEditor -> PostEditor
collapse (PostEditor internal) =
    PostEditor { internal | isExpanded = False }


setToSubmitting : PostEditor -> PostEditor
setToSubmitting (PostEditor internal) =
    PostEditor { internal | isSubmitting = True }


setNotSubmitting : PostEditor -> PostEditor
setNotSubmitting (PostEditor internal) =
    PostEditor { internal | isSubmitting = False }



-- FILES


getFiles : PostEditor -> List File
getFiles (PostEditor internal) =
    internal.files


getUploadIds : PostEditor -> List Id
getUploadIds (PostEditor internal) =
    List.filterMap File.getUploadId internal.files


getFileById : Id -> PostEditor -> Maybe File
getFileById id editor =
    let
        filterFn file =
            case File.getState file of
                File.Uploaded fileId _ ->
                    fileId == id

                _ ->
                    False
    in
    editor
        |> getFiles
        |> List.filter filterFn
        |> List.head


addFile : File -> PostEditor -> PostEditor
addFile newFile (PostEditor internal) =
    PostEditor { internal | files = newFile :: internal.files }


setFiles : List File -> PostEditor -> PostEditor
setFiles newFiles (PostEditor internal) =
    PostEditor { internal | files = newFiles }


setFileUploadPercentage : Id -> Int -> PostEditor -> PostEditor
setFileUploadPercentage clientId percentage (PostEditor internal) =
    let
        updater file =
            if File.getClientId file == Just clientId then
                File.setUploadPercentage percentage file

            else
                file

        newFiles =
            List.map updater internal.files
    in
    PostEditor { internal | files = newFiles }


setFileState : Id -> File.State -> PostEditor -> PostEditor
setFileState clientId newState (PostEditor internal) =
    let
        updater file =
            if File.getClientId file == Just clientId then
                File.setState newState file

            else
                file

        newFiles =
            List.map updater internal.files
    in
    PostEditor { internal | files = newFiles }



-- INBOUND EVENTS


type Event
    = LocalDataFetched Id String
    | Unknown


receive : (Decode.Value -> msg) -> Sub msg
receive toMsg =
    Ports.postEditorIn toMsg


decoder : Decoder Event
decoder =
    let
        convert type_ =
            case type_ of
                "localDataFetched" ->
                    Decode.map2 LocalDataFetched
                        (Decode.field "id" Decode.string)
                        (Decode.field "body" Decode.string)

                _ ->
                    Decode.fail "event not recognized"
    in
    Decode.field "type" Decode.string
        |> Decode.andThen convert


decodeEvent : Decode.Value -> Event
decodeEvent value =
    Decode.decodeValue decoder value
        |> Result.withDefault Unknown



-- OUTBOUND COMMANDS


insertAtCursor : String -> PostEditor -> Cmd msg
insertAtCursor text editor =
    Ports.postEditorOut <|
        Encode.object
            [ ( "id", Id.encoder (getId editor) )
            , ( "command", Encode.string "insertAtCursor" )
            , ( "text", Encode.string text )
            ]


insertFileLink : Id -> PostEditor -> Cmd msg
insertFileLink fileId editor =
    case getFileById fileId editor of
        Just file ->
            case File.markdownLink file of
                Just link ->
                    insertAtCursor link editor

                Nothing ->
                    Cmd.none

        Nothing ->
            Cmd.none


fetchLocal : PostEditor -> Cmd msg
fetchLocal editor =
    Ports.postEditorOut <|
        Encode.object
            [ ( "id", Id.encoder (getId editor) )
            , ( "command", Encode.string "fetchLocal" )
            ]


saveLocal : PostEditor -> Cmd msg
saveLocal editor =
    Ports.postEditorOut <|
        Encode.object
            [ ( "id", Id.encoder (getId editor) )
            , ( "command", Encode.string "saveLocal" )
            , ( "body", Encode.string (getBody editor) )
            ]


clearLocal : PostEditor -> Cmd msg
clearLocal editor =
    Ports.postEditorOut <|
        Encode.object
            [ ( "id", Id.encoder (getId editor) )
            , ( "command", Encode.string "clearLocal" )
            ]


triggerBodyChanged : PostEditor -> Cmd msg
triggerBodyChanged editor =
    Ports.postEditorOut <|
        Encode.object
            [ ( "id", Id.encoder (getId editor) )
            , ( "command", Encode.string "triggerBodyChanged" )
            ]



-- VIEW


type alias ViewConfig msg =
    { editor : PostEditor
    , spaceId : Id
    , spaceUsers : List SpaceUser
    , groups : List Group
    , onFileAdded : File -> msg
    , onFileUploadProgress : Id -> Int -> msg
    , onFileUploaded : Id -> Id -> String -> msg
    , onFileUploadError : Id -> msg
    , classList : List ( String, Bool )
    }


wrapper : ViewConfig msg -> List (Html msg) -> Html msg
wrapper config children =
    Html.node "post-editor"
        [ id (getId config.editor)
        , property "spaceId" (Id.encoder config.spaceId)
        , property "spaceUsers" (spaceUsersEncoder config.spaceUsers)
        , on "fileAdded" <|
            Decode.map config.onFileAdded
                (Decode.at [ "detail" ] File.decoder)
        , on "fileUploadProgress" <|
            Decode.map2 config.onFileUploadProgress
                (Decode.at [ "detail", "clientId" ] Id.decoder)
                (Decode.at [ "detail", "percentage" ] Decode.int)
        , on "fileUploaded" <|
            Decode.map3 config.onFileUploaded
                (Decode.at [ "detail", "clientId" ] Id.decoder)
                (Decode.at [ "detail", "id" ] Id.decoder)
                (Decode.at [ "detail", "url" ] Decode.string)
        , on "fileUploadError" <|
            Decode.map config.onFileUploadError
                (Decode.at [ "detail", "clientId" ] Id.decoder)
        , classList config.classList
        ]
        children


spaceUsersEncoder : List SpaceUser -> Encode.Value
spaceUsersEncoder list =
    Encode.list spaceUserEncoder list


spaceUserEncoder : SpaceUser -> Encode.Value
spaceUserEncoder spaceUser =
    Encode.object
        [ ( "handle", Encode.string <| SpaceUser.handle spaceUser )
        , ( "displayName", Encode.string <| SpaceUser.displayName spaceUser )
        ]


filesView : PostEditor -> Html msg
filesView (PostEditor { files }) =
    viewUnless (List.isEmpty files) <|
        div [ class "flex flex-wrap pb-2" ] <|
            List.map fileView files


fileView : File -> Html msg
fileView file =
    let
        wrapperClass =
            "flex relative flex-none items-center mr-2 px-2 py-2 bg-grey rounded no-underline"

        icon =
            div [ class "mr-2" ] [ File.icon Color.DustyBlue file ]
    in
    case File.getState file of
        File.Staged ->
            div [ class wrapperClass ]
                [ icon
                , div [ class "text-sm font-italic text-dusty-blue" ] [ text "Pending..." ]
                ]

        File.Uploading percentage ->
            div [ class wrapperClass ]
                [ icon
                , div [ class "text-sm font-italic text-dusty-blue" ] [ text "Uploading..." ]
                , div
                    [ class "absolute pin-l pin-b h-1 rounded-full w-full bg-blue transition-w"
                    , style "width" (percentageToWidth percentage)
                    ]
                    []
                ]

        File.Uploaded id url ->
            a
                [ href url
                , target "_blank"
                , class wrapperClass
                , rel "tooltip"
                , title "Download file"
                ]
                [ icon
                , div [ class "text-sm font-bold text-dusty-blue truncate" ] [ text (File.getName file) ]
                ]

        File.UploadError ->
            div [ class wrapperClass ]
                [ div [ class "text-sm font-bold text-red" ] [ text "Upload error" ]
                ]


percentageToWidth : Int -> String
percentageToWidth percentage =
    String.fromInt percentage ++ "%"
