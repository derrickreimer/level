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
        label [ class "ml-2 flex items-center h-9 px-3 rounded-full bg-grey-light focus-within-outline" ]
            [ div [ class "mr-2" ] [ Icons.search ]
            , input
                [ id (FieldEditor.getNodeId config.editor)
                , type_ "text"
                , class "bg-transparent text-base text-dusty-blue-dark no-outline"
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
            [ class "ml-2 flex items-center justify-center w-9 h-9 rounded-full bg-transparent hover:bg-grey transition-bg"
            , rel "tooltip"
            , Html.Attributes.title "Search"
            , onClick config.expandMsg
            ]
            [ Icons.search ]
