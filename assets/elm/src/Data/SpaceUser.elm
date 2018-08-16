module Data.SpaceUser
    exposing
        ( SpaceUser
        , Record
        , Role(..)
        , fragment
        , decoder
        , roleDecoder
        , getId
        , getCachedData
        )

import Json.Decode as Decode exposing (Decoder, maybe, field, string, int, succeed, fail)
import GraphQL exposing (Fragment)


-- TYPES


type SpaceUser
    = SpaceUser Record


type alias Record =
    { id : String
    , firstName : String
    , lastName : String
    , handle : String
    , role : Role
    , avatarUrl : Maybe String
    , fetchedAt : Int
    }


type Role
    = Member
    | Owner


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment SpaceUserFields on SpaceUser {
          id
          firstName
          lastName
          handle
          role
          avatarUrl
          fetchedAt
        }
        """
        []



-- DECODERS


roleDecoder : Decoder Role
roleDecoder =
    let
        convert : String -> Decoder Role
        convert raw =
            case raw of
                "MEMBER" ->
                    succeed Member

                "OWNER" ->
                    succeed Owner

                _ ->
                    fail "Role not valid"
    in
        Decode.andThen convert string


decoder : Decoder SpaceUser
decoder =
    Decode.map SpaceUser <|
        Decode.map7 Record
            (field "id" string)
            (field "firstName" string)
            (field "lastName" string)
            (field "handle" string)
            (field "role" roleDecoder)
            (field "avatarUrl" (maybe string))
            (field "fetchedAt" int)



-- API


getId : SpaceUser -> String
getId (SpaceUser { id }) =
    id


getCachedData : SpaceUser -> Record
getCachedData (SpaceUser data) =
    data
