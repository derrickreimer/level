module Tutorial exposing (Tutorial, currentStep, decoder, fragment, isComplete, key)

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, bool, field, int, string)


type Tutorial
    = Tutorial Data


type alias Data =
    { key : String
    , currentStep : Int
    , isComplete : Bool
    }


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment TutorialFields on Tutorial {
          key
          currentStep
          isComplete
        }
        """
        []



-- ACCESSORS


key : Tutorial -> String
key (Tutorial data) =
    data.key


currentStep : Tutorial -> Int
currentStep (Tutorial data) =
    data.currentStep


isComplete : Tutorial -> Bool
isComplete (Tutorial data) =
    data.isComplete



-- DECODERS


decoder : Decoder Tutorial
decoder =
    Decode.map Tutorial <|
        Decode.map3 Data
            (field "key" string)
            (field "currentStep" int)
            (field "isComplete" bool)
