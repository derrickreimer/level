module PostEditor exposing
    ( PostEditor, init
    , setBody, expand, collapse, setToSubmitting, setNotSubmitting, setErrors, clearErrors
    , getId, getBody, getErrors, isExpanded, isSubmitting
    )

{-| Holds state for the post editor.


# Types

@docs PostEditor, init


# Setters

@docs setBody, expand, collapse, setToSubmitting, setNotSubmitting, setErrors, clearErrors


# Getters

@docs getId, getBody, getErrors, isExpanded, isSubmitting

-}

import Id exposing (Id)
import ValidationError exposing (ValidationError)


type PostEditor
    = PostEditor Internal


type alias Internal =
    { id : Id
    , body : String
    , isExpanded : Bool
    , isSubmitting : Bool
    , errors : List ValidationError
    }


init : Id -> PostEditor
init id =
    PostEditor (Internal id "" False False [])



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



-- GETTERS


getId : PostEditor -> Id
getId (PostEditor internal) =
    internal.id


getBody : PostEditor -> String
getBody (PostEditor internal) =
    internal.body


getErrors : PostEditor -> List ValidationError
getErrors (PostEditor internal) =
    internal.errors


isExpanded : PostEditor -> Bool
isExpanded (PostEditor internal) =
    internal.isExpanded


isSubmitting : PostEditor -> Bool
isSubmitting (PostEditor internal) =
    internal.isSubmitting
