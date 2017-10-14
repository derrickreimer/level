module TestHelpers exposing (success)

{-| A collection of helper functions for tests.


# Utilities

@docs success

-}

-- UTILITIES


{-| Determines if a given result is successful.

    success (Ok _) == True
    success (Err _) == False

-}
success : Result a b -> Bool
success result =
    case result of
        Ok _ ->
            True

        Err _ ->
            False
