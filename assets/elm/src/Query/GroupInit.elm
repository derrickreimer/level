module Query.GroupInit exposing (Params, Response, task)

import Date exposing (Date)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Task exposing (Task)
import Data.Group exposing (Group)
import Data.GroupMembership exposing (GroupMembership, GroupMembershipState)
import Data.PageInfo
import Data.Post
import Data.PostConnection exposing (PostConnection)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Params =
    { spaceId : String
    , groupId : String
    }


type alias Response =
    { group : Group
    , state : GroupMembershipState
    , posts : PostConnection
    , featuredMemberships : List GroupMembership
    , now : Date
    }


document : Document
document =
    GraphQL.document
        """
        query GroupInit(
          $spaceId: ID!
          $groupId: ID!
        ) {
          space(id: $spaceId) {
            group(id: $groupId) {
              ...GroupFields
              membership {
                state
              }
              featuredMemberships {
                ...GroupMembershipFields
              }
              posts(first: 20) {
                edges {
                  node {
                    ...PostFields
                  }
                }
                pageInfo {
                  ...PageInfoFields
                }
              }
            }
          }
        }
        """
        [ Data.GroupMembership.fragment
        , Data.Group.fragment
        , Data.Post.fragment
        , Data.PageInfo.fragment
        ]


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "spaceId", Encode.string params.spaceId )
        , ( "groupId", Encode.string params.groupId )
        ]


decoder : Date -> Decoder Response
decoder now =
    Decode.at [ "data", "space", "group" ] <|
        (Pipeline.decode Response
            |> Pipeline.custom Data.Group.decoder
            |> Pipeline.custom (Decode.at [ "membership", "state" ] Data.GroupMembership.stateDecoder)
            |> Pipeline.custom (Decode.at [ "posts" ] Data.PostConnection.decoder)
            |> Pipeline.custom (Decode.at [ "featuredMemberships" ] (Decode.list Data.GroupMembership.decoder))
            |> Pipeline.custom (Decode.succeed now)
        )


request : Date -> Params -> Session -> Http.Request Response
request now params =
    GraphQL.request document (Just (variables params)) (decoder now)


task : String -> String -> Session -> Date -> Task Session.Error ( Session, Response )
task spaceId groupId session now =
    Params spaceId groupId
        |> request now
        |> Session.request session
