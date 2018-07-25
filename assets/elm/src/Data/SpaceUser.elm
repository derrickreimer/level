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

import Json.Decode as Decode exposing (Decoder, maybe, field, string, succeed, fail)
import GraphQL exposing (Fragment)


-- TYPES


type SpaceUser
    = SpaceUser Record


type alias Record =
    { id : String
    , firstName : String
    , lastName : String
    , role : Role
    , avatarUrl : Maybe String
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
          role
          avatarUrl
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
        Decode.map5 Record
            (field "id" string)
            (field "firstName" string)
            (field "lastName" string)
            (field "role" roleDecoder)
            (field "avatarUrl" (maybe string))



-- API


getId : SpaceUser -> String
getId (SpaceUser { id }) =
    id


getCachedData : SpaceUser -> Record
getCachedData (SpaceUser data) =
    data
