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
    <style>
    .item-list {list-style-type: none;}
    .list {border: 1px solid black; padding: 1em;}
    .categories {float: left; font-weight:bold; padding:1em;}
    .view label   {font-size: x-large; float:left;}
    .metadata h3 {font-size:medium;}
    .metadata {clear:both;}
    .item_desc {clear:both;}
    .cat_container {clear:both;}
    .expired {color: red; font-weight: bold;}
    </style>
    <ul class="item-list">
    <%= for item <- @items do %>
    <% weight = %ExUc.Value{} = item.weight %>
    <li data-id={item.id} class="list">
      <div class="view">
        <label><%= item.name %></label>
        <div class="item_image", style="float:right; width:100">
        <%= if !is_nil(item.photo) do %>
         <img src="<%= "data:image/png;base64," <> item.photo %>" height='100',width='100' />
        <% end %>
      </div>
        <div class="cat_container">
        <% cats = Inventory.Items.get_categories(item.id) %>
          <%= for cat <- cats do %>
              <div class="categories">
              <%= if !is_nil(cat.image) do %>
              <img src="<%= "data:image/svg+xml;base64," <> cat.image %>", height='60', width='60'/><br/>
              <% end %>
              <%=cat.name %>
              </div>
          <% end %>
        </div>
        </p>
        <div class="item_desc">
          <div class="metadata">
            <h3>Weight: <%= ExUc.as_string(weight) %><h3>
            <h3>Added: <%= item.date_added %> </h3>
            <h3 <%= if Date.compare(item.mfr_exp_date, Date.utc_today) == :lt do "class=expired" end %> >Expires: <%= item.mfr_exp_date %></h3>
          </div>
          <div class = "item_desc", style="clear:both">
            <h3>Description</h3>
            <%= item.description %>
          </div>
        </div>
      </div>
      <p>UPC: <%= item.upc %> </p>
    </li>
    <% end %>
    </ul>
    """
  end




end
