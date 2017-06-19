module Signup exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)

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

-- TODO: scrub invalid characters, sub whitespace for "-"
slugify : String -> String
slugify teamName =
  String.toLower(teamName)


-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ h2 [ class "auth-form__heading" ] [ text "Sign up for Bridge" ]
    , div [ class "auth-form__form" ]
      [ textField TeamName "text" "team_name" "Team Name" model.team_name
      , div [ class "form-field" ]
        [ label [ for "slug", class "form-label" ] [ text "URL" ]
        , div [ class "slug-field" ]
          [ div [ class "slug-field__domain" ] [ text "bridge.chat/" ]
          , input [ id "slug", type_ "text", class "text-field slug-field__slug", name "slug", value model.slug, onInput Slug ] []
          ]
        ]
      , textField Username "text" "username" "Username" model.username
      , textField Email "email" "email" "Email Address" model.email
      , textField Password "password" "password" "Password" model.password
      , div [ class "form-controls"]
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

textField : (String -> msg) -> String -> String -> String -> String -> Html msg
textField msg fieldType fieldName labelText val =
  div [ class "form-field" ]
    [ label [ for fieldName, class "form-label" ] [ text labelText ]
    , input [ id fieldName, type_ fieldType, class "text-field text-field--full", name fieldName, value val, onInput msg ] []
    ]
