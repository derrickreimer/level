module DigestSettings exposing (DigestSettings, decoder, fragment, isEnabled, toggle)

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder)


type DigestSettings
    = DigestSettings Data


type alias Data =
    { isEnabled : Bool
    }



-- PROPERTIES


isEnabled : DigestSettings -> Bool
isEnabled (DigestSettings data) =
    data.isEnabled


toggle : DigestSettings -> DigestSettings
toggle (DigestSettings data) =
    DigestSettings { data | isEnabled = not data.isEnabled }



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment DigestSettingsFields on DigestSettings {
              isEnabled
            }
            """
    in
    GraphQL.toFragment queryBody []



-- DECODERS


decoder : Decoder DigestSettings
decoder =
    Decode.map DigestSettings <|
        Decode.map Data (Decode.field "isEnabled" Decode.bool)
