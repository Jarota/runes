# runes

A [Lustre](https://hexdocs.pm/lustre/) SPA that acts as a digital Rune deck for the [Riftbound TCG](https://riftbound.leagueoflegends.com/en-us/) if you don't have enough physical cards (yet).

## Usage

Run locally with `gleam run -m lustre/dev start`.


There are two 'pages'; a draft page, and a play one.
When 'drafting', use the counters to choose how many of each colour to put in the deck, then click `PLAY`.


When 'playing', `AWAKEN` readies all Rune cards that have been 'exhausted', and `CHANNEL` draws two new cards from the deck.
Click on a ready Rune to exhaust it, and click on an exhausted rune to recycle it (return to the bottom of the deck).

## TODO

- [ ] Add tests
- [ ] Improve mobile experience
