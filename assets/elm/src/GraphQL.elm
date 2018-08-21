module GraphQL exposing (Document, Fragment, fragmentName, request, serializeDocument, toDocument, toFragment)

import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Regex
import Session exposing (Session)
import Set



-- TYPES


type Fragment
    = Fragment String (List Fragment)


type Document
    = Document String (List String)



-- CONSTRUCTORS


toFragment : String -> List Fragment -> Fragment
toFragment body referencedFragments =
    Fragment body referencedFragments


toDocument : String -> List Fragment -> Document
toDocument operation fragments =
    Document operation (flatten fragments)


fragmentName : Fragment -> String
fragmentName (Fragment body _) =
    let
        regex =
            Maybe.withDefault Regex.never <|
                Regex.fromString "fragment ([A-Za-z]+)"

        matches =
            Regex.findAtMost 1 regex body
    in
    case matches of
        { submatches } :: _ ->
            case submatches of
                (Just name) :: _ ->
                    name

                _ ->
                    "Unknown"

        _ ->
            "Unknown"



-- TASKS


request : Document -> Maybe Encode.Value -> Decode.Decoder a -> Session -> Http.Request a
request document maybeVariables decoder session =
    let
        requestBody =
            Encode.encode 0 (buildRequestBody document maybeVariables)
    in
    Http.request
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ session.token) ]
        , url = "/graphql"
        , body = Http.stringBody "application/json" requestBody
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


serializeDocument : Document -> String
serializeDocument (Document body fragments) =
    (body :: fragments)
        |> List.map normalize
        |> String.join "\n"


buildRequestBody : Document -> Maybe Encode.Value -> Encode.Value
buildRequestBody document maybeVariables =
    let
        query =
            serializeDocument document
    in
    case maybeVariables of
        Nothing ->
            Encode.object
                [ ( "query", Encode.string query ) ]

        Just variables ->
            Encode.object
                [ ( "query", Encode.string query )
                , ( "variables", variables )
                ]



-- HELPERS


uniq : List comparable -> List comparable
uniq list =
    list
        |> Set.fromList
        |> Set.toList


flatten : List Fragment -> List String
flatten fragments =
    let
        toList : Fragment -> List String
        toList fragment =
            case fragment of
                Fragment body [] ->
                    [ body ]

                Fragment body referencedFragments ->
                    referencedFragments
                        |> List.map toList
                        |> List.concat
                        |> (::) body
    in
    fragments
        |> List.map toList
        |> List.concat
        |> uniq


normalize : String -> String
normalize value =
    let
        lines =
            value
                |> String.lines

        firstLine =
            lines
                |> List.head
                |> Maybe.withDefault ""

        tailPadding =
            lines
                |> List.tail
                |> Maybe.withDefault []
                |> List.map String.toList
                |> List.map (countPadding 0)
                |> List.minimum
                |> Maybe.withDefault 0
    in
    lines
        |> List.tail
        |> Maybe.withDefault []
        |> List.map (String.dropLeft tailPadding)
        |> (::) firstLine
        |> String.join "\n"


countPadding : Int -> List Char -> Int
countPadding count list =
    case list of
        [ ' ' ] ->
            count + 1

        ' ' :: tl ->
            countPadding (count + 1) tl

        _ ->
            count
