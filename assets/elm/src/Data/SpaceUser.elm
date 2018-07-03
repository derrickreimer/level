module Data.SpaceUser
    exposing
        ( SpaceUser
        , Role(..)
        , fragment
        , spaceUserDecoder
        , roleDecoder
        )

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
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


roleDecoder : Decode.Decoder Role
roleDecoder =
    let
        convert : String -> Decode.Decoder Role
        convert raw =
            case raw of
                "MEMBER" ->
                    Decode.succeed Member

                "OWNER" ->
                    Decode.succeed Owner

                _ ->
                    Decode.fail "Role not valid"
    in
        Decode.string
            |> Decode.andThen convert


spaceUserDecoder : Decode.Decoder SpaceUser
spaceUserDecoder =
    Pipeline.decode SpaceUser
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "firstName" Decode.string
        |> Pipeline.required "lastName" Decode.string
        |> Pipeline.required "role" roleDecoder
