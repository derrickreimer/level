module Query.FeaturedMemberships exposing (Response, request)

import Task exposing (Task)
import Session exposing (Session)
import Data.GroupMembership exposing (GroupMembership)
import Data.SpaceUser
import Json.Decode as Decode
import Json.Encode as Encode
import Task
import GraphQL exposing (Document)


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


variables : String -> String -> Maybe Encode.Value
variables spaceId groupId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "groupId", Encode.string groupId )
            ]


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "space", "group", "featuredMemberships" ]
        (Decode.list Data.GroupMembership.decoder)


request : String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId groupId session =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId) decoder
