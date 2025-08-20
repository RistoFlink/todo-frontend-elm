module Main exposing (..)

import Api
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Todo exposing (..)
import Json.Decode

main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

type alias Model =
    { todos : List Todo
    , newTodoTitle : String
    , newTodoPriority : Priority
    , filter : Filter
    , loading : Bool
    , error : Maybe String
    , stats : Maybe TodoStats
    }

type Filter
    = All
    | Completed
    | Incomplete
    | ByPriority Priority

initialModel : Model
initialModel =
    { todos = []
    , newTodoTitle = ""
    , newTodoPriority = Medium
    , filter = All
    , loading = False
    , error = Nothing
    , stats = Nothing
    }

init : () -> ( Model, Cmd Msg)
init _ =
    ( initialModel
    , Cmd.batch
        [ loadTodos
        , loadStats
        ]
    )

type Msg
    = TodosLoaded (Result Http.Error TodoResponse)
    | StatsLoaded (Result Http.Error TodoStats)
    | NewTodoTitleChanged String
    | NewTodoPriorityChanged Priority
    | CreateTodoClicked
    | TodoCreated (Result Http.Error Todo)
    | ToggleTodoCompletion Int Bool
    | TodoToggled (Result Http.Error Todo)
    | DeleteTodoClicked Int
    | TodoDeleted (Result Http.Error ())
    | FilterChanged Filter

-- Update

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TodosLoaded (Ok response) ->
            ( { model | todos = response.todos, loading = False, error = Nothing}
            , Cmd.none
            )

        TodosLoaded (Err error) ->
            ( { model | loading = False, error = Just (httpErrorToString error) }
            , Cmd.none
            )

        StatsLoaded (Ok stats) ->
            ( { model | stats = Just stats}
            , Cmd.none
            )

        StatsLoaded (Err _) ->
            -- Don't show error for stats, just continue without them
            ( model, Cmd.none)

        NewTodoTitleChanged title ->
            ( { model | newTodoTitle = title }
            , Cmd.none
            )
        
        NewTodoPriorityChanged priority ->
            ( { model | newTodoPriority = priority }
            , Cmd.none
            )

        CreateTodoClicked ->
            let
                trimmedTitle = String.trim model.newTodoTitle
            in
            if String.isEmpty trimmedTitle then
                ( model, Cmd.none )
            else
                let
                    payload =
                        { title = trimmedTitle
                        , completed = Just False
                        , dueDate = Nothing
                        , priority = model.newTodoPriority
                        }
                in
                ( { model | loading = True }
                , Api.createTodo payload TodoCreated
                )
        
        TodoCreated (Ok todo) ->
            ( { model 
                | todos = model.todos ++ [todo]
                , newTodoTitle = ""
                , loading = False
            }
            , loadStats
            )

        TodoCreated (Err error) ->
            ( { model | loading = False, error = Just (httpErrorToString error) }
            , Cmd.none
            )

        ToggleTodoCompletion id completed ->
            case List.filter (\todo -> todo.id == id) model.todos |> List.head of
                Just currentTodo ->
                    let
                        payload = 
                            { title = currentTodo.title
                            , completed = Just completed
                            , dueDate = currentTodo.dueDate
                            , priority = currentTodo.priority
                            }
                        _ = Debug.log "Toggle payload" { id = id, completed = completed, payload = payload }
                    in
                    ( model
                    , Api.updateTodo id payload TodoToggled
                    )
                
                Nothing ->
                    ( model, Cmd.none )

        TodoToggled (Ok updatedTodo) ->
            let
                updateTodo todo =
                    if todo.id == updatedTodo.id then
                        updatedTodo
                    
                    else
                        todo
            
            in
            ( { model
                | todos = List.map updateTodo model.todos
                , loading = False
            }
            , loadStats
            )
        
        TodoToggled (Err error) -> 
            ( { model | loading = False, error = Just (httpErrorToString error) }
            , Cmd.none
            )
        
        DeleteTodoClicked id ->
            ( { model | loading = True }
            , Api.deleteTodo id TodoDeleted
            )
        
        TodoDeleted (Ok _) ->
            ( { model | loading = False }
            , Cmd.batch [ loadTodos, loadStats ]
            )
        
        TodoDeleted (Err error) ->
            ( { model | loading = False, error = Just (httpErrorToString error) }
            , Cmd.none
            )
        
        FilterChanged filter ->
            ( { model | filter = filter }
            , Cmd.none
            )

-- View
view : Model -> Html Msg
view model =
    div [ class "app-container" ]
        [ div [ class "header" ]
            [ h1 [ class "app-title" ] [ text "Todo App" ]
            , viewStats model.stats
            ]
        , div [ class "main-content" ]
            [ viewError model.error
            , viewNewTodoForm model
            , viewFilters model.filter
            , viewTodoList model
            , viewLoading model.loading
            ]
        ]

viewStats : Maybe TodoStats -> Html Msg
viewStats maybeStats =
    case maybeStats of
        Nothing ->
            text ""
        
        Just stats ->
            div [ class "stats" ]
                [ div [ class "stat" ]
                    [ div [ class "stat-icon total" ] []
                    , span [] [ text ("Total: " ++ String.fromInt stats.completionStats.completionTotal) ]
                    ]
                , div [ class "stat" ]
                    [ div [ class "stat-icon completed" ] []
                    , span [] [ text ("Completed: " ++ String.fromInt stats.completionStats.completed) ]
                    ]
                , div [ class "stat" ]
                    [ div [ class "stat-icon priority" ] []
                    , span [] [ text ("High Priority: " ++ String.fromInt stats.priorityStats.high) ]
                    ]
                ]

