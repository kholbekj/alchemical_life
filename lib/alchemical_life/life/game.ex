defmodule AlchemicalLife.Life.Game do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def get_grid do
    GenServer.call(__MODULE__, :get_grid)
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  def tick(args \\ [notick: false]) do
    send(GenServer.whereis(__MODULE__), {:tick, args})
  end

  def init(args) do
    {:ok, %{grid: args[:grid] || [], notick: true}}
  end

  def handle_call(:get_grid, _from, state) do
    {:reply, state.grid, state}
  end

  def handle_call(:reset, _from, _state) do
    # Reset the grid to an empty state
    new_state = %{grid: [[5, 5], [6, 5], [6, 3], [8, 4], [9, 5], [10, 5], [11, 5]], notick: true}
    Phoenix.PubSub.broadcast(AlchemicalLife.PubSub, "game_of_life:updates", {:grid_updated, new_state.grid})
    {:reply, :ok, new_state}
  end

  def handle_info(:tick, state) when state.notick do
    # If not ticking, just return without doing anything
    {:noreply, state}
  end
  def handle_info({:tick, notick: notick }, state) when notick do
    # If not ticking, just return without doing anything
    {:noreply, state}
  end
  def handle_info({:tick, notick: false}, state) do

    new_state = %{state | notick: false}
    handle_info(:tick, new_state)
  end
  def handle_info(:tick, state) do

    # Logic to evolve the grid state
    new_grid = evolve_grid(state.grid)

    # Schedule the next tick
    Process.send_after(self(), :tick, 1000)

    # Update the state with the new grid
    new_state = %{state | grid: new_grid}

    Phoenix.PubSub.broadcast(AlchemicalLife.PubSub, "game_of_life:updates", {:grid_updated, new_grid})

    {:noreply, new_state}
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
