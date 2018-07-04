module Data.SpaceUser exposing (SpaceUser, Role(..), fragment, decoder, roleDecoder)

import Json.Decode as Decode exposing (Decoder, field, string, succeed, fail)
import GraphQL exposing (Fragment)


-- TYPES


type alias SpaceUser =
    { id : String
    , firstName : String
    , lastName : String
    , role : Role
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
    Decode.map4 SpaceUser
        (field "id" string)
        (field "firstName" string)
        (field "lastName" string)
        (field "role" roleDecoder)
