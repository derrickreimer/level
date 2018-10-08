module ReplyComposer exposing (Mode(..), ReplyComposer, blurred, escaped, expand, getBody, init, isExpanded, isSubmitting, notSubmitting, setBody, setFiles, stayExpanded, submitting, unsubmittable)

import File exposing (File)



-- TYPES


type ReplyComposer
    = ReplyComposer Data


type alias Data =
    { body : String
    , isExpanded : Bool
    , isSubmitting : Bool
    , mode : Mode
    , files : List File
    }


type Mode
    = Autocollapse
    | AlwaysExpanded



-- API


init : Mode -> ReplyComposer
init mode =
    let
        expanded =
            case mode of
                Autocollapse ->
                    False

                AlwaysExpanded ->
                    True
    in
    ReplyComposer (Data "" expanded False mode [])


getBody : ReplyComposer -> String
getBody (ReplyComposer { body }) =
    body


setBody : String -> ReplyComposer -> ReplyComposer
setBody newBody (ReplyComposer data) =
    ReplyComposer { data | body = newBody }


isExpanded : ReplyComposer -> Bool
isExpanded (ReplyComposer data) =
    data.isExpanded


isSubmitting : ReplyComposer -> Bool
isSubmitting (ReplyComposer data) =
    data.isSubmitting


expand : ReplyComposer -> ReplyComposer
expand (ReplyComposer data) =
    ReplyComposer { data | isExpanded = True }


stayExpanded : ReplyComposer -> ReplyComposer
stayExpanded (ReplyComposer data) =
    ReplyComposer { data | mode = AlwaysExpanded, isExpanded = True }


blurred : ReplyComposer -> ReplyComposer
blurred (ReplyComposer data) =
    -- if data.body == "" && data.mode == Autocollapse then
    --     ReplyComposer { data | isExpanded = False }
    -- else
    ReplyComposer data


escaped : ReplyComposer -> ReplyComposer
escaped (ReplyComposer data) =
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


setFiles : List File -> ReplyComposer -> ReplyComposer
setFiles newFiles (ReplyComposer data) =
    ReplyComposer { data | files = newFiles }
