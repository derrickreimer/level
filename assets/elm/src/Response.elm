module Response exposing (Response(..), map)


type Response a
    = Found a
    | NotFound


map : (a -> b) -> Response a -> Response b
map fun resp =
    case resp of
        Found a ->
            Found (fun a)

        NotFound ->
            NotFound
