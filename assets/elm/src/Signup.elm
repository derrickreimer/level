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
      [ div [ class "form-field" ]
        [ label [ for "team_name", class "form-label" ] [ text "Team Name" ]
        , input [ id "team_name", type_ "text", class "text-field text-field--full", name "team_name", value model.team_name, onInput TeamName ] []
        ]
      , div [ class "form-field" ]
        [ label [ for "slug", class "form-label" ] [ text "URL" ]
        , div [ class "slug-field" ]
          [ div [ class "slug-field__domain" ] [ text "bridge.chat/" ]
          , input [ id "slug", type_ "text", class "text-field slug-field__slug", name "slug", value model.slug, onInput Slug ] []
          ]
        ]
      , div [ class "form-field" ]
        [ label [ for "username", class "form-label" ] [ text "Username" ]
        , input [ id "username", type_ "text", class "text-field text-field--full", name "username", value model.username, onInput Username ] []
        ]
      , div [ class "form-field" ]
        [ label [ for "email", class "form-label" ] [ text "Email Address" ]
        , input [ id "email", type_ "email", class "text-field text-field--full", name "email", value model.email, onInput Email ] []
        ]
      , div [ class "form-field" ]
        [ label [ for "password", class "form-label" ] [ text "Password" ]
        , input [ id "password", type_ "password", class "text-field text-field--full", name "password", value model.password, onInput Password ] []
        ]
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
