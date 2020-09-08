module Main exposing (Msg(..), main, update, view)

import Browser
import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onClick, onInput)
import ItemsApi.Mutation as Mutation
import ItemsApi.Object
import ItemsApi.Object.Items as Items
import ItemsApi.Object.Paginateditems
import ItemsApi.Query as Query
import ItemsApi.Scalar


main : Program String Model Msg
main =
    Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }


type alias Item =
    { itemsId : ItemsApi.Scalar.Id
    , name : Maybe String
    }


type alias Model =
    { apiKey : String
    , items : List Item
    , input : String
    }


type Msg
    = GotItems (Result (Graphql.Http.Error (List Item)) (List Item))
    | Change String
    | Submit
    | GotSave (Result (Graphql.Http.Error (Maybe Item)) (Maybe Item))
    | Delete ItemsApi.Scalar.Id
    | GotDelete (Result (Graphql.Http.Error (Maybe Item)) (Maybe Item))


init : String -> ( Model, Cmd Msg )
init apiKey =
    ( { apiKey = apiKey, items = [], input = "" }, makeQueryRequest apiKey )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotItems (Ok items) ->
            ( { model | items = items }, Cmd.none )

        GotItems (Err _) ->
            ( model, Cmd.none )

        Change value ->
            ( { model | input = value }, Cmd.none )

        Submit ->
            ( { model | input = "" }, makeMutationRequest model.apiKey model.input )

        GotSave (Ok item) ->
            case item of
                Just item_ ->
                    ( { model | items = model.items ++ [ item_ ] }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        GotSave (Err _) ->
            ( model, Cmd.none )

        Delete itemsId ->
            ( model, makeDeleteMutationRequest model.apiKey itemsId )

        GotDelete (Ok item) ->
            case item of
                Just item_ ->
                    ( { model
                        | items = List.filter (\itm -> itm.itemsId /= item_.itemsId) model.items
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        GotDelete (Err _) ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [] (List.map viewItem model.items ++ [ viewAdd ])


viewAdd : Html Msg
viewAdd =
    div []
        [ input [ placeholder "New value", onInput Change ] []
        , button [ onClick Submit ] [ text "submit" ]
        ]


viewItem : Item -> Html Msg
viewItem { itemsId, name } =
    div []
        [ text <| Maybe.withDefault "-" name
        , button [ onClick (Delete itemsId) ] [ text "delete" ]
        ]


itemsSelection : SelectionSet Item ItemsApi.Object.Items
itemsSelection =
    SelectionSet.map2 Item
        Items.itemsId
        Items.name


url : String
url =
    "https://iil2riwenfchbdleoziie3yyse.appsync-api.ap-southeast-2.amazonaws.com/graphql"


makeQueryRequest : String -> Cmd Msg
makeQueryRequest apiKey =
    queryAll
        |> Graphql.Http.queryRequest url
        |> Graphql.Http.withHeader "x-api-key" apiKey
        |> Graphql.Http.send GotItems


makeMutationRequest : String -> String -> Cmd Msg
makeMutationRequest apiKey name =
    save name
        |> Graphql.Http.mutationRequest url
        |> Graphql.Http.withHeader "x-api-key" apiKey
        |> Graphql.Http.send GotSave


makeDeleteMutationRequest : String -> ItemsApi.Scalar.Id -> Cmd Msg
makeDeleteMutationRequest apiKey id =
    delete id
        |> Graphql.Http.mutationRequest url
        |> Graphql.Http.withHeader "x-api-key" apiKey
        |> Graphql.Http.send GotDelete


queryAll : SelectionSet (List Item) RootQuery
queryAll =
    Query.all
        (\_ -> { limit = Absent, nextToken = Absent })
        (ItemsApi.Object.Paginateditems.items itemsSelection)


save : String -> SelectionSet (Maybe Item) RootMutation
save name =
    Mutation.save { name = name } itemsSelection


delete : ItemsApi.Scalar.Id -> SelectionSet (Maybe Item) RootMutation
delete id =
    Mutation.delete { itemsId = id } itemsSelection


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
