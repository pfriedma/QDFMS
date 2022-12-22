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
    <% weight = %ExUc.Value{} = item.weight %>
    <li data-id={item.id} class={completed?(item)}>
      <div class="view">
        <label><%= item.name %></label>
        <p> Categories </p>
        <% cats = Inventory.Items.get_categories(item.id) %>
          <%= for cat <- cats do %>
              <div class="categories" style="float:left">
              <%= if !is_nil(cat.image) do %>
              <img src="<%= "data:image/svg+xml;base64," <> Base.encode64(cat.image) %>", height='60', width='60'/><br/>
              <% end %>
              <%=cat.name %>
              </div>
          <% end %>
        </p>
        <div class="item_desc", style="clear:both">
          <div class="metadata", style="float:left">
            <h3>Weight: <%= ExUc.as_string(weight) %><h3>
            <h3>Added: <%= item.date_added %> </h3>
            <h3>Expires: <%= item.mfr_exp_date %></h3>
            <h4>UPC: <%= item.upc %> </h4>
          </div>
          <div class="item_image", style="float:right">
            <% if !is_nil(item.photo) do %>
             <img src="<%= "data:image/png;base64," <> Base.encode64(item.photo) %>" height='100',width='100' />
            <% end %>
          </div>
          <div class = "item_desc", style="clear:both">
            <h3>Description</h3>
            <%= item.description %>
          </div>
        </div>
      </div>
    </li>
    <% end %>
    </ul>
    """
  end




end
