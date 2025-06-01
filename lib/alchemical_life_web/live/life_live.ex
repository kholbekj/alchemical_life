defmodule AlchemicalLifeWeb.LifeLive do
  use AlchemicalLifeWeb, :live_view
  alias AlchemicalLife.Life.Game

  # Acorn

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to the game updates
      Phoenix.PubSub.subscribe(AlchemicalLife.PubSub, "game_of_life:updates")
    end

    grid = Game.get_grid()

    new_socket = assign(socket,
      grid_size: 20,
      grid: grid
    )

    {:ok, new_socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-center p-4">
      <div class="grid gap-px bg-gray-300 w-full max-w-xl aspect-square"
           style={"grid-template-columns: repeat(#{@grid_size}, 1fr); grid-template-rows: repeat(#{@grid_size}, 1fr);"}>
        <%= for y <- 0..(@grid_size - 1) do %>
          <%= for x <- 0..(@grid_size - 1) do %>
            <div id={"cell-#{x}-#{y}"} class={"#{if Enum.member?(@grid, [x,y]), do: "bg-black", else: "bg-white"} aspect-square"}></div>
          <% end %>
        <% end %>
      </div>
    </div>

    <div class="flex justify-center p-4">
      <button phx-click="start" class="px-4 py-2 bg-blue-500 text-white rounded">Start</button>
    </div>

    <div class="flex justify-center p-4">
      <button phx-click="reset" class="px-4 py-2 bg-red-500 text-white rounded">Reset</button>
    </div>
    """
  end

  def handle_info({:grid_updated, new_grid}, socket) do
    # Update the grid in the socket assigns
    {:noreply, assign(socket, grid: new_grid)}
  end

  def handle_event("start", _params, socket) do
    # Logic to start the game. We want to evolve state once every 1s.
    Game.tick(notick: false)

    {:noreply, socket}
  end

  def handle_event("reset", _params, socket) do
    Game.reset
    {:noreply, socket}
  end

  end
