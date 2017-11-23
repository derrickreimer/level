module TestHelpers exposing (success, userFixture, roomFixture)

{-| A collection of helper functions for tests.


# Utilities

@docs success

-}

import Data.Room
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


roomFixture : Data.Room.Room
roomFixture =
    Data.Room.Room "999" "Everyone" "The cool room."
