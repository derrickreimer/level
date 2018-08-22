module ListHelpers exposing (getBy, insertUniqueBy, last, memberBy, removeBy, size, takeLast, uniqueBy, updateBy)

import List



-- HELPERS


{-| Gets the last item from a list.

    last [ 1, 2, 3 ] == Just 3

    last [] == Nothing

-}
last : List a -> Maybe a
last =
    List.foldl (Just >> always) Nothing


{-| Take the last _n_ members of a list.

    takeLast 2 [ 1, 2, 3, 4 ] == [ 3, 4 ]

-}
takeLast : Int -> List a -> List a
takeLast n list =
    list
        |> List.reverse
        |> List.take n
        |> List.reverse


{-| Computes the size of a list.

    size [ 1, 2, 3 ] == 3

    size [] == 0

-}
size : List a -> Int
size =
    List.foldl (\_ t -> t + 1) 0



-- COMPARABLE OPERATIONS


{-| Finds an item whose comparator evaluates to the same as the given item's.

    getBy .id "1" [ { id = "1" }, { id = "2" } ] == Just { id = "1" }

-}
getBy : (a -> comparable) -> comparable -> List a -> Maybe a
getBy comparator comparable list =
    List.filter (\a -> comparator a == comparable) list
        |> List.head


{-| Finds an item whose comparator evaluates to the same as the given item's.

    uniqueBy .id [{ id = "1" }, { id = "1" }, { "id" = "2"}] == [{ id = "1" }, { id = "2"}]

-}
uniqueBy : (a -> comparable) -> List a -> List a
uniqueBy comparator list =
    let
        func =
            \item acc ->
                if memberBy comparator item acc then
                    acc

                else
                    item :: acc
    in
    List.foldl func [] list


{-| Prepends an item to a list if there does not exist a list element whose
comparator evaluates to the same as the item's.

    insertUniqueBy .id { id = "1" } [ { id = "1" } ] == [ { id = "1" } ]

    insertUniqueBy .id { id = "1" } [ { id = "2" } ] == [ { id = "1" }, { id = "2" } ]

-}
insertUniqueBy : (a -> comparable) -> a -> List a -> List a
insertUniqueBy comparator item list =
    if List.filter (\i -> comparator i == comparator item) list |> List.isEmpty then
        item :: list

    else
        list


{-| Determines whether an item is in the list with comparator value.

    memberBy .id { id = "1" } [ { id = "1" } ] == True

    memberBy .id { id = "1" } [ { id = "2" } ] == False

-}
memberBy : (a -> comparable) -> a -> List a -> Bool
memberBy comparator item list =
    case getBy comparator (comparator item) list of
        Just _ ->
            True

        _ ->
            False


{-| Updates an item whose comparator evaluates to the same as the given item.

    updateBy .id { "id" = "1", name = "Derrick"}
        [ { id = "1", name = "Jack" }
        , { id = "2", name = "Jill" }
        ]
    == [ { id = "1", name = "Derrick" }
       , { id = "2", name = "Jill" }
       ]

-}
updateBy : (a -> comparable) -> a -> List a -> List a
updateBy comparator newItem items =
    let
        replacer currentItem =
            if comparator currentItem == comparator newItem then
                newItem

            else
                currentItem
    in
    List.map replacer items


{-| Filters out items whose comparator evaluates to the same as the item's.

    removeBy .id { id = "1" } [ { id = "1" }, { id = "2" } ] == [ { id = "2" } ]

-}
removeBy : (a -> comparable) -> a -> List a -> List a
removeBy comparator item list =
    List.filter (\a -> not (comparator a == comparator item)) list
