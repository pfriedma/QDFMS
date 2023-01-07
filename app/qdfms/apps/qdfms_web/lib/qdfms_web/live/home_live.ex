defmodule QdfmsWeb.HomeLive do
  use QdfmsWeb, :live_view
  alias Phoenix.LiveView.JS
  alias Database.Item
  #@topic "whats_inside"

  def mount(_params,  _session, socket) do
    {:ok,
      socket
      |> assign(state: %{name: "home", data: %{}})
      |> assign(conn: socket)
      |> assign(edit: %{do: false})
      |> allow_upload(:image, accept: ~w(.png), auto_upload: false)
    }

  end

  def update(params, socket) do
    {:ok, assign(socket, params)}
  end


  @impl true
  def handle_event("add_item", _data, socket) do
#    status = if Map.has_key?(data, "value"), do: 1, else: 0
#    item = Item.get_item!(Map.get(data, "id"))
#    Item.update_item(item, %{id: item.id, status: status})
#    socket = assign(socket, items: Item.list_items(), active: %Item{})
    socket = socket
    |> assign(state: %{name: "add", data: %{}})
    |> push_event("reset-state", %{
      to: "#reader",
      attr: ""
    })
    # QdfmsWeb.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    {:noreply, socket}
  end

  def handle_event("remove_item", _data, socket) do
    #    status = if Map.has_key?(data, "value"), do: 1, else: 0
    #    item = Item.get_item!(Map.get(data, "id"))
    #    Item.update_item(item, %{id: item.id, status: status})
    #    socket = assign(socket, items: Item.list_items(), active: %Item{})
        socket = socket
        |> assign(state: %{name: "remove", data: %{}})
        |> push_event("reset-state", %{
          to: "#reader",
          attr: ""
        })
        # QdfmsWeb.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
        {:noreply, socket}
      end

  @impl true
  def handle_event("recv_scan", %{"value" => data} = _data, socket) do
