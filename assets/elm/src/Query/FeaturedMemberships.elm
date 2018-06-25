module Query.FeaturedMemberships exposing (request, Params, Response)

import Session exposing (Session)
import Data.GroupMembership exposing (GroupMembership, groupMembershipDecoder)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import GraphQL


type alias Params =
    { spaceId : String
    , groupId : String
    }


type alias Response =
    List GroupMembership


query : String
query =
    """
      query GetFeaturedMemberships(
        $spaceId: ID!
        $groupId: ID!
      ) {
        space(id: $spaceId) {
          group(id: $groupId) {
            featuredMemberships {
              spaceUser {
                id
                firstName
                lastName
                role
              }
            }
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "spaceId", Encode.string params.spaceId )
        , ( "groupId", Encode.string params.groupId )
        ]


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "space", "group", "featuredMemberships" ] (Decode.list groupMembershipDecoder)


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request query (Just (variables params)) decoder
