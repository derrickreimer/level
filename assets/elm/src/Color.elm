module Color exposing (Color(..), toHex)


type Color
    = Turquoise
    | DustyBlue


toHex : Color -> String
toHex color =
    case color of
        Turquoise ->
            "#12c1d5"

        DustyBlue ->
            "#8a98a5"
