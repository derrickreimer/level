module PostEditor exposing
    ( PostEditor, init
    , getId, getBody, getErrors, setBody, setErrors, clearErrors, reset
    , isExpanded, isSubmitting, isSubmittable, isUnsubmittable, expand, collapse, setToSubmitting, setNotSubmitting
    , getFiles, getUploadIds, addFile, setFiles, setFileUploadPercentage, setFileState
    , ViewConfig, wrapper, filesView
    )

{-| Represents an editor instance for creating/editing posts and replies.


# Types

@docs PostEditor, init


# General

@docs getId, getBody, getErrors, setBody, setErrors, clearErrors, reset


# Visual Settings

@docs isExpanded, isSubmitting, isSubmittable, isUnsubmittable, expand, collapse, setToSubmitting, setNotSubmitting


# Files

@docs getFiles, getUploadIds, addFile, setFiles, setFileUploadPercentage, setFileState


# Views

@docs ViewConfig, wrapper, filesView

-}

import Color exposing (Color)
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on)
import Icons
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import ListHelpers
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


reset : PostEditor -> PostEditor
reset editor =
    editor
        |> setBody ""
        |> setNotSubmitting
        |> setFiles []
        |> clearErrors



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



-- VIEW


type alias ViewConfig msg =
    { spaceId : Id
    , onFileAdded : File -> msg
    , onFileUploadProgress : Id -> Int -> msg
    , onFileUploaded : Id -> Id -> String -> msg
    }


wrapper : ViewConfig msg -> List (Html msg) -> Html msg
wrapper config children =
    Html.node "post-editor"
        [ property "spaceId" (Id.encoder config.spaceId)
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
        ]
        children


filesView : PostEditor -> Html msg
filesView (PostEditor { files }) =
    viewUnless (List.isEmpty files) <|
        div [ class "flex flex-wrap pb-2" ] <|
            List.map fileView files


fileView : File -> Html msg
fileView file =
    div [ class "flex flex-none items-center mr-4 pb-1 border-dusty-blue rounded-full" ]
        [ div [ class "mr-2" ] [ File.icon Color.Turquoise file ]
        , div [ class "text-sm font-bold text-turquoise-dark truncate" ] [ text (File.getName file) ]
        ]
