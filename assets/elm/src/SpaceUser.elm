module SpaceUser exposing (Record, Role(..), SpaceUser, decoder, fragment, getCachedData, id, roleDecoder)

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, fail, field, int, maybe, string, succeed)



-- TYPES


type SpaceUser
    = SpaceUser Record


type alias Record =
    { id : String
    , userId : String
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
    GraphQL.toFragment
        """
        fragment SpaceUserFields on SpaceUser {
          id
          userId
          firstName
          lastName
          handle
          role
          avatarUrl
          fetchedAt
        }
        """
        []



-- ACCESSORS


id : SpaceUser -> String
id (SpaceUser data) =
    data.id



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
        Decode.map8 Record
            (field "id" string)
            (field "userId" string)
            (field "firstName" string)
            (field "lastName" string)
            (field "handle" string)
            (field "role" roleDecoder)
            (field "avatarUrl" (maybe string))
            (field "fetchedAt" int)



-- API


getCachedData : SpaceUser -> Record
getCachedData (SpaceUser data) =
    data
