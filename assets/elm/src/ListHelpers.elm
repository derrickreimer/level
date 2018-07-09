module ListHelpers
    exposing
        ( last
        , size
        , getById
        , insertUniqueById
        , memberById
        , updateById
        , removeById
        )

import List


-- TYPES


type alias Identifiable a =
    { a | id : String }



-- HELPERS


{-| Gets the last item from a list.

    last [1, 2, 3] == Just 3
    last [] == Nothing

-}
last : List a -> Maybe a
last =
    List.foldl (Just >> always) Nothing


{-| Computes the size of a list.

    size [1,2,3] == 3
    size [] == 0

-}
size : List a -> Int
size =
    List.foldl (\_ t -> t + 1) 0



-- IDENTIFIABLE OPERATIONS


{-| Finds an item in list by id.

    getById "1" [{ id = "1" }, { id = "2" }] == Just { id = "1" }

-}
getById : String -> List (Identifiable a) -> Maybe (Identifiable a)
getById id list =
    List.filter (\a -> a.id == id) list
        |> List.head


{-| Prepends an item to a list if there does not exist a list element with
the same id.

    insertUniqueById { id = "1" } [{ id = "1" }] == [{ id = "1" }]
    insertUniqueById { id = "1" } [{ id = "2" }] == [{ id = "1" }, { id = "2" }]

-}
insertUniqueById : Identifiable a -> List (Identifiable a) -> List (Identifiable a)
insertUniqueById item list =
    if memberById item list then
        list
    else
        item :: list


{-| Determines whether an item is in the list with the same id.

    memberById { id = "1" } [{ id = "1" }] == True
    memberById { id = "1" } [{ id = "2" }] == False

-}
memberById : Identifiable a -> List (Identifiable a) -> Bool
memberById item list =
    case getById item.id list of
        Just _ ->
            True

        _ ->
            False


{-| Updates an item with a given id.

    updateById { "id" = "1", name = "Derrick"}
        [ { id = "1", name = "Jack" }
        , { id = "2", name = "Jill" }
        ]
    == [ { id = "1", name = "Derrick" }
       , { id = "2", name = "Jill" }
       ]

-}
updateById : Identifiable a -> List (Identifiable a) -> List (Identifiable a)
updateById newItem items =
    let
        replacer ({ id } as currentItem) =
            if newItem.id == id then
                newItem
            else
                currentItem
    in
        List.map replacer items


{-| Filters out items from list with a given id.

    removeById "1" [{ id = "1" }, { id = "2" }] == [{ id = "2" }]

-}
removeById : String -> List (Identifiable a) -> List (Identifiable a)
removeById id =
    List.filter (\a -> not (a.id == id))
