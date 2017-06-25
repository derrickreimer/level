module Signup exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Regex exposing (regex)


main : Program Never Model Msg
main =
    Html.beginnerProgram
        { model = model
        , view = view
        , update = update
        }



-- MODEL


type alias Model =
    { team_name : String
    , slug : String
    , username : String
    , email : String
    , password : String
    }


model : Model
model =
    Model "" "" "" "" ""



-- UPDATE


type Msg
    = TeamName String
    | Slug String
    | Username String
    | Email String
    | Password String


update : Msg -> Model -> Model
update msg model =
    case msg of
        TeamName val ->
            { model | team_name = val, slug = (slugify val) }

        Slug val ->
            { model | slug = val }

        Username val ->
            { model | username = val }

        Email val ->
            { model | email = val }

        Password val ->
            { model | password = val }


slugify : String -> String
slugify teamName =
    teamName
        |> String.toLower
        |> (Regex.replace Regex.All (regex "[^a-z0-9]+") (\_ -> "-"))
        |> (Regex.replace Regex.All (regex "(^-|-$)") (\_ -> ""))



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "auth-form" ]
        [ h2 [ class "auth-form__heading" ] [ text "Sign up for Bridge" ]
        , div [ class "auth-form__form" ]
            [ textField TeamName (FormField "text" "team_name" "Team Name" model.team_name)
            , div [ class "form-field" ]
                [ label [ for "slug", class "form-label" ] [ text "URL" ]
                , div [ class "slug-field" ]
                    [ div [ class "slug-field__domain" ] [ text "bridge.chat/" ]
                    , input [ id "slug", type_ "text", class "text-field slug-field__slug", name "slug", value model.slug, onInput Slug ] []
                    ]
                ]
            , textField Username (FormField "text" "username" "Username" model.username)
            , textField Email (FormField "email" "email" "Email Address" model.email)
            , textField Password (FormField "password" "password" "Password" model.password)
            , div [ class "form-controls" ]
                [ button [ type_ "submit", class "button button--primary button--full" ] [ text "Sign up" ] ]
            ]
        , div [ class "auth-form__footer" ]
            [ p []
                [ text "Already have an account? "
                , a [ href "#" ] [ text "Sign in" ]
                , text "."
                ]
            ]
        ]


type alias FormField =
    { type_ : String
    , name : String
    , label : String
    , value : String
    }


textField : (String -> msg) -> FormField -> Html msg
textField msg field =
    div [ class "form-field" ]
        [ label [ for field.name, class "form-label" ] [ text field.label ]
        , input [ id field.name, type_ field.type_, class "text-field text-field--full", name field.name, value field.value, onInput msg ] []
        ]
