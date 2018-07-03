module GraphQL exposing (Fragment, Document, fragment, document, request, compileDocument)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Session exposing (Session)
import Set


-- TYPES


type Fragment
    = Fragment String (List Fragment)


type Document
    = Document String (List String)



-- CONSTRUCTORS


fragment : String -> List Fragment -> Fragment
fragment body referencedFragments =
    Fragment body referencedFragments


document : String -> List Fragment -> Document
document operation fragments =
    Document operation (flatten fragments)



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


compileDocument : Document -> String
compileDocument document =
    case document of
        Document body fragments ->
            (body :: fragments)
                |> List.map normalize
                |> String.join "\n"


buildRequestBody : Document -> Maybe Encode.Value -> Encode.Value
buildRequestBody document maybeVariables =
    let
        query =
            compileDocument document
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
