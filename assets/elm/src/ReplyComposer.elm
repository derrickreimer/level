module ReplyComposer
    exposing
        ( ReplyComposer
        , Mode(..)
        , init
        , getBody
        , setBody
        , isExpanded
        , isSubmitting
        , expand
        , stayExpanded
        , blurred
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
    , mode : Mode
    }


type Mode
    = Autocollapse
    | AlwaysExpanded



-- API


init : Mode -> ReplyComposer
init mode =
    let
        isExpanded =
            case mode of
                Autocollapse ->
                    False

                AlwaysExpanded ->
                    True
    in
        ReplyComposer (Data "" isExpanded False mode)


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


stayExpanded : ReplyComposer -> ReplyComposer
stayExpanded (ReplyComposer data) =
    ReplyComposer { data | mode = AlwaysExpanded, isExpanded = True }


blurred : ReplyComposer -> ReplyComposer
blurred (ReplyComposer data) =
    if data.body == "" && data.mode == Autocollapse then
        ReplyComposer { data | isExpanded = False }
    else
        ReplyComposer data


submitting : ReplyComposer -> ReplyComposer
submitting (ReplyComposer data) =
    ReplyComposer { data | isSubmitting = True }


notSubmitting : ReplyComposer -> ReplyComposer
notSubmitting (ReplyComposer data) =
    ReplyComposer { data | isSubmitting = False }


unsubmittable : ReplyComposer -> Bool
unsubmittable (ReplyComposer data) =
    (data.body == "") || data.isSubmitting
