module Query.FeaturedMemberships exposing (request, fetch, Params, Response)

import Session exposing (Session)
import Data.GroupMembership exposing (GroupMembership)
import Data.SpaceUser
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Task
import GraphQL exposing (Document)


type alias Params =
    { spaceId : String
    , groupId : String
    }


type alias Response =
    List GroupMembership


document : Document
document =
    GraphQL.document
        """
        query GetFeaturedMemberships(
          $spaceId: ID!
          $groupId: ID!
        ) {
          space(id: $spaceId) {
            group(id: $groupId) {
              featuredMemberships {
                spaceUser {
                  ...SpaceUserFields
                }
              }
            }
          }
        }
        """
        [ Data.SpaceUser.fragment
        ]


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "spaceId", Encode.string params.spaceId )
        , ( "groupId", Encode.string params.groupId )
        ]


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "space", "group", "featuredMemberships" ]
        (Decode.list Data.GroupMembership.decoder)


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request document (Just (variables params)) decoder


fetch : Session -> (Result Session.Error ( Session, Response ) -> msg) -> Params -> Cmd msg
fetch session toMsg params =
    params
        |> request
        |> Session.request session
        |> Task.attempt toMsg
