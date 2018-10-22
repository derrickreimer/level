module Actor exposing (Actor(..), ActorId(..), avatar, decoder, displayName, fragment, idDecoder)

{-| An actor represents either a "space user" or "space bot".
-}

import Avatar
import GraphQL exposing (Fragment)
import Html exposing (Html)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, string)
import SpaceBot exposing (SpaceBot)
import SpaceUser exposing (SpaceUser)



-- TYPES


type Actor
    = User SpaceUser
    | Bot SpaceBot


type ActorId
    = UserId Id
    | BotId Id



-- ACCESSORS


displayName : Actor -> String
displayName actor =
    case actor of
        User user ->
            SpaceUser.displayName user

        Bot bot ->
            SpaceBot.displayName bot


avatar : Avatar.Size -> Actor -> Html msg
avatar size actor =
    case actor of
        User user ->
            SpaceUser.avatar size user

        Bot bot ->
            SpaceBot.avatar size bot



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment ActorFields on Actor {
              __typename
              ... on SpaceUser {
                ...SpaceUserFields
              }
              ... on SpaceBot {
                ...SpaceBotFields
              }
            }
            """
    in
    GraphQL.toFragment queryBody
        [ SpaceUser.fragment
        , SpaceBot.fragment
        ]



-- DECODERS


idDecoder : Decoder ActorId
idDecoder =
    let
        convert typename =
            case typename of
                "SpaceUser" ->
                    Decode.map UserId (field "id" Id.decoder)

                "SpaceBot" ->
                    Decode.map BotId (field "id" Id.decoder)

                _ ->
                    Decode.fail "author not valid"
    in
    field "__typename" string
        |> Decode.andThen convert


decoder : Decoder Actor
decoder =
    let
        convert typename =
            case typename of
                "SpaceUser" ->
                    Decode.map User SpaceUser.decoder

                "SpaceBot" ->
                    Decode.map Bot SpaceBot.decoder

                _ ->
                    Decode.fail "actor not valid"
    in
    field "__typename" string
        |> Decode.andThen convert
