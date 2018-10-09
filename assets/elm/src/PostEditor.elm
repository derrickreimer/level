module PostEditor exposing
    ( PostEditor, init
    , setBody, expand, collapse, setToSubmitting, setNotSubmitting, setErrors, clearErrors, setFiles
    , getId, getBody, getFiles, getErrors, isExpanded, isSubmitting, isSubmittable, isUnsubmittable
    , wrapper
    )

{-| Holds state for the post editor.


# Types

@docs PostEditor, init


# Setters

@docs setBody, expand, collapse, setToSubmitting, setNotSubmitting, setErrors, clearErrors, setFiles


# Getters

@docs getId, getBody, getFiles, getErrors, isExpanded, isSubmitting, isSubmittable, isUnsubmittable


# Views

@docs wrapper

-}

import File exposing (File)
import Html exposing (Html)
import Html.Events exposing (on)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import ValidationError exposing (ValidationError)


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



-- SETTERS


setBody : String -> PostEditor -> PostEditor
setBody newBody (PostEditor internal) =
    PostEditor { internal | body = newBody }


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


setErrors : List ValidationError -> PostEditor -> PostEditor
setErrors errors (PostEditor internal) =
    PostEditor { internal | errors = errors }


clearErrors : PostEditor -> PostEditor
clearErrors (PostEditor internal) =
    PostEditor { internal | errors = [] }


setFiles : List File -> PostEditor -> PostEditor
setFiles newFiles (PostEditor internal) =
    PostEditor { internal | files = newFiles }



-- GETTERS


getId : PostEditor -> Id
getId (PostEditor internal) =
    internal.id


getBody : PostEditor -> String
getBody (PostEditor internal) =
    internal.body


getFiles : PostEditor -> List File
getFiles (PostEditor internal) =
    internal.files


getErrors : PostEditor -> List ValidationError
getErrors (PostEditor internal) =
    internal.errors


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



-- VIEW


wrapper : (List File -> msg) -> List (Html msg) -> Html msg
wrapper toFileAddedMsg children =
    Html.node "post-composer"
        [ on "fileAdded" (Decode.map toFileAddedMsg filesDecoder) ]
        children


filesDecoder : Decoder (List File)
filesDecoder =
    Decode.at [ "target", "files" ] (Decode.list File.decoder)
