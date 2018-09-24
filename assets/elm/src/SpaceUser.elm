module SpaceUser exposing (Record, Role(..), SpaceUser, avatar, decoder, displayName, firstName, fragment, getCachedData, id, lastName, roleDecoder, userId)

import Avatar
import GraphQL exposing (Fragment)
import Html exposing (Html)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, fail, field, int, maybe, string, succeed)



-- TYPES


type SpaceUser
    = SpaceUser Record


type alias Record =
    { id : Id
    , userId : Id
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


id : SpaceUser -> Id
id (SpaceUser data) =
    data.id


userId : SpaceUser -> Id
userId (SpaceUser data) =
    data.userId


firstName : SpaceUser -> String
firstName (SpaceUser data) =
    data.firstName


lastName : SpaceUser -> String
lastName (SpaceUser data) =
    data.lastName


displayName : SpaceUser -> String
displayName (SpaceUser data) =
    data.firstName ++ " " ++ data.lastName


avatar : Avatar.Size -> SpaceUser -> Html msg
avatar size (SpaceUser data) =
    Avatar.personAvatar size data



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
            (field "id" Id.decoder)
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
