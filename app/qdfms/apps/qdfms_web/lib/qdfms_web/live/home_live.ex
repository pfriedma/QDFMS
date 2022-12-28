defmodule QdfmsWeb.HomeLive do
  use QdfmsWeb, :live_view
  alias Phoenix.LiveView.JS
  alias Database.Item
  #@topic "whats_inside"

  def mount(_params, %{"_csrf_token" => csrf_token} = _session, socket) do
    if connected?(socket) do
       QdfmsWeb.Endpoint.subscribe("whats_inside:#{csrf_token}")
       IO.puts("connected liveview")
    end
    {:ok,
      socket
      |> assign(state: %{name: "home", data: %{}})
      |> assign(conn: socket)
      |> assign(topics: ["whats_inside:#{csrf_token}"])
      |> assign(csrf_token, csrf_token)
    }

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
      "remove" -> "home"
      _ -> "home"
     end
     if state_name == "remove" do
        socket = socket
        |> put_flash(:info, "Item: " <> data <> " removed!")
        |> push_event("clear-scaner", %{
          to: "#reader",
          attr: ""
        })
        |> assign(state: %{name: "home", data: %{upc: data}})
        {:noreply, socket}
     else
     {:noreply, socket
     |> push_event("clear-scanner", %{
      to: "#reader",
      attr: ""
    })
    |> assign(state: %{name: new_state_name, data: %{upc: data}})}
     end
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

  def handle_info(_, socket) do
    IO.puts("Got an unhandled info event")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <script src="https://unpkg.com/html5-qrcode" type="text/javascript">
    let read_upc = "";
    </script>
    <style>
      #remove_confirm: {border: 1px solid black; padding: 1em;}
      #add_item: {border: 1px solid black; padding: 1em;}
      .categories {float: left; font-weight:bold; padding:1em;}
    </style>
    <h1>Hello World!</h1>


    <button phx-click="add_item">Add Item</button>
    <button phx-click="remove_item">Remove Item</button>

    <button phx-click="reset_state">Reset</button>

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

    <div id="scanner" <%= unless @state.name == "add" || @state.name == "remove", do: "hidden" %>>
      <%# my Who-related form inputs %>
          <div id="reader" phx-update="ignore" style="width:500px; display: inline-block;"></div>
          <div class="empty"></div>
          <div id="scanned-result"></div>
          <button phx-click="recv_scan" phx-value=" " id='read_button'> Add WIthout Scanning </button>


    </div>

    <div class="alert" phx-click="lv:clear-flash" phx-value-key="info">
        <%= live_flash(@flash, :info) %>
    </div>

    <div id="add_form" <%= unless @state.name == "add_item", do: "hidden" %>>
        <h1> form to add goes here </h1>
        <%= f = form_for :item, "#", phx_submit: "add_new_item" %>
          <%= label f, :name %>
          <%= text_input f, :name %>
          <%= error_tag f, :name %>
          <%= unless is_nil(@state.data[:upc]) || String.length(@state.data[:upc]) == 0 do %>
            <%= label f, :upc  %>
            <%= text_input f, :upc, value: @state.data[:upc] %>
            <%= error_tag f, :upc %>
          <% end %>
          <%= label f, :description %>
          <%= text_input f, :description %>
          <%= error_tag f, :description %>

          <%= label f, :exp_date %>
          <%= text_input f, :exp_date %>
          <%= #multiple_select(f, :categories_select_multiple, Enum.map(Inventory.Category.get_all_categories(), fn x -> x.id end) ) %>
          <fieldset id="categories_checkbox_group">
          <%= for cat <-  Inventory.Category.get_all_categories() do  %>
              <div class="categories">
              <%= if !is_nil(cat.image) do %>
              <img src="<%= "data:image/svg+xml;base64," <> cat.image %>", height='60', width='60'/><br/>
              <% end %>
              <input type="checkbox" name="item[categories_checkbox_group][]" value=<%=cat.id %> /><%=cat.name %>
              </div>
          <% end %>
        </fieldset>
        <div style="clear:both"></div>

          <%= submit "Save" %>
      </form>
    </div>


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

    <p>
    State is: <%= @state.name %> <br/>
    Data is <%= Kernel.inspect(@state.data) %>
    </p>

    """
  end
end
