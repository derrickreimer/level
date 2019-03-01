module ResolvedNotification exposing (Event(..), ResolvedNotification, addToRepo, decoder, resolve, unresolve)

import Connection exposing (Connection)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list, string)
import Notification exposing (Notification)
import PostReaction exposing (PostReaction)
import ReplyReaction exposing (ReplyReaction)
import Repo exposing (Repo)
import ResolvedPost exposing (ResolvedPost)
import ResolvedReply exposing (ResolvedReply)


type alias ResolvedNotification =
    { notification : Notification
    , event : Event
    }


type Event
    = PostCreated ResolvedPost
    | PostClosed ResolvedPost
    | PostReopened ResolvedPost
    | ReplyCreated ResolvedReply
    | PostReactionCreated PostReaction
    | ReplyReactionCreated ReplyReaction


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
                    Decode.map PostClosed
                        (field "post" ResolvedPost.decoder)

                "PostReopenedNotification" ->
                    Decode.map PostReopened
                        (field "post" ResolvedPost.decoder)

                "ReplyCreatedNotification" ->
                    Decode.map ReplyCreated
                        (field "reply" ResolvedReply.decoder)

                "PostReactionCreatedNotification" ->
                    Decode.map PostReactionCreated
                        (field "reaction" PostReaction.decoder)

                "ReplyReactionCreatedNotification" ->
                    Decode.map ReplyReactionCreated
                        (field "reaction" ReplyReaction.decoder)

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

                PostClosed resolvedPost ->
                    ResolvedPost.addToRepo resolvedPost repo

                PostReopened resolvedPost ->
                    ResolvedPost.addToRepo resolvedPost repo

                ReplyCreated resolvedReply ->
                    ResolvedReply.addToRepo resolvedReply repo

                PostReactionCreated postReaction ->
                    repo

                ReplyReactionCreated replyReaction ->
                    repo
    in
    Repo.setNotification resolvedNotification.notification newRepo


resolve : Repo -> Id -> Maybe ResolvedNotification
resolve repo id =
    case Repo.getNotification id repo of
        Just notification ->
            let
                maybeEvent =
                    case Notification.event notification of
                        Notification.PostCreated postId ->
                            Maybe.map PostCreated <|
                                ResolvedPost.resolve repo postId

                        Notification.PostClosed postId ->
                            Maybe.map PostClosed <|
                                ResolvedPost.resolve repo postId

                        Notification.PostReopened postId ->
                            Maybe.map PostReopened <|
                                ResolvedPost.resolve repo postId

                        Notification.ReplyCreated replyId ->
                            Maybe.map ReplyCreated <|
                                ResolvedReply.resolve repo replyId

                        Notification.PostReactionCreated postReaction ->
                            Just <| PostReactionCreated postReaction

                        Notification.ReplyReactionCreated replyReaction ->
                            Just <| ReplyReactionCreated replyReaction
            in
            Maybe.map2 ResolvedNotification
                (Just notification)
                maybeEvent

        Nothing ->
            Nothing


unresolve : ResolvedNotification -> Id
unresolve resolvedNotification =
    Notification.id resolvedNotification.notification
