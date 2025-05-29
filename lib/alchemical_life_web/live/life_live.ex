defmodule AlchemicalLifeWeb.LifeLive do
  use AlchemicalLifeWeb, :live_view

  # Acorn
  @default_grid [[5,5], [6,5], [6,3], [8,4], [9,5], [10,5], [11,5]]

  def mount(_params, _session, socket) do
    # Initialize the socket with any necessary assigns
    new_socket = socket
    |> assign(:grid_size, 20) # Default grid size
    |> assign(:grid, @default_grid) # Example initial grid state
    |> assign(:notick, false) # Flag to control ticking

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

  def handle_event("start", _params, socket) do
    # Logic to start the game. We want to evolve state once every 1s.

    Process.send_after(self(), :tick, 1000) # Schedule the first tick after 1 second
    {:noreply, assign(socket, notick: false)}
  end

  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, grid: @default_grid, notick: true)}
  end

  def handle_info(:tick, socket) when socket.assigns.notick do
    # If not ticking, just return without doing anything
    {:noreply, socket}
  end
  def handle_info(:tick, socket) do

    # Logic to evolve the grid state
    new_grid = evolve_grid(socket.assigns.grid)

    # Update the socket with the new grid state
    new_socket = assign(socket, :grid, new_grid)

    # Schedule the next tick
    Process.send_after(self(), :tick, 1000)

    {:noreply, new_socket}
  end

  def evolve_grid(grid) do
    # Conways Game of Life rules:
    # 1. Any live cell with fewer than two live neighbors dies (underpopulation).
    # 2. Any live cell with two or three live neighbors lives on to the next generation.
    # 3. Any live cell with more than three live neighbors dies (overpopulation).
    # 4. Any dead cell with exactly three live neighbors becomes a live cell (reproduction).

    neighbors = fn [x, y] ->
      for dx <- -1..1, dy <- -1..1, dx != 0 or dy != 0 do
        [x + dx, y + dy]
      end
    end

    live_neighbors = fn cell ->
      Enum.count(neighbors.(cell), fn n -> Enum.member?(grid, n) end)
    end

    for x <- 0..19, y <- 0..19 do
      cell = [x, y]
      live_count = live_neighbors.(cell)

      cond do
        Enum.member?(grid, cell) and (live_count < 2 or live_count > 3) -> nil # Cell dies
        Enum.member?(grid, cell) -> cell # Cell lives on
        live_count == 3 -> cell # Cell becomes alive
        true -> nil # Cell remains dead
      end
    end
    |> Enum.reject(&is_nil/1) # Remove nils
  end
end
