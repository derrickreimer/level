module ResolvedAuthor exposing (ResolvedAuthor, actor, addToRepo, avatarConfig, decoder, displayName, fragment, handle, overrides, resolve, unresolve)

import Actor exposing (Actor)
import Author exposing (Author)
import Avatar
import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, field, maybe, string)
import Repo exposing (Repo)



-- TYPES


type ResolvedAuthor
    = ResolvedAuthor Data


type alias Data =
    { actor : Actor
    , overrides : Overrides
    }


type alias Overrides =
    { displayName : Maybe String
    , initials : Maybe String
    , avatarColor : Maybe String
    }



-- ACCESSORS


actor : ResolvedAuthor -> Actor
actor (ResolvedAuthor data) =
    data.actor


overrides : ResolvedAuthor -> Overrides
overrides (ResolvedAuthor data) =
    data.overrides


displayName : ResolvedAuthor -> String
displayName (ResolvedAuthor data) =
    data.overrides.displayName
        |> Maybe.withDefault (Actor.displayName data.actor)


initials : ResolvedAuthor -> String
initials (ResolvedAuthor data) =
    data.overrides.initials
        |> Maybe.withDefault (Actor.initials data.actor)


avatarUrl : ResolvedAuthor -> Maybe String
avatarUrl (ResolvedAuthor data) =
    Actor.avatarUrl data.actor


avatarConfig : Avatar.Size -> ResolvedAuthor -> Avatar.Config
avatarConfig size author =
    let
        authorHandle =
            author
                |> actor
                |> Actor.handle

        image =
            case ( avatarUrl author, authorHandle ) of
                ( Nothing, "postbot" ) ->
                    Avatar.Postbot

                ( Just url, _ ) ->
                    Avatar.Url url

                ( Nothing, _ ) ->
                    Avatar.Initials
    in
    { size = size
    , initials = initials author
    , image = image
    }


handle : ResolvedAuthor -> String
handle (ResolvedAuthor data) =
    Actor.handle data.actor



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment AuthorFields on Author {
              actor {
                ...ActorFields
              }
              overrides {
                displayName
                initials
                avatarColor
              }
            }
            """
    in
    GraphQL.toFragment queryBody
        [ Actor.fragment
        ]



-- DECODERS


decoder : Decoder ResolvedAuthor
decoder =
    Decode.map ResolvedAuthor <|
        Decode.map2 Data
            (field "actor" Actor.decoder)
            (field "overrides" Author.overridesDecoder)



-- RESOLUTION


resolve : Repo -> Author -> Maybe ResolvedAuthor
resolve repo author =
    case Repo.getActor (Author.actorId author) repo of
        Just resolvedActor ->
            Just <| ResolvedAuthor (Data resolvedActor (Author.overrides author))

        Nothing ->
            Nothing


unresolve : ResolvedAuthor -> Author
unresolve (ResolvedAuthor data) =
    Author.init (Actor.id data.actor) data.overrides


addToRepo : ResolvedAuthor -> Repo -> Repo
addToRepo (ResolvedAuthor data) repo =
    Repo.setActor data.actor repo
