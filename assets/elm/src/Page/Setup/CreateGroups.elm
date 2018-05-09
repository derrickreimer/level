module Page.Setup.CreateGroups exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


-- MODEL


type alias Model =
    { firstName : String
    , isSubmitting : Bool
    }


buildModel : String -> Model
buildModel firstName =
    Model firstName False



-- UPDATE


type Msg
    = Loaded



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto py-24 max-w-430px leading-normal text-dusty-blue-darker" ]
            [ h2 [ class "mb-6 font-extrabold text-2xl" ] [ text ("Welcome to Level, " ++ model.firstName ++ "!") ]
            , p [ class "mb-6" ] [ text "To kick things off, let’s create some groups. We've assembled some common ones to choose from, but you can always create more later." ]
            , p [ class "mb-6" ] [ text "Select the groups you'd like to create:" ]
            , div [ class "mb-6" ]
                [ label [ class "control checkbox mb-2" ]
                    [ input [ type_ "checkbox", class "checkbox" ] []
                    , span [ class "control-indicator" ] []
                    , text "Announcements"
                    ]
                , label [ class "control checkbox mb-2" ]
                    [ input [ type_ "checkbox", class "checkbox" ] []
                    , span [ class "control-indicator" ] []
                    , text "Engineering"
                    ]
                , label [ class "control checkbox mb-2" ]
                    [ input [ type_ "checkbox", class "checkbox" ] []
                    , span [ class "control-indicator" ] []
                    , text "Support"
                    ]
                , label [ class "control checkbox mb-2" ]
                    [ input [ type_ "checkbox", class "checkbox" ] []
                    , span [ class "control-indicator" ] []
                    , text "Marketing"
                    ]
                , label [ class "control checkbox mb-2" ]
                    [ input [ type_ "checkbox", class "checkbox" ] []
                    , span [ class "control-indicator" ] []
                    , text "Random"
                    ]
                ]
            , button [ class "btn btn-blue" ] [ text "Create these groups" ]
            ]
        ]
