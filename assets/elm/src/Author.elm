module Author exposing (Author, actorId, decoder, fragment, init, overrides, overridesDecoder)

import Actor exposing (ActorId)
import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, field, maybe, string)



-- TYPES


type Author
    = Author Data


type alias Data =
    { actorId : ActorId
    , overrides : Overrides
    }


type alias Overrides =
    { displayName : Maybe String
    , initials : Maybe String
    , avatarColor : Maybe String
    }


init : ActorId -> Overrides -> Author
init givenActorId givenOverrides =
    Author (Data givenActorId givenOverrides)



-- ACCESSORS


actorId : Author -> ActorId
actorId (Author data) =
    data.actorId


overrides : Author -> Overrides
overrides (Author data) =
    data.overrides



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


decoder : Decoder Author
decoder =
    Decode.map Author <|
        Decode.map2 Data
            (field "actor" Actor.idDecoder)
            (field "overrides" overridesDecoder)


overridesDecoder : Decoder Overrides
overridesDecoder =
    Decode.map3 Overrides
        (field "displayName" (maybe string))
        (field "initials" (maybe string))
        (field "avatarColor" (maybe string))
