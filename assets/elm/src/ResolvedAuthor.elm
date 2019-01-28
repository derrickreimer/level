module ResolvedAuthor exposing (ResolvedAuthor, actor, addToRepo, decoder, displayName, fragment, overrides, resolve, unresolve)

import Actor exposing (Actor)
import Author exposing (Author)
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
