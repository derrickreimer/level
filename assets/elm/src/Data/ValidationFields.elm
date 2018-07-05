module Data.ValidationFields exposing (fragment)

import GraphQL exposing (Fragment)


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment ValidationFields on Validatable {
          success
          errors {
            attribute
            message
          }
        }
        """
        []
