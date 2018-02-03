module Page.Room
    exposing
        ( Model
        , ExternalMsg(..)
        , Msg
        , fetchRoom
        , buildModel
        , loaded
        , view
        , update
        , receiveMessage
        , subscriptions
        )

import Color
import Date exposing (Date)
import Dom exposing (focus)
import Dom.Scroll
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onWithOptions, defaultOptions, onInput, onClick)
import Http
import Json.Decode as Decode
import Task exposing (Task)
import Time exposing (Time, second, millisecond)
import Data.User exposing (User, UserConnection)
import Data.Room exposing (Room, RoomMessageConnection, RoomMessageEdge, RoomMessage)
import Icons exposing (privacyIcon, settingsIcon)
import Mutation.CreateRoomMessage as CreateRoomMessage
import Ports exposing (ScrollParams)
import Query.Room
import Query.RoomMessages
import Route
import Session exposing (Session)
import Util exposing (last, formatTime, formatTimeWithoutMeridian, formatDateTime, formatDay, onSameDay, onEnter)


-- MODEL


type alias Model =
    { room : Room
    , messages : RoomMessageConnection
    , users : UserConnection
    , composerBody : String
    , isSubmittingMessage : Bool
    , isFetchingMessages : Bool
    , messagesScrollPosition : Maybe Ports.ScrollPosition
    }


{-| Builds a request to fetch a room by slug.
-}
fetchRoom : String -> Session -> Http.Request Query.Room.Response
fetchRoom slug session =
    Query.Room.request (Query.Room.Params slug) session


{-| Builds a model for this page based on the response from initial page request.
-}
buildModel : Query.Room.Data -> Model
buildModel data =
    Model data.room data.messages data.users "" False False Nothing


{-| Builds the task to perform post-page load.
-}
loaded : Cmd Msg
loaded =
    Cmd.batch
        [ scrollToBottom "messages"
        , focusOnComposer
        ]



-- UPDATE


type Msg
    = ComposerBodyChanged String
    | MessageSubmitted
    | Tick Time
    | ScrollPositionReceived Decode.Value
    | NoOp
    | MessageSubmitResponse (Result Session.Error ( Session, RoomMessage ))
    | PreviousMessagesFetched (Result Session.Error ( Session, Query.RoomMessages.Response ))


type ExternalMsg
    = SessionRefreshed Session
    | ExternalNoOp


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg session model =
    case msg of
        ComposerBodyChanged newBody ->
            ( ( { model | composerBody = newBody }, Cmd.none ), ExternalNoOp )

        MessageSubmitted ->
            let
                cmd =
                    CreateRoomMessage.Params model.room model.composerBody
                        |> CreateRoomMessage.request
                        |> Session.request session
                        |> Task.attempt MessageSubmitResponse
            in
                if isSendDisabled model then
                    ( ( model, Cmd.none ), ExternalNoOp )
                else
                    ( ( { model | isSubmittingMessage = True }, cmd ), ExternalNoOp )

        MessageSubmitResponse (Ok ( session, message )) ->
            ( ( { model
                    | isSubmittingMessage = False
                    , composerBody = ""
                }
              , Cmd.none
              )
            , SessionRefreshed session
            )

        MessageSubmitResponse (Err Session.Expired) ->
            redirectToLogin model

        MessageSubmitResponse (Err _) ->
            -- TODO: implement this
            ( ( model, Cmd.none ), ExternalNoOp )

        Tick _ ->
            let
                anchorId =
                    case last model.messages.edges of
                        Just edge ->
                            Just (messageAnchorId edge)

                        Nothing ->
                            Nothing

                args =
                    Ports.ScrollPositionArgs "messages" anchorId
            in
                ( ( model, Ports.getScrollPosition args ), ExternalNoOp )

        ScrollPositionReceived value ->
            let
                result =
                    Decode.decodeValue Ports.scrollPositionDecoder value
            in
                case result of
                    Ok position ->
                        case position.containerId of
                            "messages" ->
                                let
                                    modelWithPosition =
                                        { model | messagesScrollPosition = Just position }
                                in
                                    if position.fromTop <= 200 then
                                        fetchPreviousMessages session modelWithPosition
                                    else
                                        ( ( modelWithPosition, Cmd.none ), ExternalNoOp )

                            _ ->
                                ( ( model, Cmd.none ), ExternalNoOp )

                    Err _ ->
                        ( ( model, Cmd.none ), ExternalNoOp )

        PreviousMessagesFetched (Ok ( session, response )) ->
            case response of
                Query.RoomMessages.Found { messages } ->
                    let
                        edges =
                            model.messages.edges

                        anchorId =
                            case last edges of
                                Just edge ->
                                    messageAnchorId edge

                                Nothing ->
                                    ""

                        offset =
                            case model.messagesScrollPosition of
                                Just position ->
                                    case position.anchorOffset of
                                        Just offset ->
                                            position.fromTop - offset

                                        Nothing ->
                                            position.fromTop

                                Nothing ->
                                    0

                        pageInfo =
                            model.messages.pageInfo

                        newEdges =
                            List.append edges messages.edges

                        newPageInfo =
                            { pageInfo
                                | hasNextPage = messages.pageInfo.hasNextPage
                                , endCursor = messages.pageInfo.endCursor
                            }

                        newConnection =
                            RoomMessageConnection newEdges newPageInfo
                    in
                        ( ( { model
                                | messages = newConnection
                                , isFetchingMessages = False
                            }
                          , Ports.scrollTo (ScrollParams "messages" anchorId offset)
                          )
                        , SessionRefreshed session
                        )

                Query.RoomMessages.NotFound ->
                    ( ( { model | isFetchingMessages = False }, Cmd.none ), ExternalNoOp )

        PreviousMessagesFetched (Err Session.Expired) ->
            { model | isFetchingMessages = False }
                |> redirectToLogin

        PreviousMessagesFetched (Err _) ->
            ( ( { model | isFetchingMessages = False }, Cmd.none ), ExternalNoOp )

        NoOp ->
            ( ( model, Cmd.none ), ExternalNoOp )


