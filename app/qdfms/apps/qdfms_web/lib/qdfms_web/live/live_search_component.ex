defmodule LiveSearchComponent do
  use QdfmsWeb, :live_component
  alias Phoenix.LiveView.JS
  def mount(socket) do
    {:ok, assign(socket, result_items: [])}
  end

  def handle_event("update_search_categories", %{"cat-id" => id}, socket) do
    selected_cats_list = socket.assigns.selected_cats
    |> toggle_selected(id)
    items = if Enum.count(selected_cats_list) > 0 do
          filter_items_by_cat(socket.assigns.items, selected_cats_list)
       else
          socket.assigns.items
    end

    {:noreply,
       socket
       |> assign(selected_cats: selected_cats_list)
       |> assign(result_items: items)}


  end

  def handle_event("filter-dates", %{"search_dates" => %{"days_old" => days, "expires_soon" => filter_expire}} = _data, socket) do
      items = socket.assigns.result_items
      IO.puts(days)
      IO.puts(filter_expire)
      items = if(filter_expire == "true") do
        items
        |> Enum.filter(fn %Database.Item{} = x -> Date.compare(x.mfr_exp_date, Date.add(Date.utc_today(),30)) == :lt end)
      else
        items
      end
      items = case Integer.parse(days) do
        {n,_} -> Enum.filter(items, fn %Database.Item{} = x -> Date.compare(x.date_added, Date.add(Date.utc_today(), -1* n)) == :lt end)
        _ -> items
      end
      {:noreply,
        socket |> assign(result_items: items)}
  end

  def handle_event("reset_items", _params, socket) do
    #send(self(), %{event: "update", payload: %{items: get_for_cont(socket.assigns.container)}})
    {:noreply,
      socket
      |> assign(result_items: socket.assigns.items)
      |> assign(selected_cats: [])
    }

  end

  def handle_event("search", %{"search_filter" => params}, socket) do
    {:noreply, socket}
  end

  def handle_event("filter", %{"search_filter" => params}, socket) do
    IO.puts("container is: "<> socket.assigns.container)
    items = case params["search_text"] do
      s when is_bitstring(s) ->
        if String.length(s) > 1 do
           filter_items_by_cat(socket.assigns.items, socket.assigns.selected_cats)
           |> filter_items_text(s)
        else
          filter_items_by_cat(socket.assigns.items, socket.assigns.selected_cats)
        end
      _ -> filter_items_by_cat(socket.assigns.items, socket.assigns.selected_cats)
    end
    #send(self(), %{event: "update", payload: %{items: items}})
    {:noreply,
      socket
      |>assign(result_items: items) }
  end

  def update(assigns, socket ) do
      socket = assign(socket, assigns)
      socket = if Map.has_key?(socket.assigns, :items), do: assign(socket, result_items: socket.assigns.items), else: socket
      {:ok, socket}
  end

  def handle_info({:event, :update_items}, socket) do
    IO.puts("Got update event in search component")
    send(self(), {:event, :update_items})
    {:noreply, socket
    |> assign(edit: %{do: false})}
  end


  defp toggle_selected(cats_list, cat_id) do
    if Enum.member?(cats_list, cat_id) do
      Enum.reject(cats_list, fn x -> x == cat_id end )
    else
      [cat_id | cats_list]
    end
  end


  defp matches_category(item, filter_list) do
    item_cats = Inventory.Items.get_categories_ids(item.id)
      filter_list
      |> Enum.all?(fn x -> Enum.member?(item_cats, String.to_integer(x)) end)
  end

  defp filter_items_text(items, text_string) do
    items
    |> Enum.filter(fn x -> String.contains?(x.name, text_string) || String.contains?(x.description, text_string) end)
  end

  defp get_for_cont(str_id) do
    Inventory.Items.get_items_in_container(String.to_integer(str_id))
  end

  defp filter_items_by_cat(items, selected_cats_list) do
    items
    |> Enum.filter(fn x -> matches_category(x,selected_cats_list) end)
  end

  def render(assigns) do


    ~H"""
    <div id="search">
    <style>
    .category-button { border: 1px solid black; padding: 10px; margin: 10px; background-color:white;}
    .selected {background-color: #87CEFA;}
    </style>
      <div id="categories-filter" style="border: 1px solid black; padding: 10px;">
        <%= for cat <- @categories do %>
          <div id={"cat-#{cat.id}"} style="float:left" class={"category-button #{if Enum.member?(@selected_cats, to_string(cat.id)), do: 'selected'}"} phx-click="update_search_categories" phx-value-cat-id={cat.id} phx-target={@myself} >
            <%= if !is_nil(cat.image) do %>
            <img src={"data:image/svg+xml;base64,#{cat.image}"}, height='60', width='60'/><br/>
            <% end %>
            <%= cat.name %>
          </div>
        <% end %>
        <p style="clear:both;"/>
      </div>
      <div id="text-filter" style="clear: both; padding 10px;">
        <br/>
         <.form let={f} for={:search_filter} phx-submit="reset_items" phx-change="filter" phx-target={@myself}>
          <%= text_input f, :search_text %>
          <%= submit "Reset" %>
          </.form>
      </div>

      <button style="clear:both;" phx-click={JS.toggle(to: "#advanced-search", in: "fade-in", out: "fade-out")}>Advanced</button>
      <div id="advanced-search" style="clear:both; padding 10px;" hidden>
        <.form let={f} for={:search_dates} phx-submit="filter-dates" phx-target={@myself}>
            Filter items more than __ days old:
            <%= number_input f, :days_old %>
            Show items expiring within a month:
            <%= checkbox f, :expires_soon %>
            <%= submit "Apply Filter" %>
          </.form>
      </div>



    <div id = "search_results" >
      Search Results: <br/>

      <ul class="item-list">
      <%= for item <- @result_items  do %>
        <.live_component module={ItemComponentList} edit={@edit} id={"res-#{item.id}"} item={item} uploads={@uploads} container={@container} />
      <% end %>
      </ul>

    </div>

    </div>

    """

  end

end