viewError : Maybe String -> Html Msg
viewError maybeError =
    case maybeError of
        Nothing ->
            text ""
        
        Just error ->
            div [ class "error" ] [ text ("Error: " ++ error)]

viewNewTodoForm : Model -> Html Msg
viewNewTodoForm model =
    div [ class "add-todo-section" ]
        [ div [ class "input-group" ]
            [ input
                [ type_ "text"
                , placeholder "What needs to be done?"
                , value model.newTodoTitle
                , onInput NewTodoTitleChanged
                , onEnter CreateTodoClicked
                , class "todo-input"
                ]
                []
            , select
                [ onInput (NewTodoPriorityChanged << stringToPriority)
                , class "priority-select"
                ]
                [ option [ value "Low" ] [ text "Low Priority" ]
                , option [ value "Medium", selected True ] [ text "Medium Priority" ]
                , option [ value "High" ] [ text "High Priority" ]
                ]
            , button
                [ onClick CreateTodoClicked
                , disabled (String.trim model.newTodoTitle == "")
                , class "add-btn"
                ]
                [ text "Add Todo" ]
            ]
        ]

viewFilters : Filter -> Html Msg
viewFilters currentFilter =
    div [ class "filters" ]
        [ button
            [ onClick (FilterChanged All)
            , class "filter-btn"
            , classList [ ( "active", currentFilter == All ) ]
            ]
            [ text "All" ]
        , button
            [ onClick (FilterChanged Incomplete)
            , class "filter-btn"
            , classList [ ( "active", currentFilter == Incomplete ) ]
            ]
            [ text "Active" ]
        , button
            [ onClick (FilterChanged Completed)
            , class "filter-btn"
            , classList [ ( "active", currentFilter == Completed ) ]
            ]
            [ text "Completed" ]
        ]

viewTodoList : Model -> Html Msg
viewTodoList model =
    let
        filteredTodos = filterTodos model.filter model.todos
    in
    if model.loading && List.isEmpty model.todos then
        div [ class "loading" ] [ text "Loading todos..." ]
    else if List.isEmpty filteredTodos then
        div [ class "empty-state" ]
            [ div [ class "empty-icon" ] [ text "📝" ]
            , div [ class "empty-title" ] [ text "No todos yet" ]
            , div [ class "empty-description" ] [ text "Add a task above to get started!" ]
            ]
    else
        ul [ class "todo-list" ]
            (List.map viewTodoItem filteredTodos)

viewTodoItem : Todo -> Html Msg
viewTodoItem todo =
    li [ class ("todo-item " ++ priorityToColor todo.priority)
        , classList [ ("completed", todo.completed) ]
        ]
        [ div 
            [ class "todo-checkbox"
            , classList [ ("checked", todo.completed) ]
            , onClick (ToggleTodoCompletion todo.id (not todo.completed))
            , style "cursor" "pointer"
            , title ("Click to toggle completion for: " ++ todo.title)
            ]
            [ if todo.completed then text "✓" else text "" ]
        , div [ class "todo-text"
            , classList [ ("completed", todo.completed) ]
            ] 
            [ text todo.title ]
        , div [ class ("priority-badge " ++ priorityToColor todo.priority) ]
            [ span [ class "priority-icon" ] [ text (priorityToIcon todo.priority) ]
            , text (priorityToString todo.priority)
            ]
        , button
            [ class "delete-btn"
            , onClick (DeleteTodoClicked todo.id)
            , title ("Delete: " ++ todo.title)
            ]
            [ text "×" ]
        ]

priorityToIcon : Priority -> String
priorityToIcon priority =
    case priority of
        High -> "🔥"
        Medium -> "⚡"
        Low -> "📌"

viewLoading : Bool -> Html Msg
viewLoading loading =
    if loading then
        div [ class "loading" ] [ text "Loading.." ]

    else
        text ""

-- Helpers
httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl url ->
            "Bad URL: " ++ url
        
        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error"
        
        Http.BadStatus status ->
            "Bad status: " ++ String.fromInt status
        
        Http.BadBody message ->
            "Bad response body: " ++ message

filterTodos : Filter -> List Todo -> List Todo
filterTodos filter todos =
    case filter of
        All ->
            todos
        
        Completed ->
            List.filter .completed todos

        Incomplete ->
            List.filter (not << .completed) todos

        ByPriority priority ->
            List.filter (\todo -> todo.priority == priority) todos

stringToPriority : String -> Priority
stringToPriority str =
    case str of
        "High" ->
            High

        "Low" ->
            Low

        _ ->
            Medium

priorityToColor : Priority -> String
priorityToColor priority =
    case priority of
        High -> "priority-high"
        Medium -> "priority-medium"
        Low -> "priority-low"

onEnter : Msg -> Attribute Msg
onEnter msg =
    let 
        isEnter key =
            if key == "Enter" then
                Json.Decode.succeed msg
            else
                Json.Decode.fail "not ENTER"
    in
    on "keydown" (Json.Decode.field "key" Json.Decode.string |> Json.Decode.andThen isEnter)

-- Commands
loadTodos : Cmd Msg
loadTodos =
    Api.getTodos
        { completed = Nothing
        , priority = Nothing
        , limit = Nothing
        , offset = Nothing
        , sort = Nothing
        , search = Nothing
        }
        TodosLoaded

loadStats : Cmd Msg
loadStats =
    Api.getTodoStats StatsLoaded

-- Subscriptions
subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none