{-| Scrolls the messages container to the most recent message.
-}
scrollToBottom : String -> Cmd Msg
scrollToBottom id =
    Task.attempt (always NoOp) <| Dom.Scroll.toBottom id


{-| Sets focus to the composer body textarea.
-}
focusOnComposer : Cmd Msg
focusOnComposer =
    Task.attempt (always NoOp) <| focus "composer-body-field"


{-| Executes a query for previous messages, updates the model to a fetching
state, and returns a model and command tuple.
-}
fetchPreviousMessages : Session -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
fetchPreviousMessages session model =
    case model.messages.pageInfo.endCursor of
        Just endCursor ->
            if model.messages.pageInfo.hasNextPage == True && model.isFetchingMessages == False then
                let
                    cmd =
                        Query.RoomMessages.Params model.room.id endCursor 20
                            |> Query.RoomMessages.request
                            |> Session.request session
                            |> Task.attempt PreviousMessagesFetched
                in
                    ( ( { model | isFetchingMessages = True }, cmd ), ExternalNoOp )
            else
                ( ( model, Cmd.none ), ExternalNoOp )

        Nothing ->
            ( ( model, Cmd.none ), ExternalNoOp )


{-| Append a new message to the room message connection when it is received.
-}
receiveMessage : RoomMessage -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
receiveMessage message model =
    let
        pageInfo =
            model.messages.pageInfo

        edges =
            RoomMessageEdge message :: model.messages.edges

        newMessages =
            RoomMessageConnection edges pageInfo
    in
        ( ( { model | messages = newMessages }, scrollToBottom "messages" ), ExternalNoOp )


redirectToLogin : Model -> ( ( Model, Cmd Msg ), ExternalMsg )
redirectToLogin model =
    ( ( model, Route.toLogin ), ExternalNoOp )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every (500 * millisecond) Tick
        , Ports.scrollPositionReceived ScrollPositionReceived
        ]



-- VIEW


view : Model -> Html Msg
view model =
    let
        description =
            if model.room.description == "" then
                text ""
            else
                text model.room.description

        icon =
            case model.room.subscriberPolicy of
                Data.Room.InviteOnly ->
                    span [ class "page-head__title-icon" ]
                        [ privacyIcon (Color.rgb 144 150 162) 18
                        ]

                _ ->
                    text ""
    in
        div [ id "main", classList [ ( "thread-page", True ), ( "thread-page--no-description", model.room.description == "" ) ] ]
            [ div [ class "page-head" ]
                [ div [ class "page-head__header" ]
                    [ div [ class "page-head__title" ]
                        [ h2 [ class "page-head__title-text" ] [ text model.room.name ]
                        , icon
                        ]
                    , div [ class "page-head__controls" ]
                        [ a [ Route.href (Route.RoomSettings model.room.id), class "button button--secondary" ]
                            [ settingsIcon (Color.rgb 144 150 162) 24
                            ]
                        ]
                    ]
                , p [ class "page-head__description" ] [ description ]
                ]
            , renderMessages model.messages
            , div [ class "composer" ]
                [ div [ class "composer__body" ]
                    [ textarea
                        [ id "composer-body-field"
                        , class "text-field text-field--muted textarea composer__body-field"
                        , onInput ComposerBodyChanged
                        , onEnter MessageSubmitted
                        , readonly (isComposerReadOnly model)
                        , value model.composerBody
                        ]
                        []
                    ]
                , div [ class "composer__controls" ]
                    [ button
                        [ class "button button--primary"
                        , disabled (isSendDisabled model)
                        , onClick MessageSubmitted
                        ]
                        [ text "Send Message" ]
                    ]
                ]
            ]


