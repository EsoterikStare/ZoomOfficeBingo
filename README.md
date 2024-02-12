# ZoomOfficeBingo
A small bot that can listen in on zoom meetings and automatically fill out randomly generated 

## Installation

### Elixir

The quickest way to install Elixir is with homebrew: `brew install elixir`.  If you plan to do
significant work with Elixir, a version manager like [asdf](https://asdf-vm.com/) (with the
elixir plugin) is probably a good idea.

### Project and dependencies

Elixir's build tool is named [mix](https://hexdocs.pm/elixir/introduction-to-mix.html).  It
uses [hex](https://github.com/hexpm/hex) and [rebar](https://rebar3.org/) to download dependencies.
Unfortunately, the tooling does not play well with our internal SSL ~~hackery~~ configuration, so
intalling these requires some manual workarounds.

To install mix:

```shell
mix archive.install github hexpm/hex branch latest
```

To install rebar, click the "download" link in the rebar site above, make the script executable, then:

```shell
./rebar3 local install
```

Make a note of the path where the "rebar3 run script" is written, then run:

```shell
mix local.rebar rebar3 <path from above>
```

Finally, add the Netskope CA store to the environment so that Hex will trust the generated certificates:

```shell
export HEX_CACERTS_PATH=/Library/Application\ Support/Netskope/STAgent/data/nscacert.pem
```

whew!

Now you can install the dependencies as normal:

```shell
mix deps.get
```

## Getting Started

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
