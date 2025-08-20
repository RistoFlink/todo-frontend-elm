module Api exposing (..)

import Http
import Json.Encode as Encode
import Todo exposing (..)
import Url.Builder as Url

-- Config
baseUrl : String
baseUrl = 
    "http://todo-api-haskell.railway.internal:8080"

-- Endpoints
getTodos :
    { completed : Maybe Bool
    , priority : Maybe Priority
    , limit : Maybe Int
    , offset : Maybe Int
    , sort : Maybe String
    , search : Maybe String
    }
    -> (Result Http.Error TodoResponse -> msg)
    -> Cmd msg
getTodos params toMsg =
    let
        queryParams =
            List.filterMap identity
                [ Maybe.map (\completed -> Url.string "completed" (boolToString completed)) params.completed
                , Maybe.map (\priority -> Url.string "priority" (priorityToString priority)) params.priority
                , Maybe.map (\limit -> Url.string "limit" (intToString limit)) params.limit
                , Maybe.map (\offset -> Url.string "offset" (intToString offset)) params.offset
                , Maybe.map (\sort -> Url.string "sort" sort) params.sort
                , Maybe.map (\search -> Url.string "search" search) params.search
                ]

        url =
            Url.crossOrigin baseUrl [ "todos" ] queryParams
    in
    Http.get
        { url = url
        , expect = Http.expectJson toMsg todoResponseDecoder
        }

getTodoById : Int -> (Result Http.Error Todo -> msg) -> Cmd msg
getTodoById id toMsg = 
    let
        url =
            Url.crossOrigin baseUrl [ "todos", String.fromInt id ] []
    in
    Http.get
        { url = url
        , expect = Http.expectJson toMsg todoDecoder
        }

createTodo : CreateTodoPayload -> (Result Http.Error Todo -> msg) -> Cmd msg
createTodo payload toMsg =
    let
        url =
            Url.crossOrigin baseUrl [ "todos" ] []
    in
    Http.post
        { url = url
        , body = Http.jsonBody (createTodoPayloadEncoder payload)
        , expect = Http.expectJson toMsg todoDecoder
        }

updateTodo : Int -> CreateTodoPayload -> (Result Http.Error Todo -> msg) -> Cmd msg
updateTodo id payload toMsg =
    let
        url =
            Url.crossOrigin baseUrl [ "todos", String.fromInt id ] []
    in
    Http.request
        { method = "PUT"
        , headers = []
        , url = url
        , body = Http.jsonBody (createTodoPayloadEncoder payload)
        , expect = Http.expectJson toMsg todoDecoder
        , timeout = Nothing
        , tracker = Nothing
        }

updateTodoCompletion : Int -> Bool -> (Result Http.Error Todo -> msg) -> Cmd msg
updateTodoCompletion id completed toMsg =
    let
        url =
            Url.crossOrigin baseUrl [ "todos", String.fromInt id ] []
        
        -- Create a minimal payload that only updates completion status
        payload =
            Encode.object
                [ ("completed", Encode.bool completed) ]
    in
    Http.request
        { method = "PUT"
        , headers = []
        , url = url
        , body = Http.jsonBody payload
        , expect = Http.expectJson toMsg todoDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


deleteTodo : Int -> (Result Http.Error () -> msg) -> Cmd msg
deleteTodo id toMsg =
    let
        url =
            Url.crossOrigin baseUrl [ "todos", String.fromInt id ] []
    in
    Http.request
        { method = "DELETE"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectWhatever toMsg
        , timeout = Nothing
        , tracker = Nothing
        }

getTodoStats : (Result Http.Error TodoStats -> msg) -> Cmd msg
getTodoStats toMsg =
    let
        url =
            Url.crossOrigin baseUrl [ "todos", "stats" ] []
    in
    Http.get
        { url = url
        , expect = Http.expectJson toMsg todoStatsDecoder
        }

-- Helper functions
boolToString : Bool -> String
boolToString bool =
    if bool then
        "true"
    else
        "false"

intToString : Int -> String
intToString =
    String.fromInt
