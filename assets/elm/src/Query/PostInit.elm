module Query.PostInit exposing (Response, request)

import Component.Post
import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import NewRepo exposing (NewRepo)
import Post exposing (Post)
import Reply exposing (Reply)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : String
    , spaceId : String
    , bookmarkIds : List String
    , postId : String
    , replyIds : Connection String
    , repo : NewRepo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , post : Post
    , author : SpaceUser
    , groups : List Group
    , replies : Connection Reply
    }


document : Document
document =
    GraphQL.toDocument
        """
        query PostInit(
          $spaceSlug: String!
          $postId: ID!
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            bookmarks {
              ...GroupFields
            }
            space {
              ...SpaceFields
              post(id: $postId) {
                ...PostFields
                replies(last: 20) {
                  ...ReplyConnectionFields
                }
              }
            }
          }
        }
        """
        [ SpaceUser.fragment
        , Space.fragment
        , Group.fragment
        , Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : String -> String -> Maybe Encode.Value
variables spaceSlug postId =
    Just <|
        Encode.object
            [ ( "spaceSlug", Encode.string spaceSlug )
            , ( "postId", Encode.string postId )
            ]


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map7 Data
            SpaceUser.decoder
            (field "space" Space.decoder)
            (field "bookmarks" (list Group.decoder))
            (Decode.at [ "space", "post" ] Post.decoder)
            (Decode.at [ "space", "post", "author" ] SpaceUser.decoder)
            (Decode.at [ "space", "post", "groups" ] (list Group.decoder))
            (Decode.at [ "space", "post", "replies" ] (Connection.decoder Reply.decoder))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            NewRepo.empty
                |> NewRepo.setSpace data.space
                |> NewRepo.setSpaceUser data.viewer
                |> NewRepo.setSpaceUser data.author
                |> NewRepo.setGroups data.groups
                |> NewRepo.setGroups data.bookmarks
                |> NewRepo.setPost data.post
                |> NewRepo.setReplies (Connection.toList data.replies)

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.bookmarks)
                (Post.id data.post)
                (Connection.map Reply.id data.replies)
                repo
    in
    ( session, resp )


request : String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceSlug postId session =
    GraphQL.request document (variables spaceSlug postId) decoder
        |> Session.request session
        |> Task.map buildResponse
