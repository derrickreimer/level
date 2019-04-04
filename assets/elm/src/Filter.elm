module Filter exposing (all, any)


any : List (a -> Bool) -> a -> Bool
any funs val =
    List.any (\fun -> fun val) funs


all : List (a -> Bool) -> a -> Bool
all funs val =
    List.all (\fun -> fun val) funs
