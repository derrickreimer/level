module Page.Room
    exposing
        ( Model
        , Msg
        , fetchRoom
        , buildModel
        , loaded
        , view
        , update
        , receiveMessage
        , subscriptions
        )

import Task exposing (Task)
import Http
import Json.Decode as Decode
import Html exposing (..)
import Html.Events exposing (on, onWithOptions, defaultOptions, onInput, onClick)
import Html.Attributes exposing (..)
import Dom exposing (focus)
import Dom.Scroll
import Date exposing (Date)
import Time exposing (Time, second, millisecond)
import Data.User exposing (User, UserConnection)
import Data.Room exposing (Room, RoomMessageConnection, RoomMessageEdge, RoomMessage)
import Data.Session exposing (Session)
import Query.Room
import Query.RoomMessages
import Mutation.CreateRoomMessage as CreateRoomMessage
import Ports exposing (ScrollParams)
import Util exposing (last, formatTime, formatTimeWithoutMeridian, formatDateTime, formatDay, onSameDay, onEnter)
import Icons exposing (privacyIcon)
import Color


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


{-| Builds a Task to fetch a room by slug.
-}
fetchRoom : Session -> String -> Task Http.Error Query.Room.Response
fetchRoom session slug =
    Query.Room.request session.apiToken (Query.Room.Params slug)
        |> Http.toTask


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
    | MessageSubmitResponse (Result Http.Error RoomMessage)
    | PreviousMessagesFetched (Result Http.Error Query.RoomMessages.Response)
    | Tick Time
    | ScrollPositionReceived Decode.Value
    | NoOp


update : Msg -> Session -> Model -> ( Model, Cmd Msg )
update msg session model =
    case msg of
        ComposerBodyChanged newBody ->
            ( { model | composerBody = newBody }, Cmd.none )

        MessageSubmitted ->
            let
                params =
                    CreateRoomMessage.Params model.room model.composerBody

                request =
                    CreateRoomMessage.request session.apiToken params
            in
                if isSendDisabled model then
                    ( model, Cmd.none )
                else
                    ( { model | isSubmittingMessage = True }
                    , Http.send MessageSubmitResponse request
                    )

        MessageSubmitResponse (Ok message) ->
            ( { model
                | isSubmittingMessage = False
                , composerBody = ""
              }
            , Cmd.none
            )

        MessageSubmitResponse (Err _) ->
            -- TODO: implement this
            ( model, Cmd.none )

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
                ( model, Ports.getScrollPosition args )

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
                                        ( modelWithPosition, Cmd.none )

                            _ ->
                                ( model, Cmd.none )

                    Err _ ->
                        ( model, Cmd.none )

        PreviousMessagesFetched (Ok response) ->
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
                        ( { model
                            | messages = newConnection
                            , isFetchingMessages = False
                          }
                        , Ports.scrollTo (ScrollParams "messages" anchorId offset)
                        )

                Query.RoomMessages.NotFound ->
                    ( { model | isFetchingMessages = False }, Cmd.none )

        PreviousMessagesFetched (Err _) ->
            ( { model | isFetchingMessages = False }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


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
fetchPreviousMessages : Session -> Model -> ( Model, Cmd Msg )
fetchPreviousMessages session model =
    case model.messages.pageInfo.endCursor of
        Just endCursor ->
            if model.messages.pageInfo.hasNextPage == True && model.isFetchingMessages == False then
                let
                    params =
                        Query.RoomMessages.Params model.room.id endCursor 20

                    request =
                        Query.RoomMessages.request session.apiToken params
                in
                    ( { model | isFetchingMessages = True }, Http.send PreviousMessagesFetched request )
            else
                ( model, Cmd.none )

        Nothing ->
            ( model, Cmd.none )


{-| Append a new message to the room message connection when it is received.
-}
receiveMessage : RoomMessage -> Model -> ( Model, Cmd Msg )
receiveMessage message model =
    let
        pageInfo =
            model.messages.pageInfo

        edges =
            RoomMessageEdge message :: model.messages.edges

        newMessages =
            RoomMessageConnection edges pageInfo
    in
        ( { model | messages = newMessages }, scrollToBottom "messages" )



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
                "Add a description..."
            else
                model.room.description

        icon =
            case model.room.subscriberPolicy of
                Data.Room.InviteOnly ->
                    span [ class "page-head__title-icon" ]
                        [ privacyIcon (Color.rgba 255 255 255 0.5) 18
                        ]

                _ ->
                    text ""
    in
        div [ id "main", class "main main--room" ]
            [ div [ class "page-head" ]
                [ div [ class "page-head__header" ]
                    [ div [ class "page-head__title" ]
                        [ h2 [ class "page-head__title-text" ] [ text model.room.name ]
                        , icon
                        ]
                    , div [ class "page-head__controls" ] []
                    ]
                , p [ class "page-head__description" ] [ text description ]
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
    "https://pbs.twimg.com/profile_images/852639806475583488/ZIHg4A21_400x400.jpg"


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
