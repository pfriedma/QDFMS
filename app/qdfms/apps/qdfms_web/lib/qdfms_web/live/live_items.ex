defmodule QdfmsWeb.LiveItems do
  use QdfmsWeb, :live_view

  @topic "whats_inside:lobby"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: QdfmsWeb.Endpoint.subscribe(@topic)
    {:ok, assign(socket, items: Inventory.Items.get_items_in_container(1))} # add items to assigns
  end


  @impl true
  def handle_info(%{event: "update", payload: %{items: items}}, socket) do
    {:noreply, assign(socket, items: items)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <ul class="todo-list">
    <%= for item <- @items do %>
    <li data-id={item.id} class={completed?(item)}>
      <div class="view">
        <label><%= item.name %></label>
        <p> Categories </p>
        <p> <% cats = Inventory.Items.get_categories(item.id) %>
            <%= for cat <- cats do %>
                <p><%=cat.name %></p>
                <%= if !is_nil(cat.image) do %>
                <p><img src="<%= "data:image/svg;base64," <> Base.encode64(cat.image) %>"/></p>
                <% end %>
            <% end %>
        </p>
        <p><%= inspect(item) %></p>
      </div>
    </li>
    <% end %>
    </ul>
    """
  end




end
