module IdentityMapTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (string)
import IdentityMap
import Test exposing (..)


type alias TestRecord =
    { id : String
    , name : String
    , fetchedAt : Int
    }


tests : Test
tests =
    describe "IdentityMap.get"
        [ fuzz2 string string "returns the record from the map if exists" <|
            \id name ->
                let
                    record =
                        TestRecord id name 0

                    map =
                        record
                            |> IdentityMap.set IdentityMap.init

                    default =
                        TestRecord id "Stale" 0
                in
                    default
                        |> IdentityMap.get map
                        |> .name
                        |> Expect.equal name
        , fuzz2 string string "returns the default if not in the map" <|
            \id name ->
                let
                    record =
                        TestRecord id name 0

                    map =
                        TestRecord "other" "other" 0
                            |> IdentityMap.set IdentityMap.init
                in
                    record
                        |> IdentityMap.get map
                        |> .name
                        |> Expect.equal name
        , fuzz2 string string "returns the default if its newer than whats in the map" <|
            \id name ->
                let
                    record =
                        TestRecord id "Newer name" 1

                    map =
                        TestRecord id name 0
                            |> IdentityMap.set IdentityMap.init
                in
                    record
                        |> IdentityMap.get map
                        |> .name
                        |> Expect.equal "Newer name"
        ]
