module View.SearchBox exposing (Config, view)

import FieldEditor exposing (FieldEditor)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Vendor.Keys as Keys exposing (Modifier(..), enter, esc, onKeydown, preventDefault)


type alias Config msg =
    { editor : FieldEditor String
    , changeMsg : String -> msg
    , expandMsg : msg
    , collapseMsg : msg
    , submitMsg : msg
    }


view : Config msg -> Html msg
view config =
    if FieldEditor.isExpanded config.editor then
        label [ class "flex items-center py-2 px-3 rounded-full bg-grey-light focus-within-outline" ]
            [ div [ class "mr-2" ] [ Icons.search ]
            , input
                [ id (FieldEditor.getNodeId config.editor)
                , type_ "text"
                , class "bg-transparent text-sm text-dusty-blue-dark no-outline"
                , value (FieldEditor.getValue config.editor)
                , readonly (FieldEditor.isSubmitting config.editor)
                , onInput config.changeMsg
                , onKeydown preventDefault
                    [ ( [], esc, \event -> config.collapseMsg )
                    , ( [], enter, \event -> config.submitMsg )
                    ]
                ]
                []
            ]

    else
        button
            [ class "px-3 py-2"
            , rel "tooltip"
            , Html.Attributes.title "Search"
            , onClick config.expandMsg
            ]
            [ Icons.search ]
