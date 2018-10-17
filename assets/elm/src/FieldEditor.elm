module FieldEditor exposing (FieldEditor, collapse, expand, getErrors, getNodeId, getValue, init, isExpanded, isSubmitting, setErrors, setIsSubmitting, setValue)

import ValidationError exposing (ValidationError)


type FieldEditor a
    = FieldEditor (Internal a)


type alias Internal a =
    { nodeId : String
    , value : a
    , isExpanded : Bool
    , isSubmitting : Bool
    , errors : List ValidationError
    }



-- API


init : String -> a -> FieldEditor a
init nodeId value =
    FieldEditor (Internal nodeId value False False [])


getNodeId : FieldEditor a -> String
getNodeId (FieldEditor internal) =
    internal.nodeId


getValue : FieldEditor a -> a
getValue (FieldEditor internal) =
    internal.value


getErrors : FieldEditor a -> List ValidationError
getErrors (FieldEditor internal) =
    internal.errors


isExpanded : FieldEditor a -> Bool
isExpanded (FieldEditor internal) =
    internal.isExpanded


isSubmitting : FieldEditor a -> Bool
isSubmitting (FieldEditor internal) =
    internal.isSubmitting


setValue : a -> FieldEditor a -> FieldEditor a
setValue newValue (FieldEditor internal) =
    FieldEditor { internal | value = newValue }


setErrors : List ValidationError -> FieldEditor a -> FieldEditor a
setErrors newErrors (FieldEditor internal) =
    FieldEditor { internal | errors = newErrors }


expand : FieldEditor a -> FieldEditor a
expand (FieldEditor internal) =
    FieldEditor { internal | isExpanded = True }


collapse : FieldEditor a -> FieldEditor a
collapse (FieldEditor internal) =
    FieldEditor { internal | isExpanded = False }


setIsSubmitting : Bool -> FieldEditor a -> FieldEditor a
setIsSubmitting truth (FieldEditor internal) =
    FieldEditor { internal | isSubmitting = truth }
