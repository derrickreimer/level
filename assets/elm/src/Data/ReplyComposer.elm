module Data.ReplyComposer
    exposing
        ( ReplyComposer
        , init
        , getBody
        , setBody
        , isExpanded
        , isSubmitting
        , expand
        , collapse
        , submitting
        , notSubmitting
        , unsubmittable
        )

-- TYPES


type ReplyComposer
    = ReplyComposer Data


type alias Data =
    { body : String
    , isExpanded : Bool
    , isSubmitting : Bool
    }



-- API


init : ReplyComposer
init =
    ReplyComposer (Data "" False False)


getBody : ReplyComposer -> String
getBody (ReplyComposer { body }) =
    body


setBody : String -> ReplyComposer -> ReplyComposer
setBody newBody (ReplyComposer data) =
    ReplyComposer { data | body = newBody }


isExpanded : ReplyComposer -> Bool
isExpanded (ReplyComposer { isExpanded }) =
    isExpanded


isSubmitting : ReplyComposer -> Bool
isSubmitting (ReplyComposer { isSubmitting }) =
    isSubmitting


expand : ReplyComposer -> ReplyComposer
expand (ReplyComposer data) =
    ReplyComposer { data | isExpanded = True }


collapse : ReplyComposer -> ReplyComposer
collapse (ReplyComposer data) =
    ReplyComposer { data | isExpanded = False }


submitting : ReplyComposer -> ReplyComposer
submitting (ReplyComposer data) =
    ReplyComposer { data | isSubmitting = True }


notSubmitting : ReplyComposer -> ReplyComposer
notSubmitting (ReplyComposer data) =
    ReplyComposer { data | isSubmitting = False }


unsubmittable : ReplyComposer -> Bool
unsubmittable (ReplyComposer data) =
    (data.body == "") || data.isSubmitting
