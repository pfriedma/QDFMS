defmodule ItemComponentLive do
  use QdfmsWeb, :live_component



  @impl true
  def handle_info(%{event: "update", payload: %{items: items}}, socket) do
    {:noreply, assign(socket, items: items)}
  end

  @impl true

  def render(assigns) do

    ~H"""

    <li data-id={@item.id} class="list">
    <% weight = %ExUc.Value{} = @item.weight %>
      <div class="view">
        <label><%= @item.name %></label>
        <div class="item_image", style="float:right; width:100">
        <%= if !is_nil(@item.photo) do %>
         <img src={"data:image/png;base64,#{@item.photo}"} height='100',width='100' />
        <% end %>
      </div>
        <div class="cat_container">
        <% cats = Inventory.Items.get_categories(@item.id) %>
          <%= for cat <- cats do %>
              <div class="categories">
              <%= if !is_nil(cat.image) do %>
              <img src={"data:image/svg+xml;base64,#{cat.image}"}, height='60', width='60'/><br/>
              <% end %>
              <%=cat.name %>
              </div>
          <% end %>
        </div>
        <div class="item_desc">
          <div class="metadata">
            <h3>Weight: <%= ExUc.as_string(weight) %> </h3>
            <h3>Added: <%= @item.date_added %> </h3>
            <h3 class={if Date.compare(@item.mfr_exp_date, Date.utc_today) == :lt, do: "expired"}> Expires: <%= @item.mfr_exp_date %></h3>
          </div>
          <div class = "item_desc", style="clear:both">
            <h3>Description</h3>
            <%= @item.description %>
          </div>
        </div>
      </div>
      <p>UPC: <%= @item.upc %> </p>
    </li>
    """
  end

end
