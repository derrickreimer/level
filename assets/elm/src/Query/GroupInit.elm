module Query.GroupInit exposing (Params, Response, task)

import Date exposing (Date)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Task exposing (Task)
import Connection exposing (Connection)
import Data.Group exposing (Group)
import Data.GroupMembership exposing (GroupMembership, GroupMembershipState)
import Data.Post exposing (Post)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Params =
    { spaceId : String
    , groupId : String
    }


type alias Response =
    { group : Group
    , state : GroupMembershipState
    , posts : Connection Post
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
                ...PostConnectionFields
              }
            }
          }
        }
        """
        [ Data.GroupMembership.fragment
        , Data.Group.fragment
        , Connection.fragment "PostConnection" Data.Post.fragment
        ]


variables : Params -> Maybe Encode.Value
variables params =
    Just <|
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
            |> Pipeline.custom (Decode.at [ "posts" ] (Connection.decoder Data.Post.decoder))
            |> Pipeline.custom (Decode.at [ "featuredMemberships" ] (Decode.list Data.GroupMembership.decoder))
            |> Pipeline.custom (Decode.succeed now)
        )


request : Date -> Params -> Session -> Http.Request Response
request now params =
    GraphQL.request document (variables params) (decoder now)


task : String -> String -> Session -> Date -> Task Session.Error ( Session, Response )
task spaceId groupId session now =
    Params spaceId groupId
        |> request now
        |> Session.request session