#    status = if Map.has_key?(data, "value"), do: 1, else: 0
#    item = Item.get_item!(Map.get(data, "id"))
#    Item.update_item(item, %{id: item.id, status: status})
#    socket = assign(socket, items: Item.list_items(), active: %Item{})
     state = socket.assigns.state
     state_name = state.name
     socket = socket
     IO.puts("Got Value:" <> data)
     IO.puts("state:" <> state.name )
     new_state_name = case state_name do
      "add" -> "add_item"
      "remove" -> "remove_item"
      _ -> "home"
     end
     if state_name == "remove" do
        {:noreply,
        socket
          |> push_event("clear-scanner", %{
            to: "#reader",
            attr: ""
          })
          |> assign(items: do_remove_item(data))
          |> assign(state: %{name: "search", data: %{}})}
     else
     {:noreply, socket
     |> push_event("clear-scanner", %{
      to: "#reader",
      attr: ""
    })
    |> assign(state: %{name: new_state_name, data: %{upc: data}})}
     end
  end

  def handle_event("search_form", _data, socket) do
    {:noreply,
      socket
        |> push_event("clear-scanner", %{
          to: "#reader",
          attr: ""
        })
        |> assign(items: Inventory.Items.get_items_in_container(String.to_integer(socket.assigns.container_id)))
        |> assign(state: %{name: "search", data: %{}})}
  end


  def handle_event("reset_state", _data, socket) do
    socket = assign(socket, state: %{name: "home", data: %{}})
    {:noreply, push_event(socket, "clear-scanner", %{
      to: "#reader",
      attr: ""
    })}
  end

  def handle_event("add_new_item", %{"item" => item_data} = _data, socket) do

    IO.puts(Kernel.inspect(item_data))
    socket = socket
    |> put_flash(:info, "Item added!")
    |> assign(state: %{name: "home", data: %{}})
    {:noreply, socket}
  end

  def handle_event("register", data, socket) do
   # {:ok, socket |> assign(container_id: data["id"])}
   IO.puts(Kernel.inspect(data))
   {:noreply, socket}
  end

  def handle_info({:event, %{update_items: id}}, socket) do
    if socket.assigns.state["name"] == "search" do
      send_update(ItemComponentList, id: "res-"<>to_string(id), edit: %{do: false})
    end
    {:noreply,
    socket
    |> put_flash(:info, "Items updated")
    |> assign(edit: %{do: false})
    |> assign(items: Inventory.Items.get_items_in_container(String.to_integer(socket.assigns.container_id)))
  }

  end

  def handle_event("select_container", %{"container" => cont_data} = _data, socket) do
    {:noreply, socket
      |> assign(container_id: cont_data["container"])}
  end

  def handle_info(_, socket) do
    IO.puts("Got an unhandled info event")
    {:noreply, socket}
  end

  defp do_remove_item(upc) do
     Inventory.Items.find_item_by_upc(upc)
  end

  defp lookup_upc_info(upc) do
    hist_items = Inventory.HistoricalItems.find_item_by_upc(upc)
    {item, categories} = if Enum.count(hist_items) > 0 do
        hi = %Database.HistoricalItem{} = List.first(hist_items)
        item = %Database.Item{weight: hi.weight,
          description: hi.description,
          name: hi.name,
          photo: hi.photo,
          upc: hi.upc}
        categories = hi.categories |> Enum.map(&(&1.category_id))
        {item, categories}
    else
      {%Database.Item{weight: %ExUc.Value{kind: :mass}, upc: upc}, []}
    end

    {item, categories}
  end

  defp do_register_form(assigns) do
    ~H"""

    <div class="device_form">
      <%= f = form_for :container, "#", phx_submit: "select_container" %>
      <%= select f, :container, Enum.map(Inventory.Container.get_all_containers(), &{&1.name, &1.id}) %>
      <%= submit "Manage Container" %>
    </div>
    <script src="https://unpkg.com/html5-qrcode" type="text/javascript"></script>

    <script>
    function foo() {

    function onScanSuccess(decodedText, decodedResult) {
      //const channel = useChannel("counter:lobby", "shout", updateMsg);
      // Handle on success condition with the decoded text or result.
      console.log(`Scan result: ${decodedText}`, decodedResult);
      //window.channel.push('recv_scan',{'data': decodedText});
      read_upc = decodedText;
      console.log(`Scan result is ${read_upc}`,read_upc);
      document.getElementById('read_button').value=read_upc;
      document.getElementById('read_button').click();
    }

    let html5QrcodeScanner = new Html5QrcodeScanner(
        "reader",
        {
            fps: 5,
            // Important notice: this is experimental feature, use it at your
            // own risk. See documentation in
            // mebjas@/html5-qrcode/src/experimental-features.ts
            rememberLastUsedCamera: true,
            qrbox: 250,
            showTorchButtonIfSupported: true
        });
  window.scanner = html5QrcodeScanner;
	html5QrcodeScanner.render(onScanSuccess);


    }

    function clear_scanner() {
      window.scanner.clear();
    }
            window.addEventListener('phx:reset-state', foo);
            window.addEventListener('phx:clear-scanner', clear_scanner);
  </script>
    """
  end

  defp do_main_interface(assigns) do
    ~H"""

    <style>
      #remove_confirm: {border: 1px solid black; padding: 1em;}
      #add_item: {border: 1px solid black; padding: 1em;}
      .categories {float: left; font-weight:bold; padding:1em;}
      .big {height: 10em; }
    </style>
    <h3>Managing Container: <%= Inventory.Container.get_container(String.to_integer(@container_id)).name %> </h3>


    <button class="big" phx-click="add_item">Add Item</button>
    <button class="big" phx-click="search_form">Search</button>
    <button class="big" phx-click="remove_item">Remove Item</button>

    <script src="https://unpkg.com/html5-qrcode" type="text/javascript"></script>
    <script>
    function docReady(fn) {
      // see if DOM is already available
      if (document.readyState === "complete" || document.readyState === "interactive") {
          // call on next available tick
          setTimeout(fn, 1);
      } else {
          document.addEventListener("DOMContentLoaded", fn);
      }
  }

    </script>


    <%= if @state.name == "search" do %>
      <div id="search_portal">
        <.live_component module={LiveSearchComponent} edit={@edit} id="search_comp" items={@items} selected_cats={[]} categories={Inventory.Category.get_all_categories()} container={@container_id} uploads={@uploads} />
      </div>
    <% end %>

    <div id="scanner" hidden={unless @state.name == "add" || @state.name == "remove", do: "hidden"}>
      <%# my Who-related form inputs %>
          <div id="reader" phx-update="ignore" style="width:500px; display: inline-block;"></div>
          <div class="empty"></div>
          <div id="scanned-result"></div>
          <button phx-click="recv_scan" phx-value=" " id='read_button'> Continue WIthout Scanning </button>


    </div>



    <div id="add_form" hidden={unless @state.name == "add_item", do: "hidden"}>
        <%= if is_nil(@state.data[:upc]) || String.length(@state.data[:upc]) == 0 do %>
        <% item = %Database.Item{weight: %ExUc.Value{kind: :mass}} %>
        <.live_component module={ItemComponentFormLive} id="new" container={@container_id} item={item} item_categories={[]} uploads={@uploads} />
        <% else %>
        <% {item, categories} = lookup_upc_info(@state.data[:upc]) %>
        <.live_component module={ItemComponentFormLive} id="new" container={@container_id} item={item} item_categories={categories} uploads={@uploads} />
        <% end %>
    </div>


    <script>
    function foo() {

    function onScanSuccess(decodedText, decodedResult) {
      //const channel = useChannel("counter:lobby", "shout", updateMsg);
      // Handle on success condition with the decoded text or result.
      console.log(`Scan result: ${decodedText}`, decodedResult);
      //window.channel.push('recv_scan',{'data': decodedText});
      read_upc = decodedText;
      html5QrcodeScanner.pause();
      console.log(`Scan result is ${read_upc}`,read_upc);
      document.getElementById('read_button').value=read_upc;
      document.getElementById('read_button').click();
    }

    let html5QrcodeScanner = new Html5QrcodeScanner(
        "reader",
        {
            fps: 5,
            // Important notice: this is experimental feature, use it at your
            // own risk. See documentation in
            // mebjas@/html5-qrcode/src/experimental-features.ts
            rememberLastUsedCamera: true,
            qrbox: 250,
            showTorchButtonIfSupported: true
        });
  window.scanner = html5QrcodeScanner;
	html5QrcodeScanner.render(onScanSuccess);


    }

    function clear_scanner() {
      window.scanner.clear();
    }
            window.addEventListener('phx:reset-state', foo);
            window.addEventListener('phx:clear-scanner', clear_scanner);
  </script>
    <br/>
    <button phx-click="reset_state">Reset</button>
    """
  end

  @impl true
  def render(assigns) do
    if !Map.has_key?(assigns, :container_id) do
      do_register_form(assigns)
     else
      do_main_interface(assigns)
     end

  end

end
