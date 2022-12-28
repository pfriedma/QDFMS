defmodule QdfmsWeb.LiveItems do
  use QdfmsWeb, :live_view
  alias Phoenix.LiveView.JS

  @topic "whats_inside:lobby"

  @impl true
  def mount(%{"container" => container_id} , _session, socket) do
    {:ok,
    socket
    |> assign(items: Inventory.Items.get_items_in_container(String.to_integer(container_id)))
    |> assign(container: container_id)
    |> allow_upload(:image, accept: ~w(.jpg .jpeg .png .gif), auto_upload: false)
    } # add items to assigns
  end
  def mount(_params , _session, socket) do
    {:ok,
    socket
    |> assign(items: [])
    |> allow_upload(:image, accept: ~w(.jpg .jpeg .png .gif), auto_upload: false)
    } # add items to assigns
  end


  @impl true
  def handle_info(%{event: "update", payload: %{items: items}}, socket) do
    {:noreply, assign(socket, items: items)}
  end

  def handle_params(%{"container" => container}, _, socket) do
    {:noreply,
      socket
      |> assign(items: Inventory.Items.get_items_in_container(String.to_integer(container)))
      |> assign(container: container)
    }
  end

  def handle_params(_, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
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

    <button phx-click={JS.show(to: "#new_item_form", transition: "fade-in")}>Create New</button>
    <div id="new_item_form" hidden data-js-exec={JS.hide(to: "#new_item_form", transition: "fade-out")}>
      <.live_component module={ItemComponentFormLive} id="new" container={@container} item={%Database.Item{weight: %ExUc.Value{kind: :mass}}} uploads={@uploads} />
      <button phx-click={JS.hide(to: "#new_item_form", transition: "fade-out")}>Cancel</button>
    </div>
    <%= for item <- @items do %>
      <.live_component module={ItemComponentLive} id={item.id} item={item} uploads={@uploads} />
    <% end %>
    </ul>
    """
  end




end
