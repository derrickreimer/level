module ResolvedNotification exposing (Event(..), ResolvedNotification, addManyToRepo, addToRepo, decoder, resolve, unresolve)

import Actor exposing (Actor)
import Connection exposing (Connection)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list, maybe, string)
import Notification exposing (Notification)
import PostReaction exposing (PostReaction)
import ReplyReaction exposing (ReplyReaction)
import Repo exposing (Repo)
import ResolvedPost exposing (ResolvedPost)
import ResolvedPostReaction exposing (ResolvedPostReaction)
import ResolvedReply exposing (ResolvedReply)
import ResolvedReplyReaction exposing (ResolvedReplyReaction)


type alias ResolvedNotification =
    { notification : Notification
    , event : Event
    }


type Event
    = PostCreated ResolvedPost
    | PostClosed ResolvedPost Actor
    | PostReopened ResolvedPost Actor
    | ReplyCreated ResolvedReply
    | PostReactionCreated ResolvedPostReaction
    | ReplyReactionCreated ResolvedReplyReaction


decoder : Decoder ResolvedNotification
decoder =
    Decode.map2 ResolvedNotification
        Notification.decoder
        eventDecoder


eventDecoder : Decoder Event
eventDecoder =
    let
        decodeByTypename : String -> Decoder Event
        decodeByTypename typename =
            case typename of
                "PostCreatedNotification" ->
                    Decode.map PostCreated
                        (field "post" ResolvedPost.decoder)

                "PostClosedNotification" ->
                    Decode.map2 PostClosed
                        (field "post" ResolvedPost.decoder)
                        (field "actor" Actor.decoder)

                "PostReopenedNotification" ->
                    Decode.map2 PostReopened
                        (field "post" ResolvedPost.decoder)
                        (field "actor" Actor.decoder)

                "ReplyCreatedNotification" ->
                    Decode.map ReplyCreated
                        (field "reply" ResolvedReply.decoder)

                "PostReactionCreatedNotification" ->
                    Decode.map PostReactionCreated
                        (field "reaction" ResolvedPostReaction.decoder)

                "ReplyReactionCreatedNotification" ->
                    Decode.map ReplyReactionCreated
                        (field "reaction" ResolvedReplyReaction.decoder)

                _ ->
                    Decode.fail "event not recognized"
    in
    Decode.field "__typename" string
        |> Decode.andThen decodeByTypename


addToRepo : ResolvedNotification -> Repo -> Repo
addToRepo resolvedNotification repo =
    let
        newRepo =
            case resolvedNotification.event of
                PostCreated resolvedPost ->
                    ResolvedPost.addToRepo resolvedPost repo

                PostClosed resolvedPost actor ->
                    repo
                        |> ResolvedPost.addToRepo resolvedPost
                        |> Repo.setActor actor

                PostReopened resolvedPost actor ->
                    repo
                        |> ResolvedPost.addToRepo resolvedPost
                        |> Repo.setActor actor

                ReplyCreated resolvedReply ->
                    ResolvedReply.addToRepo resolvedReply repo

                PostReactionCreated resolvedReaction ->
                    ResolvedPostReaction.addToRepo resolvedReaction repo

                ReplyReactionCreated resolvedReaction ->
                    ResolvedReplyReaction.addToRepo resolvedReaction repo
    in
    Repo.setNotification resolvedNotification.notification newRepo


addManyToRepo : List ResolvedNotification -> Repo -> Repo
addManyToRepo resolvedNotifications repo =
    List.foldr addToRepo repo resolvedNotifications


resolve : Repo -> Id -> Maybe ResolvedNotification
resolve repo id =
    case Repo.getNotification id repo of
        Just notification ->
            let
                maybeEvent =
                    case Notification.event notification of
                        Notification.PostCreated postId ->
                            Maybe.map PostCreated
                                (ResolvedPost.resolve repo postId)

                        Notification.PostClosed postId actorId ->
                            Maybe.map2 PostClosed
                                (ResolvedPost.resolve repo postId)
                                (Repo.getActor actorId repo)

                        Notification.PostReopened postId actorId ->
                            Maybe.map2 PostReopened
                                (ResolvedPost.resolve repo postId)
                                (Repo.getActor actorId repo)

                        Notification.ReplyCreated replyId ->
                            Maybe.map ReplyCreated
                                (ResolvedReply.resolve repo replyId)

                        Notification.PostReactionCreated postReaction ->
                            Maybe.map PostReactionCreated
                                (ResolvedPostReaction.resolve repo postReaction)

                        Notification.ReplyReactionCreated replyReaction ->
                            Maybe.map ReplyReactionCreated
                                (ResolvedReplyReaction.resolve repo replyReaction)
            in
            Maybe.map2 ResolvedNotification
                (Just notification)
                maybeEvent

        Nothing ->
            Nothing


unresolve : ResolvedNotification -> Id
unresolve resolvedNotification =
    Notification.id resolvedNotification.notification
