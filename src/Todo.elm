module Todo exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Time

-- Types

type Priority
    = High
    | Medium
    | Low

type alias Todo =
    { id : Int
    , title : String
    , completed : Bool
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    , dueDate : Maybe Time.Posix
    , priority : Priority
    }

type alias TodoResponse =
    { todos : List Todo
    , totalCount : Int
    , limit : Int
    , offset : Int
    }

type alias CreateTodoPayload =
    { title: String
    , completed: Maybe Bool
    , dueDate: Maybe Time.Posix
    , priority : Priority
    }

type alias TodoStats =
    { priorityStats : PriorityStats
    , completionStats : CompletionStats
    , overdueCount : Int
    , dueSoonCount : Int
    }

type alias PriorityStats =
    { high : Int
    , medium : Int
    , low : Int
    , priorityTotal : Int
    }

type alias CompletionStats = 
    { completed : Int
    , incomplete : Int
    , completionTotal : Int
    }

-- JSON decoders
priorityDecoder : Decoder Priority
priorityDecoder =
    Decode.string |> Decode.andThen (\str ->
        case str of
            "High" -> Decode.succeed High
            "Medium" -> Decode.succeed Medium
            "Low" -> Decode.succeed Low
            _ -> Decode.fail ("Unknown priority: " ++ str)
    )

todoDecoder : Decoder Todo
todoDecoder =
    Decode.map7 Todo
        (Decode.field "id" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "completed" Decode.bool)
        (Decode.field "createdAt" (Decode.map Time.millisToPosix Decode.int))
        (Decode.field "updatedAt" (Decode.map Time.millisToPosix Decode.int))
        (Decode.field "dueDate" (Decode.nullable (Decode.map Time.millisToPosix Decode.int)))
        (Decode.field "priority" priorityDecoder)

todoResponseDecoder : Decoder TodoResponse
todoResponseDecoder =
    Decode.map4 TodoResponse
        (Decode.field "todos" (Decode.list todoDecoder))
        (Decode.field "totalCount" Decode.int)
        (Decode.field "limit" Decode.int)
        (Decode.field "offset" Decode.int)

priorityStatsDecoder : Decoder PriorityStats
priorityStatsDecoder = 
    Decode.map4 PriorityStats
        (Decode.field "high" Decode.int)
        (Decode.field "medium" Decode.int)
        (Decode.field "low" Decode.int)
        (Decode.field "priorityTotal" Decode.int)

completionStatsDecoder : Decoder CompletionStats
completionStatsDecoder =
    Decode.map3 CompletionStats
        (Decode.field "completed" Decode.int)
        (Decode.field "incomplete" Decode.int)
        (Decode.field "completionTotal" Decode.int)

todoStatsDecoder : Decoder TodoStats
todoStatsDecoder =
    Decode.map4 TodoStats
        (Decode.field "priorityStats" priorityStatsDecoder)
        (Decode.field "completionStats" completionStatsDecoder)
        (Decode.field "overdueCount" Decode.int)
        (Decode.field "dueSoonCount" Decode.int)

-- JSON encoders
priorityEncoder : Priority -> Encode.Value
priorityEncoder priority =
    Encode.string (priorityToString priority)

createTodoPayloadEncoder : CreateTodoPayload -> Encode.Value
createTodoPayloadEncoder payload =
    Encode.object
        [ ("createTitle", Encode.string payload.title)
        , ("completed",
            case payload.completed of
                Just completed -> Encode.bool completed
                Nothing -> Encode.null
        )
        , ("dueDate",
            case payload.dueDate of
                Just date -> Encode.int (Time.posixToMillis date)
                Nothing -> Encode.null
        )
        , ("priority", priorityEncoder payload.priority)
        ]

-- Helper functions
priorityToString : Priority -> String
priorityToString priority =
    case priority of
        High -> "High"
        Medium -> "Medium"
        Low -> "Low"