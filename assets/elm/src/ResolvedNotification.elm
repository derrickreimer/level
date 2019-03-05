module ResolvedNotification exposing (Event(..), ResolvedNotification, addManyToRepo, addToRepo, decoder, resolve, unresolve)

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
    = PostCreated (Maybe ResolvedPost)
    | PostClosed (Maybe ResolvedPost)
    | PostReopened (Maybe ResolvedPost)
    | ReplyCreated (Maybe ResolvedReply)
    | PostReactionCreated (Maybe ResolvedPostReaction)
    | ReplyReactionCreated (Maybe ResolvedReplyReaction)


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
                        (field "post" (maybe ResolvedPost.decoder))

                "PostClosedNotification" ->
                    Decode.map PostClosed
                        (field "post" (maybe ResolvedPost.decoder))

                "PostReopenedNotification" ->
                    Decode.map PostReopened
                        (field "post" (maybe ResolvedPost.decoder))

                "ReplyCreatedNotification" ->
                    Decode.map ReplyCreated
                        (field "reply" (maybe ResolvedReply.decoder))

                "PostReactionCreatedNotification" ->
                    Decode.map PostReactionCreated
                        (field "reaction" (maybe ResolvedPostReaction.decoder))

                "ReplyReactionCreatedNotification" ->
                    Decode.map ReplyReactionCreated
                        (field "reaction" (maybe ResolvedReplyReaction.decoder))

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
                PostCreated (Just resolvedPost) ->
                    ResolvedPost.addToRepo resolvedPost repo

                PostClosed (Just resolvedPost) ->
                    ResolvedPost.addToRepo resolvedPost repo

                PostReopened (Just resolvedPost) ->
                    ResolvedPost.addToRepo resolvedPost repo

                ReplyCreated (Just resolvedReply) ->
                    ResolvedReply.addToRepo resolvedReply repo

                PostReactionCreated (Just resolvedReaction) ->
                    ResolvedPostReaction.addToRepo resolvedReaction repo

                ReplyReactionCreated (Just resolvedReaction) ->
                    ResolvedReplyReaction.addToRepo resolvedReaction repo

                _ ->
                    repo
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
                        Notification.PostCreated maybePostId ->
                            maybePostId
                                |> Maybe.map (ResolvedPost.resolve repo)
                                |> Maybe.map PostCreated

                        Notification.PostClosed maybePostId ->
                            maybePostId
                                |> Maybe.map (ResolvedPost.resolve repo)
                                |> Maybe.map PostClosed

                        Notification.PostReopened maybePostId ->
                            maybePostId
                                |> Maybe.map (ResolvedPost.resolve repo)
                                |> Maybe.map PostReopened

                        Notification.ReplyCreated maybeReplyId ->
                            maybeReplyId
                                |> Maybe.map (ResolvedReply.resolve repo)
                                |> Maybe.map ReplyCreated

                        Notification.PostReactionCreated maybePostReaction ->
                            maybePostReaction
                                |> Maybe.map (ResolvedPostReaction.resolve repo)
                                |> Maybe.map PostReactionCreated

                        Notification.ReplyReactionCreated maybeReplyReaction ->
                            maybeReplyReaction
                                |> Maybe.map (ResolvedReplyReaction.resolve repo)
                                |> Maybe.map ReplyReactionCreated
            in
            Maybe.map2 ResolvedNotification
                (Just notification)
                maybeEvent

        Nothing ->
            Nothing


unresolve : ResolvedNotification -> Id
unresolve resolvedNotification =
    Notification.id resolvedNotification.notification
