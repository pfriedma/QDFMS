defmodule QdfmsWeb.WhatsInsideChannel do
  use QdfmsWeb, :channel

  @impl true
  def join("whats_inside:" <> token, payload, socket) do
    if authorized?(payload) do
      {:ok, assign(socket, :channel, "whats_inside:#{token}")}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (whats_inside:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end


  @impl true
  def handle_in("recv_scan", %{"data" => data} = _data, socket) do
#    status = if Map.has_key?(data, "value"), do: 1, else: 0
#    item = Item.get_item!(Map.get(data, "id"))
#    Item.update_item(item, %{id: item.id, status: status})
#    socket = assign(socket, items: Item.list_items(), active: %Item{})
     #socket = assign(socket, state: %{name: data})
     IO.puts(data)
     IO.puts(socket.assigns.channel)
    broadcast!(socket,"recv_scan_fromc", %{data: data})
    Phoenix.PubSub.broadcast!(QdfmsWeb.PubSub, socket.assigns.channel, {"recv_scan_c", %{data: data}})
    QdfmsWeb.Endpoint.broadcast_from!(self(), socket.assigns.channel, "recv_scan_c", %{data: data})

    #QdfmsWeb.Endpoint.broadcast_from!(self(),"foo","recv_scan",%{data: data})
    {:noreply, socket}
  end



  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
