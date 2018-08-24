module Query.SetupInit exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewer : SpaceUser
    , space : Space
    , bookmarkedGroups : List Group
    }


document : Document
document =
    GraphQL.toDocument
        """
        query GroupInit(
          $spaceSlug: String!
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
            }
            bookmarkedGroups {
              ...GroupFields
            }
          }
        }
        """
        [ Group.fragment
        , SpaceUser.fragment
        , Space.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceSlug =
    Just <|
        Encode.object
            [ ( "spaceSlug", Encode.string spaceSlug )
            ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        (Decode.succeed Response
            |> Pipeline.custom SpaceUser.decoder
            |> Pipeline.custom (Decode.field "space" Space.decoder)
            |> Pipeline.custom (Decode.field "bookmarkedGroups" (Decode.list Group.decoder))
        )


request : String -> Session -> Task Session.Error ( Session, Response )
request spaceSlug session =
    Session.request session <|
        GraphQL.request document (variables spaceSlug) decoder
