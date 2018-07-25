module ListHelpers
    exposing
        ( last
        , takeLast
        , size
        , getById
        , insertUniqueBy
        , memberById
        , updateById
        , removeBy
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


{-| Take the last *n* members of a list.

    takeLast 2 [1,2,3,4] == [3,4]

-}
takeLast : Int -> List a -> List a
takeLast n list =
    list
        |> List.reverse
        |> List.take n
        |> List.reverse


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


{-| Prepends an item to a list if there does not exist a list element whose
comparator evaluates to the same as the item's.

    insertUniqueBy .id { id = "1" } [{ id = "1" }] == [{ id = "1" }]
    insertUniqueBy .id { id = "1" } [{ id = "2" }] == [{ id = "1" }, { id = "2" }]

-}
insertUniqueBy : (a -> comparable) -> a -> List a -> List a
insertUniqueBy comparator item list =
    if List.filter (\i -> comparator i == comparator item) list |> List.isEmpty then
        item :: list
    else
        list


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


{-| Filters out items whose comparator evaluates to the same as the item's.

    removeBy .id [{ id = "1" }, { id = "2" }] == [{ id = "2" }]

-}
removeBy : (a -> comparable) -> a -> List a -> List a
removeBy comparator item list =
    List.filter (\a -> comparator a == comparator item) list
