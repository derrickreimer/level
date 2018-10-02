module PostEditor exposing (PostEditor, expand, getBody, getId, init, isExpanded, setBody)

import Id exposing (Id)


type PostEditor
    = PostEditor Internal


type alias Internal =
    { id : Id
    , body : String
    , isExpanded : Bool
    , isSubmitting : Bool
    }



-- API


init : Id -> PostEditor
init id =
    PostEditor (Internal id "" False False)


getId : PostEditor -> Id
getId (PostEditor internal) =
    "post-editor-" ++ internal.id


expand : PostEditor -> PostEditor
expand (PostEditor internal) =
    PostEditor { internal | isExpanded = True }


isExpanded : PostEditor -> Bool
isExpanded (PostEditor internal) =
    internal.isExpanded


getBody : PostEditor -> String
getBody (PostEditor internal) =
    internal.body


setBody : String -> PostEditor -> PostEditor
setBody newBody (PostEditor internal) =
    PostEditor { internal | body = newBody }
