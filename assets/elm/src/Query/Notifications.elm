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
    { resolvedNotifications : Connection ResolvedNotification
    , repo : Repo
    }


type alias Data =
    { resolvedNotifications : Connection ResolvedNotification
    }


document : Document
document =
    GraphQL.toDocument
        """
        query Notifications(
          $after: Timestamp,
          $first: Int,
          $orderField: NotificationOrderField,
          $orderDirection: OrderDirection,
          $state: NotificationStateFilter
        ) {
          notifications(
            after: $after,
            first: $first,
            orderBy: {
              field: $orderField,
              direction: $orderDirection
            },
            filters: {
              state: $state
            }
          ) {
            ...NotificationConnectionFields
          }
        }
        """
        [ Connection.fragment "NotificationConnection" Notification.fragment
        ]


variables : NotificationStateFilter -> Int -> Maybe Posix -> Maybe Encode.Value
variables state limit maybeCursor =
    let
        pairs =
            case maybeCursor of
                Just cursor ->
                    [ ( "after", Encode.int (Time.posixToMillis cursor) )
                    , ( "first", Encode.int limit )
                    , ( "orderField", Encode.string "OCCURRED_AT" )
                    , ( "orderDirection", Encode.string "DESC" )
                    , ( "state", Encode.string <| NotificationStateFilter.toEnum state )
                    ]

                Nothing ->
                    [ ( "first", Encode.int limit )
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
            (Connection.decoder ResolvedNotification.decoder)


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> ResolvedNotification.addManyToRepo (Connection.toList data.resolvedNotifications)

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
