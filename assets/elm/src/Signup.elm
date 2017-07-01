module Signup exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Regex exposing (regex)
import Http
import Json.Encode as Encode
import Json.Decode as Decode exposing (decodeString)


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { csrf_token : String
    , team_name : String
    , slug : String
    , username : String
    , email : String
    , password : String
    , errors : List ValidationError
    }


type alias Flags =
    { csrf_token : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( (initialState flags), Cmd.none )


initialState : Flags -> Model
initialState flags =
    { csrf_token = flags.csrf_token
    , team_name = ""
    , slug = ""
    , username = ""
    , email = ""
    , password = ""
    , errors = []
    }



-- UPDATE


type Msg
    = TeamName String
    | Slug String
    | Username String
    | Email String
    | Password String
    | Submit
    | Submitted (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TeamName val ->
            ( { model | team_name = val, slug = (slugify val) }, Cmd.none )

        Slug val ->
            ( { model | slug = val }, Cmd.none )

        Username val ->
            ( { model | username = val }, Cmd.none )

        Email val ->
            ( { model | email = val }, Cmd.none )

        Password val ->
            ( { model | password = val }, Cmd.none )

        Submit ->
            ( model, submit model )

        Submitted (Ok slug) ->
            ( model, Cmd.none )

        Submitted (Err (Http.BadStatus resp)) ->
            case decodeString errorDecoder resp.body of
                Ok value ->
                    ( { model | errors = value }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        Submitted (Err _) ->
            ( model, Cmd.none )


slugify : String -> String
slugify teamName =
    teamName
        |> String.toLower
        |> (Regex.replace Regex.All (regex "[^a-z0-9]+") (\_ -> "-"))
        |> (Regex.replace Regex.All (regex "(^-|-$)") (\_ -> ""))
        |> String.slice 0 20



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


errorFor : String -> List ValidationError -> Maybe String
errorFor attribute errors =
    case (List.filter (\error -> error.attribute == attribute) errors) of
        error :: _ ->
            Just error.message

        [] ->
            Nothing


view : Model -> Html Msg
view model =
    div [ class "auth-form" ]
        [ h2 [ class "auth-form__heading" ] [ text "Sign up for Bridge" ]
        , div [ class "auth-form__form" ]
            [ textField TeamName (FormField "text" "team_name" "Team Name" model.team_name) Nothing
            , div [ class "form-field" ]
                [ label [ for "slug", class "form-label" ] [ text "URL" ]
                , div [ class "slug-field" ]
                    [ div [ class "slug-field__domain" ] [ text "bridge.chat/" ]
                    , input
                        [ id "slug"
                        , type_ "text"
                        , class "text-field slug-field__slug"
                        , name "slug"
                        , value model.slug
                        , onInput Slug
                        ]
                        []
                    ]
                ]
            , textField Username (FormField "text" "username" "Username" model.username) (errorFor "username" model.errors)
            , textField Email (FormField "email" "email" "Email Address" model.email) (errorFor "email" model.errors)
            , textField Password (FormField "password" "password" "Password" model.password) (errorFor "password" model.errors)
            , div [ class "form-controls" ]
                [ button
                    [ type_ "submit"
                    , class "button button--primary button--full"
                    , onClick Submit
                    ]
                    [ text "Sign up" ]
                ]
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


textField : (String -> msg) -> FormField -> Maybe String -> Html msg
textField msg field string =
    div [ class "form-field" ]
        [ label [ for field.name, class "form-label" ] [ text field.label ]
        , input
            [ id field.name
            , type_ field.type_
            , class "text-field text-field--full"
            , name field.name
            , value field.value
            , onInput msg
            ]
            []
        , div [ class "form-errors" ] [ text <| Maybe.withDefault "" string ]
        ]



-- HTTP


type alias ErrorResponse =
    { errors : List ValidationError }


type alias ValidationError =
    { attribute : String
    , message : String
    }


submit : Model -> Cmd Msg
submit model =
    Http.send Submitted (buildRequest model)


buildRequest : Model -> Http.Request String
buildRequest model =
    postWithCsrfToken model.csrf_token "/api/teams" (buildBody model) successDecoder


postWithCsrfToken : String -> String -> Http.Body -> Decode.Decoder a -> Http.Request a
postWithCsrfToken token url body decoder =
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-Csrf-Token" token ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


buildBody : Model -> Http.Body
buildBody model =
    Http.jsonBody
        (Encode.object
            [ ( "signup"
              , Encode.object
                    [ ( "team_name", Encode.string model.team_name )
                    , ( "slug", Encode.string model.slug )
                    , ( "username", Encode.string model.username )
                    , ( "email", Encode.string model.email )
                    , ( "password", Encode.string model.password )
                    ]
              )
            ]
        )



-- DECODERS


successDecoder : Decode.Decoder String
successDecoder =
    Decode.at [ "team", "slug" ] Decode.string


errorDecoder : Decode.Decoder (List ValidationError)
errorDecoder =
    Decode.field "errors"
        (Decode.list
            (Decode.map2 ValidationError
                (Decode.field "attribute" Decode.string)
                (Decode.field "message" Decode.string)
            )
        )
