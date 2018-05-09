module Page.Setup.CreateGroups exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


-- MODEL


type alias Model =
    { spaceId : String
    , firstName : String
    , isSubmitting : Bool
    , selectedGroups : List String
    }


buildModel : String -> String -> Model
buildModel spaceId firstName =
    Model spaceId firstName False [ "Announcements" ]


defaultGroups : List String
defaultGroups =
    [ "Announcements", "Engineering", "Marketing", "Support", "Random" ]



-- UPDATE


type Msg
    = GroupToggled String
    | Submit


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        groups =
            model.selectedGroups
    in
        case msg of
            GroupToggled name ->
                if List.member name groups then
                    ( { model | selectedGroups = remove name groups }, Cmd.none )
                else
                    ( { model | selectedGroups = name :: groups }, Cmd.none )

            Submit ->
                ( model, Cmd.none )


remove : String -> List String -> List String
remove name list =
    List.filter (\item -> not (item == name)) list



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto py-24 max-w-430px leading-normal text-dusty-blue-darker" ]
            [ h2 [ class "mb-6 font-extrabold text-2xl" ] [ text ("Welcome to Level, " ++ model.firstName ++ "!") ]
            , p [ class "mb-6" ] [ text "To kick things off, let’s create some groups. We've assembled some common ones to choose from, but you can always create more later." ]
            , p [ class "mb-6" ] [ text "Select the groups you'd like to create:" ]
            , div [ class "mb-6" ] (List.map (groupCheckbox model.selectedGroups) defaultGroups)
            , button [ class "btn btn-blue", onClick Submit ] [ text "Create these groups" ]
            ]
        ]


groupCheckbox : List String -> String -> Html Msg
groupCheckbox selectedGroups name =
    label [ class "control checkbox mb-2" ]
        [ input
            [ type_ "checkbox"
            , class "checkbox"
            , onClick (GroupToggled name)
            , checked (List.member name selectedGroups)
            ]
            []
        , span [ class "control-indicator" ] []
        , text name
        ]