groupMessagesByDay : List RoomMessageEdge -> List ( Date, List RoomMessageEdge )
groupMessagesByDay edges =
    case edges of
        [] ->
            []

        hd :: _ ->
            let
                onDay : Date -> RoomMessageEdge -> Bool
                onDay date edge =
                    onSameDay date edge.node.insertedAt

                ( phd, ptl ) =
                    List.partition (onDay hd.node.insertedAt) edges
            in
                [ ( hd.node.insertedAt, phd ) ] ++ groupMessagesByDay ptl


groupMessagesByUser : List RoomMessageEdge -> List ( User, List RoomMessageEdge )
groupMessagesByUser edges =
    let
        reducer edge groups =
            case groups of
                [] ->
                    [ ( edge.node.user, [ edge ] ) ]

                ( hUser, hEdges ) :: tl ->
                    if edge.node.user.id == hUser.id && Util.size hEdges < 5 then
                        ( hUser, edge :: hEdges ) :: tl
                    else
                        ( edge.node.user, [ edge ] ) :: groups
    in
        List.foldr reducer [] edges


renderMessages : RoomMessageConnection -> Html Msg
renderMessages connection =
    let
        edges =
            List.reverse connection.edges
    in
        div [ id "messages", class "messages" ]
            (List.map renderTimeGroup <| groupMessagesByDay edges)


renderTimeGroup : ( Date, List RoomMessageEdge ) -> Html Msg
renderTimeGroup ( date, edges ) =
    let
        userGroups =
            groupMessagesByUser edges
    in
        div [ class "message-time-group" ]
            [ div [ class "message-time-group__head" ]
                [ span [ class "message-time-group__timestamp" ] [ text (formatDay date) ]
                ]
            , div [ class "message-time-group__messages" ] <| List.map renderUserGroup userGroups
            ]


renderUserGroup : ( User, List RoomMessageEdge ) -> Html Msg
renderUserGroup ( user, edges ) =
    case edges of
        [] ->
            text ""

        hd :: tl ->
            div [ class "message-user-group" ] <|
                (renderHeadMessage hd)
                    :: (renderTailMessages tl)


stubbedAvatarUrl : String
stubbedAvatarUrl =
    "https://pbs.twimg.com/profile_images/952064552287453185/T_QMnFac_400x400.jpg"


renderHeadMessage : RoomMessageEdge -> Html Msg
renderHeadMessage edge =
    let
        dateTime =
            formatDateTime edge.node.insertedAt

        time =
            formatTime edge.node.insertedAt
    in
        div [ class "message-head" ]
            [ img [ class "message-head__avatar", src stubbedAvatarUrl ] []
            , div [ class "message-head__contents" ]
                [ div [ class "message-head__head" ]
                    [ span [ class "message-head__name" ] [ text (Data.User.displayName edge.node.user) ]
                    , span [ class "message-head__middot" ] [ text "·" ]
                    , span [ class "message-head__timestamp", rel "tooltip", title dateTime ] [ text time ]
                    ]
                , div [ id (messageAnchorId edge), class "message-head__body" ] [ text edge.node.body ]
                ]
            ]


renderTailMessages : List RoomMessageEdge -> List (Html Msg)
renderTailMessages edges =
    let
        renderTailMessage edge =
            let
                dateTime =
                    formatDateTime edge.node.insertedAt

                time =
                    formatTimeWithoutMeridian edge.node.insertedAt
            in
                div [ class "message-tail" ]
                    [ div [ class "message-tail__timestamp", rel "tooltip", title dateTime ] [ text time ]
                    , div [ class "message-tail__contents" ]
                        [ div [ id (messageAnchorId edge), class "message-tail__body" ] [ text edge.node.body ]
                        ]
                    ]
    in
        List.map renderTailMessage edges


{-| Takes an edge from a room messages connection returns the DOM node ID for
the message.
-}
messageAnchorId : RoomMessageEdge -> String
messageAnchorId edge =
    "msg-body-" ++ edge.node.id


{-| Determines if the "Send Message" button should be disabled.

    isSendDisabled { composerBody = "" } == True
    isSendDisabled { composerBody = "I have some text" } == False
    isSendDisabled { isSubmittingMessage = True } == False

-}
isSendDisabled : Model -> Bool
isSendDisabled model =
    model.composerBody == "" || (isComposerReadOnly model)


{-| Determines if the composer textarea should be read-only.

    isComposerReadOnly { composerBody = "" } == True
    isComposerReadOnly { composerBody = "I have some text" } == False
    isComposerReadOnly { isSubmittingMessage = True } == False

-}
isComposerReadOnly : Model -> Bool
isComposerReadOnly model =
    model.isSubmittingMessage == True
