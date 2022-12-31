defmodule ItemComponentLive do
  use QdfmsWeb, :live_component


  @impl true



  def render(assigns) do

    ~H"""
    <li id={"item-#{@item.id}"} data-id={@item.id} class="list">
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

  defmodule ItemComponentList do
    use QdfmsWeb, :live_component
    alias Phoenix.LiveView.JS


    @impl true

    def handle_event("remove_item", %{"id" => id, "value" => _val}=_data, socket) do
      Inventory.Items.remove_item(String.to_integer(id))
      send(self(), {:event, %{update_items: id}})
      {:noreply, socket}
    end

    def handle_event("edit_item", %{"id" => id, "value" => _val} = _data, socket) do
      IO.puts("got edit event in item form for: " <> id)
      {:noreply, socket
         |> assign(edit: %{do: true, id: id})}
    end

    def handle_event("cancel_edit", _data, socket) do
      {:noreply, socket
        |> assign(edit: %{do: false}) }
    end


    def update(assigns, socket) do
      {:ok ,assign(socket, assigns)}
    end

    def render(assigns) do

      ~H"""
      <li id={"item-#{@item.id}"} data-id={@item.id} class="list">
      <style>
      .item-list {list-style-type: none;}
      .list {border: 1px solid black; padding: 1em;}
      .categories {float: right; font-weight:bold; padding:1em;}
      .details {clear:both;}
      .view label   {font-size: x-large;}
      .title {float: left;}
      .metadata h3 {font-size:medium;}
      .metadata {clear:both;}
      .item_desc {clear:both;}
      .title{ float: left;}
      .cat_container {float: right;}
      .expired {color: red; font-weight: bold;}
      </style>
      <% weight = %ExUc.Value{} = @item.weight %>
        <div class="view" phx-click={JS.toggle(to: "#item-detail-#{@item.id}", in: "fade-in", out: "fade-out")}>
          <div class="header" >
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
            <div class="title">
              <h1><%= @item.name %></h1>
              <span>Added: <%= @item.date_added %> </span><br/>
              <span class={if Date.compare(@item.mfr_exp_date, Date.utc_today) == :lt, do: "expired"}> Expires: <%= @item.mfr_exp_date %></span>
            </div>
          </div>
            <p style="clear:both" />
          <div id={"item-detail-#{@item.id}"} class="details" hidden>
            <div class="item_image", style="float:right; width:100">
              <%= if !is_nil(@item.photo) do %>
              <img src={"data:image/png;base64,#{@item.photo}"} height='100',width='100' />
              <% end %>
            </div>

            <div class="item_desc_cont">
              <div class="metadata">
                <h3>Weight: <%= ExUc.as_string(weight) %> </h3>
                <h3>Added: <%= @item.date_added %> </h3>
                <h3 class={if Date.compare(@item.mfr_exp_date, Date.utc_today) == :lt, do: "expired"}> Expires: <%= @item.mfr_exp_date %></h3>
              </div>
              <div class = "item_desc", style="clear:both">
                <h3>Description</h3>
                <%= @item.description %>
              </div>
              <p>UPC: <%= @item.upc %> </p>
                <button style="background-color:red; color:white" data-confirm="Are you sure? This action can't be undone" phx-click="remove_item" phx-value-id={@item.id} phx-target={@myself}>Remove</button>
                <button phx-click="edit_item" phx-value-id={@item.id} phx-target={@myself}> Edit </button>

            </div>
          </div>
        </div>
        <div id={"edit_item-#{@item.id}"} >
          <%= if Map.has_key?(assigns, :edit) && @edit.do == true && @edit.id == to_string(@item.id)  do %>
            <.live_component module={ItemComponentFormLive} id={to_string(@item.id)} container={@container} item={@item} uploads={@uploads} />
            <button phx-click="cancel_edit" phx-target={@myself}> Cancel </button>
          <% end %>
        </div>
      </li>
      """
    end

  end
