module TestHelpers exposing (success, userFixture)

{-| A collection of helper functions for tests.


# Utilities

@docs success

-}

import Data.User


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



-- FIXTURES


userFixture : Data.User.User
userFixture =
    Data.User.User "999" "Derrick" "Reimer"
