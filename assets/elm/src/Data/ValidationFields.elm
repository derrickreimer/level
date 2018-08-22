module Data.ValidationFields exposing (fragment)

import GraphQL exposing (Fragment)


fragment : Fragment
fragment =
    GraphQL.toFragment
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
