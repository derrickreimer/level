module IdentityMapTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (string)
import IdentityMap
import Test exposing (..)


type alias TestRecord =
    { id : String
    , name : String
    }


tests : Test
tests =
    describe "IdentityMap.get"
        [ fuzz2 string string "returns the record from the map if exists" <|
            \id name ->
                let
                    record =
                        TestRecord id name

                    map =
                        IdentityMap.init
                            |> IdentityMap.set record

                    default =
                        TestRecord id "Stale"
                in
                    map
                        |> IdentityMap.get default
                        |> .name
                        |> Expect.equal name
        , fuzz2 string string "returns the default if not in the map" <|
            \id name ->
                let
                    record =
                        TestRecord id name

                    map =
                        IdentityMap.init
                            |> IdentityMap.set (TestRecord "other" "other")
                in
                    map
                        |> IdentityMap.get record
                        |> .name
                        |> Expect.equal name
        ]
