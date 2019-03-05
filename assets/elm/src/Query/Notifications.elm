module Query.Notifications exposing (Response, request, variables)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Notification
import NotificationStateFilter exposing (NotificationStateFilter)
import Repo exposing (Repo)
import ResolvedNotification exposing (ResolvedNotification)
import Session exposing (Session)
import Task exposing (Task)
import Time exposing (Posix)


type alias Response =
    { resolvedNotifications : List ResolvedNotification
    , repo : Repo
    }


type alias Data =
    { resolvedNotifications : List ResolvedNotification
    }


document : Document
document =
    GraphQL.toDocument
        """
        query Notifications(
          $cursor: Timestamp,
          $limit: Int,
          $orderField: NotificationOrderField,
          $orderDirection: OrderDirection,
          $state: NotificationStateFilter
        ) {
          notifications(
            cursor: $cursor,
            limit: $limit,
            orderBy: {
              field: $orderField,
              direction: $orderDirection
            },
            state: $state
          ) {
            ...NotificationFields
          }
        }
        """
        [ Notification.fragment
        ]


variables : NotificationStateFilter -> Int -> Maybe Posix -> Maybe Encode.Value
variables state limit maybeCursor =
    let
        pairs =
            case maybeCursor of
                Just cursor ->
                    [ ( "cursor", Encode.int (Time.posixToMillis cursor) )
                    , ( "limit", Encode.int limit )
                    , ( "orderField", Encode.string "OCCURRED_AT" )
                    , ( "orderDirection", Encode.string "DESC" )
                    , ( "state", Encode.string <| NotificationStateFilter.toEnum state )
                    ]

                Nothing ->
                    [ ( "limit", Encode.int limit )
                    , ( "orderField", Encode.string "OCCURRED_AT" )
                    , ( "orderDirection", Encode.string "DESC" )
                    , ( "state", Encode.string <| NotificationStateFilter.toEnum state )
                    ]
    in
    Just (Encode.object pairs)


decoder : Decoder Data
decoder =
    Decode.at [ "data", "notifications" ] <|
        Decode.map Data
            (list ResolvedNotification.decoder)


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> ResolvedNotification.addManyToRepo data.resolvedNotifications

        resp =
            Response
                data.resolvedNotifications
                repo
    in
    ( session, resp )


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    GraphQL.request document maybeVariables decoder
        |> Session.request session
        |> Task.map buildResponse
