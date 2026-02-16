import gleam/dict
import gleam/int
import gleam/list
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/keyed
import lustre/event

type Rune {
  Fury
  Calm
  Mind
  Body
  Chaos
  Order
}

fn rune_to_string(rune: Rune) -> String {
  case rune {
    Fury -> "fury"
    Calm -> "calm"
    Mind -> "mind"
    Body -> "body"
    Chaos -> "chaos"
    Order -> "order"
  }
}

type Card {
  Card(id: String, rune: Rune)
}

type Model {
  Drafting(DraftModel)
  Playing(PlayModel)
}

type DraftModel {
  DraftModel(deck: dict.Dict(Rune, Int))
}

type PlayModel {
  PlayModel(deck: List(Card), ready: List(Card), exhausted: List(Card))
}

type Msg {
  Draft(DraftMsg)
  Play(PlayMsg)
}

type DraftMsg {
  UserClickedAdd(Rune)
  UserClickedRemove(Rune)
  UserClickedPlay
}

type PlayMsg {
  UserClickedBack
  UserClickedAwaken
  UserClickedChannel
  UserClickedExhaust(String)
  UserClickedRecycle(String)
}

fn new_draft_deck() -> dict.Dict(Rune, Int) {
  dict.new()
  |> dict.insert(Fury, 0)
  |> dict.insert(Calm, 0)
  |> dict.insert(Mind, 0)
  |> dict.insert(Body, 0)
  |> dict.insert(Chaos, 0)
  |> dict.insert(Order, 0)
}

fn init(_args) -> Model {
  Drafting(DraftModel(new_draft_deck()))
}

fn view(model: Model) -> Element(Msg) {
  case model {
    Drafting(m) -> view_draft(m)
    Playing(m) -> view_play(m)
  }
}

fn view_draft(model: DraftModel) -> Element(Msg) {
  let all_rune_containers =
    dict.map_values(model.deck, draft_rune_container)
    |> dict.values

  html.div([], [
    html.h1([], [html.text("Draft")]),
    html.div([attribute.class("picker-container")], all_rune_containers),
    html.menu([], [
      html.button(
        [attribute.class("btn-primary"), event.on_click(Draft(UserClickedPlay))],
        [html.text("PLAY")],
      ),
    ]),
  ])
}

fn draft_rune_container(rune: Rune, n: Int) -> Element(Msg) {
  html.div([attribute.class("rune-picker " <> rune_to_string(rune))], [
    html.button(
      [
        attribute.class("btn-secondary"),
        event.on_click(Draft(UserClickedAdd(rune))),
      ],
      [
        html.text("+"),
      ],
    ),
    html.p([attribute.class("draft-amount")], [html.text(int.to_string(n))]),
    html.button(
      [
        attribute.class("btn-secondary"),
        event.on_click(Draft(UserClickedRemove(rune))),
      ],
      [
        html.text("-"),
      ],
    ),
  ])
}

fn view_play(model: PlayModel) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Play")]),
    html.menu([], [
      html.button(
        [
          attribute.class("btn-secondary"),
          event.on_click(Play(UserClickedBack)),
        ],
        [html.text("BACK")],
      ),
      html.button(
        [
          attribute.class("btn-primary"),
          event.on_click(Play(UserClickedAwaken)),
        ],
        [html.text("AWAKEN")],
      ),
      html.button(
        [
          attribute.class("btn-primary"),
          event.on_click(Play(UserClickedChannel)),
        ],
        [html.text("CHANNEL")],
      ),
    ]),
    keyed.div(
      [attribute.class("deck")],
      list.append(
        list.map(model.deck, view_card_undrawn),
        list.append(
          list.index_map(model.ready, view_card_ready),
          list.index_map(model.exhausted, view_card_exhausted),
        ),
      ),
    ),
  ])
}

fn view_card_undrawn(card: Card) -> #(String, Element(Msg)) {
  let el =
    html.div([attribute.class("card face-down"), attribute.id(card.id)], [
      html.p([attribute.class("p-cardback")], [html.text("LEAGUE of LEGENDS")]),
    ])

  #(card.id, el)
}

fn view_card_ready(card: Card, index: Int) -> #(String, Element(Msg)) {
  let el =
    html.div(
      [
        event.on_click(Play(UserClickedExhaust(card.id))),
        attribute.id(card.id),
        attribute.class("card ready " <> rune_to_string(card.rune)),
        attribute.style("top", int.to_string(index * 40) <> "px"),
      ],
      [],
    )

  #(card.id, el)
}

fn view_card_exhausted(card: Card, index: Int) -> #(String, Element(Msg)) {
  let el =
    html.div(
      [
        event.on_click(Play(UserClickedRecycle(card.id))),
        attribute.id(card.id),
        attribute.class("card exhausted " <> rune_to_string(card.rune)),
        attribute.style("top", int.to_string(index * 40) <> "px"),
      ],
      [],
    )

  #(card.id, el)
}

fn update(model: Model, msg: Msg) -> Model {
  case model, msg {
    Drafting(mo), Draft(ms) -> update_draft(mo, ms)
    Playing(mo), Play(ms) -> update_play(mo, ms)
    _, _ -> model
  }
}

fn update_draft(model: DraftModel, msg: DraftMsg) -> Model {
  case msg {
    UserClickedAdd(rune) -> {
      let assert Ok(n) = dict.get(model.deck, rune)
      let new_deck = dict.insert(model.deck, rune, n + 1)
      Drafting(DraftModel(new_deck))
    }
    UserClickedRemove(rune) -> {
      let assert Ok(n) = dict.get(model.deck, rune)
      let new_deck = dict.insert(model.deck, rune, int.max(n - 1, 0))
      Drafting(DraftModel(new_deck))
    }
    UserClickedPlay -> {
      let runes =
        dict.fold(over: model.deck, from: [], with: fn(acc, rune, n) {
          list.append(acc, list.repeat(rune, n))
        })

      let deck =
        list.index_map(runes, fn(rune, i) {
          Card(id: int.to_string(i), rune: rune)
        })
      Playing(PlayModel(list.shuffle(deck), [], []))
    }
  }
}

fn update_play(model: PlayModel, msg: PlayMsg) -> Model {
  case msg {
    UserClickedBack -> {
      Drafting(DraftModel(new_draft_deck()))
    }
    UserClickedAwaken -> {
      // Ready all exhausted runes
      let ready = list.append(model.ready, model.exhausted)
      Playing(PlayModel(model.deck, ready, []))
    }
    UserClickedChannel -> {
      let new_cards = list.take(model.deck, 2)
      let drawn = list.append(model.ready, new_cards)
      let left = list.drop(model.deck, 2)
      Playing(PlayModel(left, drawn, model.exhausted))
    }
    UserClickedExhaust(id) -> {
      let assert Ok(exhausting) =
        list.find(model.ready, fn(card) { card.id == id })
      let ready = list.filter(model.ready, fn(card) { card.id != id })

      Playing(PlayModel(
        model.deck,
        ready,
        list.append(model.exhausted, [exhausting]),
      ))
    }
    UserClickedRecycle(id) -> {
      let assert Ok(recycling) =
        list.find(model.exhausted, fn(card) { card.id == id })
      let exhausted =
        list.filter(model.exhausted, keeping: fn(card) { card.id != id })

      Playing(PlayModel(
        list.append(model.deck, [recycling]),
        model.ready,
        exhausted,
      ))
    }
  }
}

pub fn main() -> Nil {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
